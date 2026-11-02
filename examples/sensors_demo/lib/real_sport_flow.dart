import 'dart:convert';
import 'dart:io';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart' as multisport;
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_sport_ble_adapter/flutter_sport_ble_adapter.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';
import 'package:flutter_tracking_gps_adapter/flutter_tracking_gps_adapter.dart';
import 'package:path_provider/path_provider.dart';

class SavedChallenge {
  const SavedChallenge(this.results, this.heartRate, this.cadence);

  final List<multisport.StageResult> results;
  final List<List<SeriesPoint>> heartRate;
  final List<List<SeriesPoint>> cadence;
}

/// App-owned glue. The SDKs remain independent: the host decides which sensors
/// to connect, where to store data, what screens to show and when to retry.
class RealSportFlow {
  RealSportFlow._(this.directory, this.gps, this.ble, this.challenge)
    : store = FileTelemetryStore(Directory('${directory.path}/telemetry')),
      bleSnapshots = ble.snapshots.asBroadcastStream();

  static Future<RealSportFlow> create({
    Directory? directory,
    FlutterTrackingGps? gps,
    SportBle? ble,
    FlutterChallenge? challenge,
  }) async {
    final root = directory ?? await getApplicationDocumentsDirectory();
    await root.create(recursive: true);
    return RealSportFlow._(
      root,
      gps ?? FlutterTrackingGps(),
      ble ?? SportBle(),
      challenge ?? FlutterChallenge(),
    );
  }

  final Directory directory;
  final FlutterTrackingGps gps;
  final SportBle ble;
  final FlutterChallenge challenge;
  final FileTelemetryStore store;
  final Stream<SensorSnapshot> bleSnapshots;

  TrackingSession? tracking;
  ActivityRecorder? activity;
  multisport.ChallengeCoordinator? coordinator;
  multisport.SportPlan? plan;
  String? sessionId;
  String? kind;

  File get _activeFile => File('${directory.path}/active-sport-session.json');
  File get _indexFile => File('${directory.path}/sport-history.json');
  File _planFile(String id) => File('${directory.path}/plan-$id.json');
  File _routeFile(String id) => File('${directory.path}/route-$id.json');

  Future<void> _write(File file, String content) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);
  }

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _requireGpsPermission() async {
    var permission = await gps.permissionStatus();
    if (permission != PlatformPermission.granted) {
      permission = await gps.requestPermission();
    }
    if (permission != PlatformPermission.granted) {
      throw StateError('location permission: ${permission.name}');
    }
  }

  void _attachActivitySources(
    ActivityRecorder recorder,
    TrackingSession session,
  ) {
    recorder.attachDistance(GpsProgressSource(session.updates));
    recorder.attachTelemetry(GpsTelemetrySource(session.updates));
    recorder.attachTelemetry(
      ResolvedBleTelemetrySource(snapshots: bleSnapshots),
    );
  }

  void _attachChallengeSources(
    multisport.ChallengeCoordinator c,
    TrackingSession? session,
  ) {
    if (session != null) c.attachProgress(GpsProgressSource(session.updates));
    c.attachTelemetry(ResolvedBleTelemetrySource(snapshots: bleSnapshots));
  }

  /// Connect any number of standard BLE sensors while an activity or challenge
  /// is open. The BLE resolver chooses one healthy device per live metric.
  Future<void> connectDevice(String deviceId) => ble.connect(deviceId);
  Future<void> disconnectDevice(String deviceId) => ble.disconnect(deviceId);
  Future<void> preferDevice(SportMetric metric, String? deviceId) =>
      ble.setPreferredSource(metric, deviceId);

  /// A device-specific cumulative counter (rower, treadmill, external swim
  /// source). The stage must allow [sourceId]. Unknown devices can implement
  /// [ProgressSource] in the host instead.
  void attachDeviceCounter(
    String deviceId,
    SportMetric metric, {
    required String sourceId,
  }) {
    coordinator?.attachProgress(
      BleCounterSource(
        snapshots: bleSnapshots,
        deviceId: deviceId,
        metric: metric,
        sourceId: sourceId,
      ),
    );
  }

  void attachProgress(ProgressSource source) =>
      coordinator?.attachProgress(source);
  void attachTelemetry(TelemetrySource source) {
    activity?.attachTelemetry(source);
    coordinator?.attachTelemetry(source);
  }

  Future<void> startActivity() async {
    if (sessionId != null) throw StateError('finish the open session first');
    await _requireGpsPermission();
    final id = _nextId('activity');
    final session = gps.createSession();
    final recorder = await ActivityRecorder.begin(
      store,
      id,
      activityType: 'running',
      distanceSource: 'gps',
    );
    _attachActivitySources(recorder, session);
    try {
      await session.start(sessionId: id);
    } catch (_) {
      await recorder.dispose();
      await store.clear(id);
      await session.dispose();
      rethrow;
    }
    tracking = session;
    activity = recorder;
    sessionId = id;
    kind = 'activity';
    await _write(_activeFile, jsonEncode({'kind': kind, 'id': id}));
  }

  /// Saves the full plan before starting: a custom sport can therefore be
  /// reconstructed with the same source and metric rules after a crash.
  Future<void> startChallenge(multisport.SportPlan nextPlan) async {
    if (sessionId != null) throw StateError('finish the open session first');
    nextPlan.validate();
    final needsGps = nextPlan.stages.any(
      (s) =>
          nextPlan.catalog.stageDefinitionOf(s).allowedSources.contains('gps'),
    );
    if (needsGps) await _requireGpsPermission();
    final id = _nextId('challenge');
    final session = needsGps ? gps.createSession() : null;
    final c = multisport.ChallengeCoordinator(
      challenge: challenge,
      store: store,
      catalog: nextPlan.catalog,
    );
    _attachChallengeSources(c, session);
    await _write(_planFile(id), nextPlan.encode());
    var gpsStarted = false;
    try {
      if (session != null) {
        await session.start(sessionId: id);
        gpsStarted = true;
      }
      await c.start(
        sessionId: id,
        stages: nextPlan.stages,
        challengeId: nextPlan.id,
        allowPause: nextPlan.allowPause,
      );
    } catch (_) {
      if (gpsStarted) {
        try {
          await session!.finish();
        } catch (_) {
          // Preserve the original start failure; dispose still releases the link.
        }
      }
      await c.dispose();
      await session?.dispose();
      await _planFile(id).delete();
      rethrow;
    }
    coordinator = c;
    tracking = session;
    plan = nextPlan;
    sessionId = id;
    kind = 'challenge';
    await _write(_activeFile, jsonEncode({'kind': kind, 'id': id}));
  }

  /// Restore a crashed session paused. BLE links must be reconnected by the
  /// host; restored samples and progress still come from their own stores.
  Future<void> restoreActive() async {
    if (!await _activeFile.exists()) return;
    final active =
        jsonDecode(await _activeFile.readAsString()) as Map<String, dynamic>;
    final id = active['id'] as String;
    final activeKind = active['kind'] as String;
    if (activeKind == 'activity') {
      final recorder = await ActivityRecorder.restore(store, id);
      if (recorder == null) {
        throw StateError('activity telemetry was not found');
      }
      final session = gps.createSession();
      await session.restore(sessionId: id);
      _attachActivitySources(recorder, session);
      activity = recorder;
      tracking = session;
    } else if (activeKind == 'challenge') {
      final savedPlan = multisport.SportPlan.decode(
        await _planFile(id).readAsString(),
      );
      final c = multisport.ChallengeCoordinator(
        challenge: challenge,
        store: store,
        catalog: savedPlan.catalog,
      );
      await c.restore(sessionId: id, stages: savedPlan.stages);
      final needsGps = savedPlan.stages.any(
        (s) => savedPlan.catalog
            .stageDefinitionOf(s)
            .allowedSources
            .contains('gps'),
      );
      TrackingSession? session;
      if (needsGps) {
        session = gps.createSession();
        await session.restore(sessionId: id);
      }
      _attachChallengeSources(c, session);
      coordinator = c;
      tracking = session;
      plan = savedPlan;
    } else {
      throw FormatException('unknown session kind: $activeKind');
    }
    sessionId = id;
    kind = activeKind;
  }

  Future<void> pause() async {
    if (kind == 'activity') {
      await tracking!.pause();
      activity!.pause();
    } else if (kind == 'challenge') {
      await coordinator!.pause();
      if (tracking?.snapshot.state == RecordingState.running) {
        await tracking!.pause();
      }
    }
  }

  Future<void> resume() async {
    if (kind == 'activity') {
      activity!.resume();
      await tracking!.resume();
    } else if (kind == 'challenge') {
      await coordinator!.resume();
      if (tracking?.snapshot.state == RecordingState.paused) {
        await tracking!.resume();
      }
    }
  }

  Future<ActivitySummary> finishActivity() async {
    if (kind != 'activity') throw StateError('no activity is open');
    if (tracking!.snapshot.state != RecordingState.finished) {
      await tracking!.finish();
    }
    final result = await activity!.finish();
    if (!result.isDurable || result.hasWriteFailures) {
      throw StateError('activity telemetry could not be saved completely');
    }
    await _saveRoute(sessionId!);
    await _archive('activity', sessionId!);
    await _activeFile.delete();
    await activity!.dispose();
    await tracking!.dispose();
    activity = null;
    tracking = null;
    kind = null;
    sessionId = null;
    return result;
  }

  Future<void> addManualProgress(double amount, {String? eventId}) =>
      coordinator!.addProgress(amount, eventId: eventId);
  Future<void> confirmStage() => coordinator!.confirm();
  Future<void> nextStage() => coordinator!.nextStage();

  /// Call when [multisport.ChallengeFinished] arrives. The native journal and
  /// per-stage telemetry remain readable; the plan file makes restore possible.
  Future<List<multisport.StageResult>> archiveChallenge() async {
    if (kind != 'challenge' ||
        coordinator?.snapshot?.state != ChallengeState.completed) {
      throw StateError('challenge is not completed');
    }
    await coordinator!.flushTelemetry();
    if (!coordinator!.isTelemetryDurable ||
        coordinator!.hasTelemetryWriteFailures) {
      throw StateError('challenge telemetry could not be saved completely');
    }
    if (tracking?.snapshot.state == RecordingState.running ||
        tracking?.snapshot.state == RecordingState.paused) {
      await tracking!.finish();
    }
    if (tracking != null) {
      await _saveRoute(sessionId!);
    }
    final results = coordinator!.results;
    await _archive('challenge', sessionId!);
    await _activeFile.delete();
    await coordinator!.dispose();
    await tracking?.dispose();
    coordinator = null;
    tracking = null;
    plan = null;
    kind = null;
    sessionId = null;
    return results;
  }

  Future<void> _saveRoute(String id) async {
    final fixes = await tracking?.persistedFixes() ?? const <TrackingFix>[];
    await _write(
      _routeFile(id),
      jsonEncode([
        for (final f in fixes)
          {
            'lat': f.latitude,
            'lon': f.longitude,
            'at': f.time.millisecondsSinceEpoch,
            'seq': f.seq,
          },
      ]),
    );
  }

  Future<void> _archive(String archivedKind, String id) async {
    final records = await history();
    if (!records.any((r) => r['id'] == id)) {
      records.add({'kind': archivedKind, 'id': id});
      await _write(_indexFile, jsonEncode(records));
    }
  }

  Future<List<Map<String, String>>> history() async {
    if (!await _indexFile.exists()) return [];
    final decoded =
        jsonDecode(await _indexFile.readAsString()) as List<dynamic>;
    return [
      for (final item in decoded)
        (item as Map<String, dynamic>).cast<String, String>(),
    ];
  }

  Future<ActivityRecorder?> activityHistory(String id) =>
      ActivityRecorder.restore(store, id);

  Future<List<Map<String, Object?>>> routeHistory(String id) async {
    final file = _routeFile(id);
    if (!await file.exists()) return [];
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    return [
      for (final item in decoded)
        (item as Map<String, dynamic>).cast<String, Object?>(),
    ];
  }

  Future<SavedChallenge> challengeHistory(String id) async {
    if (sessionId != null) {
      throw StateError(
        'open session must be finished before replaying a challenge',
      );
    }
    final savedPlan = multisport.SportPlan.decode(
      await _planFile(id).readAsString(),
    );
    final c = multisport.ChallengeCoordinator(
      challenge: challenge,
      store: store,
      catalog: savedPlan.catalog,
    );
    try {
      await c.restore(sessionId: id, stages: savedPlan.stages);
      final results = c.results;
      return SavedChallenge(
        results,
        [
          for (final r in results)
            c.stageSeries(r.index, TelemetryMetric.heartRate, maxPoints: 200),
        ],
        [
          for (final r in results)
            c.stageSeries(r.index, TelemetryMetric.cadence, maxPoints: 200),
        ],
      );
    } finally {
      await c.dispose();
    }
  }

  Future<void> dispose() async {
    await activity?.dispose();
    await coordinator?.dispose();
    await tracking?.dispose();
  }
}
