# WorkoutModel.kt

**Path:** `.../workout/model/WorkoutModel.kt` · **Layer:** model

`WorkoutMode` (outdoor/indoor running and cycling; `isIndoor` decides the preferred distance source), `WorkoutState` (IDLE, RUNNING, PAUSED, FINISHED), `DistanceSourceKind` (GPS: a cumulative total of a GPS engine; COUNTER: a cumulative counter of a device; SPEED: a speed that is integrated), `DistanceSource(id, kind)` (a device's counter and its speed are two sources), `WorkoutEvent` and `WorkoutSnapshot`. Everything that changes a workout is an event with a sequence number: Started, Paused, Resumed, Finished, SourceSelected, BaselineEstablished, DistanceAdvanced. The journal stores them and replaying them gives the same workout. The snapshot has the state, the active and the paused time (a pause is not activity), the distance and its source (null source = distance 0, never a guess).
