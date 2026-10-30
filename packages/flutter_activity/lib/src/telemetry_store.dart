import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Where the telemetry records of a session live: an append-only list of text lines, in order. A store never interprets a line.
abstract interface class TelemetryStore {
  /// Appends [line] after the lines already stored. Completes when it is stored.
  Future<void> append(String sessionId, String line);

  Future<List<String>> read(String sessionId);

  Future<void> clear(String sessionId);

  /// Replaces ALL the lines of [sessionId] by [lines], atomically, after keeping the previous content for diagnosis. Used to cut a damaged
  /// tail off, so that what is appended later is not hidden behind the damage.
  Future<void> replace(String sessionId, List<String> lines);
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

  /// The content `replace` kept, by session id.
  final Map<String, List<String>> damaged = {};

  @override
  Future<void> replace(String sessionId, List<String> newLines) async {
    damaged[sessionId] = List.of(lines[sessionId] ?? const []);
    lines[sessionId] = List.of(newLines);
  }
}

/// One text file per session in [directory] (one line per record), flushed to the disk on every append, so what a crash can lose is the
/// line being written. The file name is made from the id so that two ids never share a file.
class FileTelemetryStore implements TelemetryStore {
  FileTelemetryStore(this.directory);

  final Directory directory;

  File _file(String sessionId) => File('${directory.path}/telemetry-${_safe(sessionId)}.jsonl');

  /// A file name from an id: ASCII letters and digits stay, anything else (the underscore included) is written as its hex code, so two
  /// different ids never share a file.
  static String _safe(String id) {
    final out = StringBuffer();
    for (final rune in id.runes) {
      final isAlnum = (rune >= 0x30 && rune <= 0x39) || (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
      if (isAlnum) {
        out.writeCharCode(rune);
      } else {
        out.write('_${rune.toRadixString(16)}_');
      }
    }
    return out.toString();
  }

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

  @override
  Future<void> replace(String sessionId, List<String> lines) async {
    final file = _file(sessionId);
    if (await file.exists()) {
      await file.copy('${file.path}.damaged-${DateTime.now().millisecondsSinceEpoch}');
    }
    final temp = File('${file.path}.tmp');
    await directory.create(recursive: true);
    await temp.writeAsString(lines.isEmpty ? '' : '${lines.join('\n')}\n', flush: true);
    await temp.rename(file.path); // atomic on the same volume
  }
}
