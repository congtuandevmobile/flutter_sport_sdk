import 'dart:async';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_challenge/flutter_challenge.dart';

import 'sport.dart';
import 'sport_catalog.dart';
import 'telemetry.dart';
import 'telemetry_recorder.dart';

/// What the coordinator tells the app. The app turns these into a vibration, a sound, a notification or a screen.
sealed class CoordinatorEvent {
  const CoordinatorEvent();
}

/// Stage [index] began.
class StageStarted extends CoordinatorEvent {
  const StageStarted(this.index, this.config);
  final int index;
  final SportStageConfig config;
}

/// Stage [index] completed: [completed] is what the challenge decided, [result] adds what the sensors recorded UNTIL NOW. A sample that
/// was made during the stage but arrives a moment later is still filed under it: read `ChallengeCoordinator.results` (or the
/// [ChallengeFinished] event) for the final numbers.
class StageCompleted extends CoordinatorEvent {
  const StageCompleted(this.index, this.config, this.completed, this.result);
  final int index;
  final SportStageConfig config;
  final CompletedStage completed;
  final StageResult result;
}

/// The previous stage completed and the next one ([nextIndex]) waits for the user (`TransitionPolicy.waitForUser`): show the button.
class AwaitingNextStage extends CoordinatorEvent {
  const AwaitingNextStage(this.nextIndex, this.next);
  final int nextIndex;
  final SportStageConfig next;
}

/// The last stage completed.
class ChallengeFinished extends CoordinatorEvent {
  const ChallengeFinished(this.results);
  final List<StageResult> results;
}

/// Something went wrong that the app may want to show (a reading refused, the telemetry not stored).
class CoordinatorError extends CoordinatorEvent {
  const CoordinatorError(this.code, this.message);
  final String code;
  final String message;
}

/// Runs a multisport challenge on top of a [FlutterChallenge]: it builds the challenge from the stages the user chose, forwards the
/// readings of the sources, records the telemetry of each stage, tells the app when a stage starts or completes, and moves to the next
/// stage by hand or by itself.
///
/// It does NOT decide progress: the challenge does (one source per stage, the clock of a timed stage, the journal). It does not know GPS
/// or Bluetooth: the app attaches [ProgressSource]s and [TelemetrySource]s. Connections stay open between stages; what changes is which
/// source the next stage lets count.
class ChallengeCoordinator {
  ChallengeCoordinator({
    required FlutterChallenge challenge,
    required TelemetryStore store,
    SportCatalog? catalog,
    DateTime Function()? clock,
    this.autoNextDelay = const Duration(seconds: 3),
  }) : _challenge = challenge,
       _store = store,
       catalog = catalog ?? SportCatalog.standard(),
       _clock = clock ?? DateTime.now;

  final FlutterChallenge _challenge;
  final TelemetryStore _store;
  final DateTime Function() _clock;
  final SportCatalog catalog;

  /// How long a stage with `TransitionPolicy.autoNext` waits (to let the user see that it completed) before the next one starts.
  final Duration autoNextDelay;

  final _events = StreamController<CoordinatorEvent>.broadcast();

  List<SportStageConfig> _stages = const [];
  String? _sessionId;
  StageTelemetryRecorder? _recorder;
  StreamSubscription<ChallengeSnapshot>? _snapshotSub;
  final _sourceSubs = <StreamSubscription<Object?>>[];
  Timer? _autoTimer;

  ChallengeSnapshot? _latest;
  int _startedIndex = -1;
  int _completedSeen = 0;
  int _awaitingEmittedFor = -1;
  int _autoScheduledFor = -1;
  bool _finishedEmitted = false;
  DateTime? _startHint;
  int _manualCounter = 0;
  final _errorAt = <String, DateTime>{};

  Stream<CoordinatorEvent> get events => _events.stream;

  /// The stages of the running challenge.
  List<SportStageConfig> get stages => List.unmodifiable(_stages);

  String? get sessionId => _sessionId;

  /// The latest snapshot of the challenge (null before the start).
  ChallengeSnapshot? get snapshot => _latest;

  /// The stage that is running (null before the first and after the last).
  SportStageConfig? get currentStage {
    final s = _latest;
    if (s == null || s.state == ChallengeState.idle || s.state == ChallengeState.completed) return null;
    return s.stageIndex >= 0 && s.stageIndex < _stages.length ? _stages[s.stageIndex] : null;
  }

  /// The results of the stages that completed so far, with their telemetry.
  List<StageResult> get results {
    final recorder = _recorder;
    final s = _latest;
    if (recorder == null || s == null) return const [];
    return [for (var i = 0; i < s.completed.length; i++) recorder.resultFor(i, completed: s.completed[i])];
  }

  /// The result of the stage that is running now, so far (no evidence, no end).
  StageResult? get currentResult {
    final recorder = _recorder;
    final s = _latest;
    if (recorder == null || s == null || recorder.currentStage < 0 || s.state == ChallengeState.completed) return null;
    return recorder.resultFor(recorder.currentStage);
  }

  /// Whether the telemetry recorded so far is on the store.
  bool get isTelemetryDurable => _recorder?.isDurable ?? true;

  // ── start / restore ───────────────────────────────────────────────────────

  /// Builds the challenge from [stages] and starts it (the first stage begins now). Throws [SportConfigException] when a stage is wrong,
  /// and the errors of `FlutterChallenge.start` (`SESSION_EXISTS`, `RECOVERY_REQUIRED`, ...).
  Future<void> start({
    required String sessionId,
    required List<SportStageConfig> stages,
    String challengeId = 'multisport',
    bool allowPause = true,
  }) async {
    final definition = catalog.definitionOf(id: challengeId, stages: stages, allowPause: allowPause);
    _reset();
    final recorder = await StageTelemetryRecorder.begin(_store, sessionId, clock: _clock);
    _stages = List.of(stages);
    _sessionId = sessionId;
    _recorder = recorder;
    _listen();
    _startHint = _clock();
    try {
      _handle(await _challenge.start(sessionId: sessionId, definition: definition));
    } catch (_) {
      await _snapshotSub?.cancel();
      _snapshotSub = null;
      _recorder = null;
      _sessionId = null;
      await _store.clear(sessionId);
      rethrow;
    }
  }

  /// Picks the challenge [sessionId] up after the process died. [stages] must be the same list it started with. It comes back PAUSED:
  /// call [resume] to go on (the time the process was dead is in neither the stage nor its telemetry).
  Future<void> restore({required String sessionId, required List<SportStageConfig> stages}) async {
    catalog.definitionOf(id: 'restore', stages: stages); // the same stages must still be valid
    _reset();
    _stages = List.of(stages);
    _sessionId = sessionId;
    _recorder = await StageTelemetryRecorder.restore(_store, sessionId, clock: _clock);
    _listen();
    final snap = await _challenge.restore(sessionId);
    _startedIndex = snap.stageIndex;
    _completedSeen = snap.completed.length;
    _finishedEmitted = snap.state == ChallengeState.completed;
    _awaitingEmittedFor = snap.state == ChallengeState.transition ? snap.stageIndex + 1 : -1;
    _latest = snap;
  }

  // ── what the app attaches ─────────────────────────────────────────────────

  /// Forwards the readings of [source] to the challenge, whatever the stage (the challenge lets only the stage's own sources count).
  void attachProgress(ProgressSource source) {
    _sourceSubs.add(
      source.readings.listen((r) {
        final id = _sessionId;
        if (id == null) return;
        _challenge
            .submitCounter(id, source.sourceId, r.value, epoch: r.epoch, age: r.age)
            .catchError((Object e) => _error('READING_REFUSED', '$e'));
      }),
    );
  }

  /// Records the samples of [source] under the stage they were made in.
  void attachTelemetry(TelemetrySource source) {
    _sourceSubs.add(source.samples.listen((s) => _recorder?.record(s)));
  }

  /// A repetition count made by hand or by a counter that counts for itself (a "+1" button), for the stage that is running now. Pass a
  /// stable [eventId] when a retry is possible: the same id is never counted twice.
  Future<void> addRepetitions(double count, {String sourceId = 'manual', String? eventId}) {
    final id = _sessionId;
    final snap = _latest;
    if (id == null || snap == null) throw StateError('no challenge is running');
    return _challenge.submitDelta(
      id,
      sourceId,
      eventId ?? '$sourceId-${_clock().microsecondsSinceEpoch}-${_manualCounter++}',
      count,
      // the stage the user SAW: a tap that arrives after the stage changed is dropped, not given to the next stage
      stageActivation: snap.stageActivation,
    );
  }

  // ── commands ──────────────────────────────────────────────────────────────

  /// Starts the next stage (after one completed). With `TransitionPolicy.autoNext` the coordinator calls it by itself.
  Future<void> nextStage() async {
    _autoTimer?.cancel();
    _startHint = _clock();
    _handle(await _challenge.nextStage(_requireSession()));
  }

  /// Confirms the stage that is running (a `confirmed` or `manualOnly` stage, or a stage the user ends early). The activation of the
  /// stage the user saw is sent along, so a confirmation that arrives late cannot complete the next stage.
  Future<void> confirm({CompletionEvidence evidence = CompletionEvidence.manual}) async {
    final snap = _latest;
    _handle(await _challenge.confirm(_requireSession(), evidence, expectedStageActivation: snap?.stageActivation));
  }

  Future<void> pause() async {
    final at = _clock();
    final snap = await _challenge.pause(_requireSession());
    _recorder?.markPaused(at);
    _handle(snap);
  }

  Future<void> resume() async {
    final at = _clock();
    final snap = await _challenge.resume(_requireSession());
    _recorder?.markResumed(at);
    _handle(snap);
  }

  /// Stops listening; the challenge itself is left as it is (its journal still lets it be restored).
  Future<void> dispose() async {
    _autoTimer?.cancel();
    await _snapshotSub?.cancel();
    for (final s in _sourceSubs) {
      await s.cancel();
    }
    _sourceSubs.clear();
    await _recorder?.flush();
    await _events.close();
  }

  // ── reacting to the challenge ─────────────────────────────────────────────

  String _requireSession() => _sessionId ?? (throw StateError('no challenge is running'));

  void _reset() {
    _autoTimer?.cancel();
    _snapshotSub?.cancel();
    _snapshotSub = null;
    _latest = null;
    _startedIndex = -1;
    _completedSeen = 0;
    _awaitingEmittedFor = -1;
    _autoScheduledFor = -1;
    _finishedEmitted = false;
    _startHint = null;
  }

  void _listen() {
    _snapshotSub = _challenge.snapshots.listen(_handle);
  }

  void _handle(ChallengeSnapshot s) {
    final recorder = _recorder;
    if (recorder == null || (s.sessionId != null && s.sessionId != _sessionId)) return;
    _latest = s;
    final now = _clock();

    // a stage began
    if (s.state != ChallengeState.idle && s.stageIndex > _startedIndex && s.stageIndex < _stages.length) {
      final at = _startHint ?? now;
      _startHint = null;
      _startedIndex = s.stageIndex;
      recorder.markStageStarted(s.stageIndex, _stages[s.stageIndex], at);
      _emit(StageStarted(s.stageIndex, _stages[s.stageIndex]));
    }

    // stages completed (in order, once each)
    while (_completedSeen < s.completed.length && _completedSeen < _stages.length) {
      final i = _completedSeen++;
      recorder.markStageEnded(i, now);
      _emit(StageCompleted(i, _stages[i], s.completed[i], recorder.resultFor(i, completed: s.completed[i])));
    }

    if (s.state == ChallengeState.paused) {
      recorder.markPaused(now);
    } else if (recorder.isPaused && (s.state == ChallengeState.active || s.state == ChallengeState.transition)) {
      recorder.markResumed(now);
    }

    // what follows a completed stage
    if (s.state == ChallengeState.transition) {
      final next = s.stageIndex + 1;
      if (next < _stages.length) {
        if (_stages[s.stageIndex].transition == TransitionPolicy.autoNext) {
          _scheduleAutoNext(next);
        } else if (_awaitingEmittedFor != next) {
          _awaitingEmittedFor = next;
          _emit(AwaitingNextStage(next, _stages[next]));
        }
      }
    }

    if (s.state == ChallengeState.completed && !_finishedEmitted) {
      _finishedEmitted = true;
      _emit(ChallengeFinished(results));
    }
    if (!recorder.isDurable) _error('TELEMETRY_NOT_STORED', 'the telemetry of this session could not be written');
  }

  void _scheduleAutoNext(int next) {
    if (_autoScheduledFor == next) return;
    _autoScheduledFor = next;
    _autoTimer = Timer(autoNextDelay, () {
      nextStage().catchError((Object e) => _error('AUTO_NEXT_FAILED', '$e'));
    });
  }

  void _emit(CoordinatorEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  /// An error event, at most one per code every 5 seconds (a source that keeps failing must not flood the screen).
  void _error(String code, String message) {
    final now = _clock();
    final last = _errorAt[code];
    if (last != null && now.difference(last) < const Duration(seconds: 5)) return;
    _errorAt[code] = now;
    _emit(CoordinatorError(code, message));
  }
}
