import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Where the telemetry records of a session live: an append-only list of text lines, in order. A store never interprets a line.
abstract interface class TelemetryStore {
  /// Appends [line] after the lines already stored. Completes when it is stored.
  Future<void> append(String sessionId, String line);

  Future<List<String>> read(String sessionId);

  Future<void> clear(String sessionId);
}

/// Lines in memory (tests, or data that need not survive the process).
class MemoryTelemetryStore implements TelemetryStore {
  final Map<String, List<String>> lines = {};

  @override
  Future<void> append(String sessionId, String line) async => (lines[sessionId] ??= []).add(line);

  @override
  Future<List<String>> read(String sessionId) async => List.of(lines[sessionId] ?? const []);

  @override
  Future<void> clear(String sessionId) async => lines.remove(sessionId);
}

/// One text file per session in [directory] (one line per record), flushed to the disk on every append, so what a crash can lose is the
/// line being written. The file name is made from the id so that two ids never share a file.
class FileTelemetryStore implements TelemetryStore {
  FileTelemetryStore(this.directory);

  final Directory directory;

  File _file(String sessionId) => File('${directory.path}/telemetry-${Uri.encodeComponent(sessionId).replaceAll('%', '_')}.jsonl');

  @override
  Future<void> append(String sessionId, String line) async {
    await directory.create(recursive: true);
    await _file(sessionId).writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  @override
  Future<List<String>> read(String sessionId) async {
    final file = _file(sessionId);
    if (!await file.exists()) return const [];
    final text = await file.readAsString(encoding: utf8);
    return const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
  }

  @override
  Future<void> clear(String sessionId) async {
    final file = _file(sessionId);
    if (await file.exists()) await file.delete();
  }
}
