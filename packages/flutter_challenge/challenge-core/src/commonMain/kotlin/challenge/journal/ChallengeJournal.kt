package challenge.journal

import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.StageDefinition
import challenge.session.ChallengeSession
import challenge.session.RestoredSession

/** What reading a journal found. */
enum class JournalStatus {
    /** Every line was intact. */
    INTACT,

    /** The LAST line was damaged (a write cut short) and was dropped. */
    TAIL_REPAIRED,

    /** A line in the middle was damaged: only what comes before it is kept. */
    PARTIAL,
}

class JournalRead(val events: List<ChallengeEvent>, val status: JournalStatus, val droppedLines: Int)

class RecoveredChallenge(val restored: RestoredSession, val read: JournalRead)

/**
 * The text form of the challenge events: one line per event, `C1|seq|type|atMs|fields...|crc`, the crc being a CRC-32 of everything
 * before it. The Created line carries the whole definition, so a challenge can be rebuilt from its journal alone. Independent of the
 * GPS and workout journals: it never holds a coordinate, and the three are never merged. Text is percent-escaped.
 */
object ChallengeJournal {
    private const val VERSION = "C1"

    fun encode(e: ChallengeEvent): String {
        val b = StringBuilder().append(VERSION).append('|').append(e.seq).append('|')
        when (e) {
            is ChallengeEvent.Created -> {
                val d = e.definition
                b.append("N|").append(e.atMs).append('|').append(esc(e.sessionId)).append('|').append(esc(d.id)).append('|')
                    .append(d.version).append('|').append(if (d.allowPause) 1 else 0).append('|').append(d.stages.size)
                for (s in d.stages) {
                    b.append('|').append(esc(s.id)).append('|').append(s.metric.name).append('|').append(s.target).append('|')
                        .append(s.policy.name).append('|').append(s.allowedSources.joinToString(",") { esc(it) })
                }
            }
            is ChallengeEvent.Started -> b.append("S|").append(e.atMs)
            is ChallengeEvent.StageActivated -> b.append("A|").append(e.atMs).append('|').append(e.index).append('|').append(e.activation)
            is ChallengeEvent.ProgressAdvanced ->
                b.append("P|").append(e.atMs).append('|').append(e.activation).append('|').append(esc(e.eventId)).append('|')
                    .append(esc(e.sourceId)).append('|').append(e.delta)
            is ChallengeEvent.TargetReached -> b.append("T|").append(e.atMs).append('|').append(e.activation)
            is ChallengeEvent.StageCompleted -> b.append("C|").append(e.atMs).append('|').append(e.activation).append('|').append(e.evidence.name)
            is ChallengeEvent.Paused -> b.append("U|").append(e.atMs).append('|').append(esc(e.reason))
            is ChallengeEvent.Resumed -> b.append("R|").append(e.atMs)
            is ChallengeEvent.Completed -> b.append("F|").append(e.atMs)
        }
        val text = b.toString()
        return text + "|" + Crc32.hex(text)
    }

    /** The event of a line, or null when it is damaged, cut, forged, of another version or unknown. */
    fun decode(line: String): ChallengeEvent? {
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
                "N" -> created(seq, at, p)
                "S" -> if (p.size == 4) ChallengeEvent.Started(seq, at) else null
                "A" -> if (p.size == 6) ChallengeEvent.StageActivated(seq, at, p[4].toInt(), p[5].toLong()) else null
                "P" -> if (p.size == 8) {
                    val delta = p[7].toDouble()
                    if (!delta.isFinite() || delta <= 0.0) null
                    else ChallengeEvent.ProgressAdvanced(seq, at, p[4].toLong(), unesc(p[5]), unesc(p[6]), delta)
                } else null
                "T" -> if (p.size == 5) ChallengeEvent.TargetReached(seq, at, p[4].toLong()) else null
                "C" -> if (p.size == 6) ChallengeEvent.StageCompleted(seq, at, p[4].toLong(), CompletionEvidence.valueOf(p[5])) else null
                "U" -> if (p.size == 5) ChallengeEvent.Paused(seq, at, unesc(p[4])) else null
                "R" -> if (p.size == 4) ChallengeEvent.Resumed(seq, at) else null
                "F" -> if (p.size == 4) ChallengeEvent.Completed(seq, at) else null
                else -> null
            }
        } catch (e: IllegalArgumentException) { // a bad number, an unknown enum, a definition that breaks its own rules
            null
        }
    }

    /**
     * Reads the lines of a journal: every intact line in order. The first damaged line ends the reading: when it is the LAST one it is
     * a write cut short (TAIL_REPAIRED), otherwise the damage is in the middle and only the prefix is trusted (PARTIAL).
     */
    fun read(lines: List<String>): JournalRead {
        val clean = lines.filter { it.isNotBlank() }
        val events = ArrayList<ChallengeEvent>(clean.size)
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

    /** Rebuilds the challenge from its journal lines (null without a usable Created line). The session comes back PAUSED if it was running. */
    fun recover(lines: List<String>): RecoveredChallenge? {
        val read = read(lines)
        val restored = ChallengeSession.restore(read.events) ?: return null
        return RecoveredChallenge(restored, read)
    }

    private fun created(seq: Long, at: Long, p: List<String>): ChallengeEvent? {
        if (p.size < 10) return null
        val count = p[8].toInt()
        if (count < 1 || p.size != 9 + count * 5) return null
        val stages = ArrayList<StageDefinition>(count)
        for (i in 0 until count) {
            val o = 9 + i * 5
            stages.add(
                StageDefinition(
                    unesc(p[o]), ProgressMetric.valueOf(p[o + 1]), p[o + 2].toDouble(), CompletionPolicy.valueOf(p[o + 3]),
                    p[o + 4].split(',').map { unesc(it) }.toSet(),
                ),
            )
        }
        val definition = ChallengeDefinition(unesc(p[5]), p[6].toInt(), stages, p[7] == "1")
        return ChallengeEvent.Created(seq, at, unesc(p[4]), definition)
    }

    private fun esc(text: String): String =
        text.replace("%", "%25").replace("|", "%7C").replace(",", "%2C").replace("\n", "%0A").replace("\r", "%0D")

    private fun unesc(text: String): String =
        text.replace("%0D", "\r").replace("%0A", "\n").replace("%2C", ",").replace("%7C", "|").replace("%25", "%")
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
        return (c.inv().toLong() and 0xFFFFFFFFL).toString(16).padStart(8, '0')
    }
}
