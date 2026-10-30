package sensor.protocol

/**
 * Reads little-endian fields in order. A read past the end flips [ok] to false and returns 0, so a parser reads everything the
 * flags announce and rejects the whole packet at the end if [ok] is false (a truncated packet is never half-used).
 */
class ByteReader(private val bytes: ByteArray, private var at: Int = 0) {
    var ok = true
        private set

    val remaining: Int get() = bytes.size - at

    fun skip(n: Int) {
        if (n < 0 || at + n > bytes.size) { ok = false; return }
        at += n
    }

    fun u8(): Int {
        if (at + 1 > bytes.size) { ok = false; return 0 }
        return bytes[at++].toInt() and 0xFF
    }

    fun u16(): Int {
        if (at + 2 > bytes.size) { ok = false; return 0 }
        val v = (bytes[at].toInt() and 0xFF) or ((bytes[at + 1].toInt() and 0xFF) shl 8)
        at += 2
        return v
    }

    fun s16(): Int {
        val v = u16()
        return if (v >= 0x8000) v - 0x10000 else v
    }

    fun u24(): Int {
        if (at + 3 > bytes.size) { ok = false; return 0 }
        val v = (bytes[at].toInt() and 0xFF) or ((bytes[at + 1].toInt() and 0xFF) shl 8) or ((bytes[at + 2].toInt() and 0xFF) shl 16)
        at += 3
        return v
    }

    fun u32(): Long {
        if (at + 4 > bytes.size) { ok = false; return 0L }
        val v = (bytes[at].toLong() and 0xFF) or ((bytes[at + 1].toLong() and 0xFF) shl 8) or
            ((bytes[at + 2].toLong() and 0xFF) shl 16) or ((bytes[at + 3].toLong() and 0xFF) shl 24)
        at += 4
        return v
    }
}
