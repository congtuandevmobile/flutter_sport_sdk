package io.github.congtuandevmobile.flutter_workout

import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Where the workout journal lives. `append` returns only when the lines are on the disk (the engine shows a number only after
 * that), and fails with an [IOException] when they are not.
 */
interface WorkoutJournalStore {
    @Throws(IOException::class)
    fun append(sessionId: String, lines: List<String>)

    @Throws(IOException::class)
    fun read(sessionId: String): List<String>

    @Throws(IOException::class)
    fun clear(sessionId: String)

    /**
     * Replaces the journal by [lines] ATOMICALLY (a temporary file is written and synced, then renamed over it) after keeping the
     * previous content next to it for diagnosis. Used to cut a damaged tail off, so that what is appended later is never hidden
     * behind the damage. Returns the name of the kept original.
     */
    @Throws(IOException::class)
    fun replaceKeepingOriginal(sessionId: String, lines: List<String>): String

    /** The workout that was running or paused when it was last seen, or null. */
    fun activeSessionId(): String?

    @Throws(IOException::class)
    fun setActive(sessionId: String?)
}

/** One text file per workout in [dir], one line per event, synced to disk on every append. */
class FileWorkoutJournalStore(private val dir: File) : WorkoutJournalStore {
    init {
        dir.mkdirs()
    }

    private fun file(id: String) = File(dir, "workout-" + safe(id) + ".journal")
    private val pointer get() = File(dir, "workout-active.txt")

    override fun append(sessionId: String, lines: List<String>) {
        if (lines.isEmpty()) return
        FileOutputStream(file(sessionId), true).use { out ->
            out.write((lines.joinToString("\n") + "\n").toByteArray(Charsets.UTF_8))
            out.flush()
            out.fd.sync()
        }
    }

    override fun read(sessionId: String): List<String> {
        val f = file(sessionId)
        return if (f.exists()) f.readText(Charsets.UTF_8).split('\n').filter { it.isNotBlank() } else emptyList()
    }

    override fun replaceKeepingOriginal(sessionId: String, lines: List<String>): String {
        val current = file(sessionId)
        val kept = File(dir, current.name + ".damaged-" + System.currentTimeMillis())
        if (current.exists()) current.copyTo(kept, overwrite = false)
        val temp = File(dir, current.name + ".tmp")
        FileOutputStream(temp, false).use { out ->
            out.write((lines.joinToString("\n") + if (lines.isEmpty()) "" else "\n").toByteArray(Charsets.UTF_8))
            out.flush()
            out.fd.sync()
        }
        if (!temp.renameTo(current)) throw IOException("could not replace the journal")
        return kept.name
    }

    override fun clear(sessionId: String) {
        val f = file(sessionId)
        if (f.exists() && !f.delete()) throw IOException("could not delete the journal")
        if (activeSessionId() == sessionId) setActive(null)
    }

    override fun activeSessionId(): String? =
        try { pointer.takeIf { it.exists() }?.readText(Charsets.UTF_8)?.trim()?.ifEmpty { null } } catch (e: IOException) { null }

    override fun setActive(sessionId: String?) {
        if (sessionId == null) {
            if (pointer.exists() && !pointer.delete()) throw IOException("could not clear the active pointer")
            return
        }
        FileOutputStream(pointer, false).use { out ->
            out.write(sessionId.toByteArray(Charsets.UTF_8))
            out.flush()
            out.fd.sync()
        }
    }

    /** A file name from an id: letters and digits stay, anything else is written as its hex code, so two ids never collide. */
    private fun safe(id: String): String = buildString {
        for (c in id) if (c.isLetterOrDigit() && c.code < 128) append(c) else append('_').append(c.code.toString(16)).append('_')
    }
}
