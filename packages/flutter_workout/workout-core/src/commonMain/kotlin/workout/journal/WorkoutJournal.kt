package workout.journal

import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutEvent
import workout.model.WorkoutMode
import workout.session.RestoredSession
import workout.session.WorkoutSession

/** What reading a journal found. */
enum class JournalStatus {
    /** Every line was intact. */
    INTACT,

    /** The LAST line was damaged (a write cut short) and was dropped. */
    TAIL_REPAIRED,

    /** A line in the middle was damaged: only what comes before it is kept. */
    PARTIAL,
}

class JournalRead(val events: List<WorkoutEvent>, val status: JournalStatus, val droppedLines: Int)

class RecoveredWorkout(val restored: RestoredSession, val read: JournalRead)

/**
 * The text form of the workout events: one line per event, `W1|seq|type|atMs|fields...|crc`, where the crc (CRC-32 of everything
 * before it, in hex) lets a cut or damaged line be recognised. Text with `|`, `%` and line breaks is percent-escaped. This is the
 * WORKOUT journal: it is independent of the GPS journal and never holds a coordinate.
 */
object WorkoutJournal {
    private const val VERSION = "W1"

    fun encode(e: WorkoutEvent): String {
        val body = StringBuilder().append(VERSION).append('|').append(e.seq).append('|')
        when (e) {
            is WorkoutEvent.Started -> body.append("S|").append(e.atMs).append('|').append(e.mode.name)
            is WorkoutEvent.Paused -> body.append("P|").append(e.atMs)
            is WorkoutEvent.Resumed -> body.append("R|").append(e.atMs)
            is WorkoutEvent.Finished -> body.append("F|").append(e.atMs)
            is WorkoutEvent.SourceSelected ->
                body.append("C|").append(e.atMs).append('|').append(source(e.source)).append('|').append(escape(e.reason))
            is WorkoutEvent.BaselineEstablished ->
                body.append("B|").append(e.atMs).append('|').append(source(e.source)).append('|').append(e.value).append('|').append(escape(e.reason))
            is WorkoutEvent.DistanceAdvanced ->
                body.append("D|").append(e.atMs).append('|').append(source(e.source)).append('|').append(e.deltaMeters)
        }
        val text = body.toString()
        return text + "|" + Crc32.hex(text)
    }

    /** The event of a line, or null when the line is damaged, cut, of another version or unknown. */
    fun decode(line: String): WorkoutEvent? {
        val cut = line.lastIndexOf('|')
        if (cut < 0) return null
        val text = line.substring(0, cut)
        if (Crc32.hex(text) != line.substring(cut + 1)) return null
        val p = text.split('|')
        if (p.size < 4 || p[0] != VERSION) return null
        val seq = p[1].toLongOrNull() ?: return null
        val at = p[3].toLongOrNull() ?: return null
        if (seq < 1L || at < 0L) return null
        return try {
            when (p[2]) {
                "S" -> if (p.size == 5) WorkoutEvent.Started(seq, at, WorkoutMode.valueOf(p[4])) else null
                "P" -> if (p.size == 4) WorkoutEvent.Paused(seq, at) else null
                "R" -> if (p.size == 4) WorkoutEvent.Resumed(seq, at) else null
                "F" -> if (p.size == 4) WorkoutEvent.Finished(seq, at) else null
                "C" -> if (p.size == 6) WorkoutEvent.SourceSelected(seq, at, parseSource(p[4]) ?: return null, unescape(p[5])) else null
                "B" -> if (p.size == 7) {
                    WorkoutEvent.BaselineEstablished(seq, at, parseSource(p[4]) ?: return null, finite(p[5]) ?: return null, unescape(p[6]))
                } else null
                "D" -> if (p.size == 6) {
                    val delta = finite(p[5]) ?: return null
                    if (delta <= 0.0) null else WorkoutEvent.DistanceAdvanced(seq, at, parseSource(p[4]) ?: return null, delta)
                } else null
                else -> null
            }
        } catch (e: IllegalArgumentException) {
            null
        }
    }

    /**
     * Reads the lines of a journal: every intact line in order. The first damaged line ends the reading; when it is the LAST one it is
     * a write that was cut short (TAIL_REPAIRED), otherwise the damage is in the middle and only the prefix is trusted (PARTIAL).
     */
    fun read(lines: List<String>): JournalRead {
        val clean = lines.filter { it.isNotBlank() }
        val events = ArrayList<WorkoutEvent>(clean.size)
        for ((i, line) in clean.withIndex()) {
            val e = decode(line)
            if (e == null) {
                val status = if (i == clean.lastIndex) JournalStatus.TAIL_REPAIRED else JournalStatus.PARTIAL
                return JournalRead(events, status, clean.size - i)
            }
            events.add(e)
        }
        return JournalRead(events, JournalStatus.INTACT, 0)
    }

    /**
     * Rebuilds the workout from its journal lines. Null when there is no usable Started line. The session comes back PAUSED if it
     * was running; `restored.recoveryEvents` are to be appended to the journal (encode them like any event).
     */
    fun recover(lines: List<String>): RecoveredWorkout? {
        val read = read(lines)
        val restored = WorkoutSession.restore(read.events) ?: return null
        return RecoveredWorkout(restored, read)
    }

    private fun source(s: DistanceSource) = s.kind.name + ":" + escape(s.id)

    private fun parseSource(text: String): DistanceSource? {
        val colon = text.indexOf(':')
        if (colon < 1) return null
        val kind = try { DistanceSourceKind.valueOf(text.substring(0, colon)) } catch (e: IllegalArgumentException) { return null }
        return DistanceSource(unescape(text.substring(colon + 1)), kind)
    }

    private fun finite(text: String): Double? = text.toDoubleOrNull()?.takeIf { it.isFinite() }

    private fun escape(text: String): String =
        text.replace("%", "%25").replace("|", "%7C").replace("\n", "%0A").replace("\r", "%0D")

    private fun unescape(text: String): String =
        text.replace("%0D", "\r").replace("%0A", "\n").replace("%7C", "|").replace("%25", "%")
}

/** CRC-32 (the common one), written out because common Kotlin has none. */
internal object Crc32 {
    private val table = IntArray(256) { n ->
        var c = n
        repeat(8) { c = if (c and 1 != 0) (c ushr 1) xor 0xEDB88320.toInt() else c ushr 1 }
        c
    }

    fun hex(text: String): String {
        var c = -1
        for (b in text.encodeToByteArray()) c = table[(c xor b.toInt()) and 0xFF] xor (c ushr 8)
        val v = c.inv().toLong() and 0xFFFFFFFFL
        return v.toString(16).padStart(8, '0')
    }
}
