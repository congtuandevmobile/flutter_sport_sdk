package workout.journal

/** Test-only access to the internal CRC, to build forged lines that carry a VALID checksum. */
object Crc32Probe {
    fun hex(text: String): String = Crc32.hex(text)
}
