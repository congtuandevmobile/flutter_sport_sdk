# ByteReader.kt

**Path:** `.../sensor/protocol/ByteReader.kt` · **Layer:** protocol

Little-endian reader (`u8`, `u16`, `s16`, `u24`, `u32`, `skip`). A read past the end sets `ok = false` and returns 0, so a parser reads every field the flags announce and rejects the whole packet at the end if `ok` is false: a truncated packet is never half-used.
