# SourcePolicy.kt

**Path:** `.../sensor/resolver/SourcePolicy.kt` · **Layer:** resolver

The default rank of a source for a metric (LOWER is better), from what the device really is: a heart rate sensor before a machine's heart rate; a footpod before a machine for running speed, cadence and stride; for cycling cadence a power meter, then a cadence sensor, then a trainer; for cycling speed a wheel sensor before a trainer; for power a power meter before a trainer or rower; no preference for the rest. The user's own choice always wins. Starting values, not measured.
