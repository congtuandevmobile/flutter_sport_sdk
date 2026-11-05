#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class WorkoutCoreDistanceLedgerConfig, WorkoutCoreDistanceLedgerConfigCompanion, WorkoutCoreDistanceSource, WorkoutCoreDistanceSourceKind, WorkoutCoreJournalRead, WorkoutCoreJournalStatus, WorkoutCoreKotlinArray<T>, WorkoutCoreKotlinEnum<E>, WorkoutCoreKotlinEnumCompanion, WorkoutCoreRecoveredWorkout, WorkoutCoreRestoredSession, WorkoutCoreWorkoutEvent, WorkoutCoreWorkoutJournal, WorkoutCoreWorkoutMode, WorkoutCoreWorkoutSession, WorkoutCoreWorkoutSessionCompanion, WorkoutCoreWorkoutSnapshot, WorkoutCoreWorkoutState;

@protocol WorkoutCoreKotlinComparable, WorkoutCoreKotlinIterator;

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wnullability"

#pragma push_macro("_Nullable_result")
#if !__has_feature(nullability_nullable_result)
#undef _Nullable_result
#define _Nullable_result _Nullable
#endif

__attribute__((swift_name("KotlinBase")))
@interface WorkoutCoreBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface WorkoutCoreBase (WorkoutCoreBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface WorkoutCoreMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface WorkoutCoreMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorWorkoutCoreKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface WorkoutCoreNumber : NSNumber
- (instancetype)initWithChar:(char)value __attribute__((unavailable));
- (instancetype)initWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
- (instancetype)initWithShort:(short)value __attribute__((unavailable));
- (instancetype)initWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
- (instancetype)initWithInt:(int)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
- (instancetype)initWithLong:(long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
- (instancetype)initWithLongLong:(long long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
- (instancetype)initWithFloat:(float)value __attribute__((unavailable));
- (instancetype)initWithDouble:(double)value __attribute__((unavailable));
- (instancetype)initWithBool:(BOOL)value __attribute__((unavailable));
- (instancetype)initWithInteger:(NSInteger)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
+ (instancetype)numberWithChar:(char)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
+ (instancetype)numberWithShort:(short)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
+ (instancetype)numberWithInt:(int)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
+ (instancetype)numberWithLong:(long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
+ (instancetype)numberWithLongLong:(long long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
+ (instancetype)numberWithFloat:(float)value __attribute__((unavailable));
+ (instancetype)numberWithDouble:(double)value __attribute__((unavailable));
+ (instancetype)numberWithBool:(BOOL)value __attribute__((unavailable));
+ (instancetype)numberWithInteger:(NSInteger)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
@end

__attribute__((swift_name("KotlinByte")))
@interface WorkoutCoreByte : WorkoutCoreNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface WorkoutCoreUByte : WorkoutCoreNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface WorkoutCoreShort : WorkoutCoreNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface WorkoutCoreUShort : WorkoutCoreNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface WorkoutCoreInt : WorkoutCoreNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface WorkoutCoreUInt : WorkoutCoreNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface WorkoutCoreLong : WorkoutCoreNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface WorkoutCoreULong : WorkoutCoreNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface WorkoutCoreFloat : WorkoutCoreNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface WorkoutCoreDouble : WorkoutCoreNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface WorkoutCoreBoolean : WorkoutCoreNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end


/**
 * The one place the distance of a workout is added up. A source gives either a cumulative COUNTER (a GPS total, a footpod, a
 * treadmill) or a SPEED to integrate; the ledger adds only DIFFERENCES, from a baseline, and only from ONE source at a time.
 *
 *  - The first sample of a source, of a new epoch, after a pause, after the workout started, or right after the source was
 *    chosen is a BASELINE: it credits nothing. A counter that goes back, or jumps more than the speed limit and the elapsed time
 *    allow, takes a new baseline too (a reset sensor never makes a spike or a negative distance).
 *  - Only the chosen source credits. Choice: the user's preference while it is fresh, else the chosen source while it stays
 *    fresh (it never alternates), else the best kind for the mode (outdoors GPS, then counter, then speed; indoors counter, then
 *    speed, then GPS), among equals the first seen. A source that returns after being stale does not take the distance back.
 *  - Switching keeps the distance counted so far: the new source starts from a new baseline (its total is never assigned).
 *  - A speed is integrated (trapezoid) only over gaps up to [DistanceLedgerConfig.maxIntegrationGapMs], never across a pause.
 *  - A sample older than the previous one of its source is ignored; a source's epoch must not go back.
 * Every change is returned as events with a sequence number from [nextSeq]; replaying the DistanceAdvanced deltas gives the
 * distance again. One monotonic clock; not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceLedger")))
@interface WorkoutCoreDistanceLedger : WorkoutCoreBase
- (instancetype)initWithMode:(WorkoutCoreWorkoutMode *)mode config:(WorkoutCoreDistanceLedgerConfig *)config nextSeq:(WorkoutCoreLong *(^)(void))nextSeq __attribute__((swift_name("init(mode:config:nextSeq:)"))) __attribute__((objc_designated_initializer));

/** The workout is counting (started or resumed): every source starts from a new baseline. */
- (void)activateReason:(NSString *)reason __attribute__((swift_name("activate(reason:)")));

/** The source that is counting now: [selected] while it is fresh, null when it went quiet (the distance so far is kept). */
- (WorkoutCoreDistanceSource * _Nullable)activeSourceNowMs:(int64_t)nowMs __attribute__((swift_name("activeSource(nowMs:)")));

/** The workout is not counting (paused or finished): nothing is credited and every baseline is forgotten. */
- (void)deactivate __attribute__((swift_name("deactivate()")));
- (NSArray<WorkoutCoreWorkoutEvent *> *)onCounterSource:(WorkoutCoreDistanceSource *)source epoch:(int64_t)epoch meters:(double)meters atMs:(int64_t)atMs __attribute__((swift_name("onCounter(source:epoch:meters:atMs:)")));
- (NSArray<WorkoutCoreWorkoutEvent *> *)onSpeedSource:(WorkoutCoreDistanceSource *)source epoch:(int64_t)epoch mps:(double)mps atMs:(int64_t)atMs __attribute__((swift_name("onSpeed(source:epoch:mps:atMs:)")));

/** The user's choice of source (null clears it). It only applies while that source is fresh. */
- (NSArray<WorkoutCoreWorkoutEvent *> *)setPreferredSource:(WorkoutCoreDistanceSource * _Nullable)source nowMs:(int64_t)nowMs __attribute__((swift_name("setPreferred(source:nowMs:)")));

/** Looks at the freshness of the sources without a new sample (a source went quiet). */
- (NSArray<WorkoutCoreWorkoutEvent *> *)tickNowMs:(int64_t)nowMs __attribute__((swift_name("tick(nowMs:)")));
@property (readonly) double distanceMeters __attribute__((swift_name("distanceMeters")));

/** The source that credited last: kept even when it went quiet (a history), never the one that is counting NOW. */
@property (readonly) WorkoutCoreDistanceSource * _Nullable selected __attribute__((swift_name("selected")));
@end


/** Starting values, not measured. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceLedgerConfig")))
@interface WorkoutCoreDistanceLedgerConfig : WorkoutCoreBase
- (instancetype)initWithStaleAfterMs:(int64_t)staleAfterMs maxSpeedMps:(double)maxSpeedMps spikeSlackMeters:(double)spikeSlackMeters maxIntegrationGapMs:(int64_t)maxIntegrationGapMs __attribute__((swift_name("init(staleAfterMs:maxSpeedMps:spikeSlackMeters:maxIntegrationGapMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) WorkoutCoreDistanceLedgerConfigCompanion *companion __attribute__((swift_name("companion")));

/** A speed is integrated only over a gap this short: a longer one is lost data, never credited. */
@property (readonly) int64_t maxIntegrationGapMs __attribute__((swift_name("maxIntegrationGapMs")));

/** The fastest speed a source may report (running 12 m/s, cycling 30 m/s): more is a spike, not a movement. */
@property (readonly) double maxSpeedMps __attribute__((swift_name("maxSpeedMps")));

/** A counter may move this much more than the maximum speed allows (jitter). */
@property (readonly) double spikeSlackMeters __attribute__((swift_name("spikeSlackMeters")));

/** A source with no sample for this long is stale and loses the distance to another one. */
@property (readonly) int64_t staleAfterMs __attribute__((swift_name("staleAfterMs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceLedgerConfig.Companion")))
@interface WorkoutCoreDistanceLedgerConfigCompanion : WorkoutCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) WorkoutCoreDistanceLedgerConfigCompanion *shared __attribute__((swift_name("shared")));
- (WorkoutCoreDistanceLedgerConfig *)forModeMode:(WorkoutCoreWorkoutMode *)mode __attribute__((swift_name("forMode(mode:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRead")))
@interface WorkoutCoreJournalRead : WorkoutCoreBase
- (instancetype)initWithEvents:(NSArray<WorkoutCoreWorkoutEvent *> *)events status:(WorkoutCoreJournalStatus *)status droppedLines:(int32_t)droppedLines __attribute__((swift_name("init(events:status:droppedLines:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int32_t droppedLines __attribute__((swift_name("droppedLines")));
@property (readonly) NSArray<WorkoutCoreWorkoutEvent *> *events __attribute__((swift_name("events")));
@property (readonly) WorkoutCoreJournalStatus *status __attribute__((swift_name("status")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol WorkoutCoreKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface WorkoutCoreKotlinEnum<E> : WorkoutCoreBase <WorkoutCoreKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) WorkoutCoreKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end


/** What reading a journal found. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalStatus")))
@interface WorkoutCoreJournalStatus : WorkoutCoreKotlinEnum<WorkoutCoreJournalStatus *>
+ (instancetype)alloc __attribute__((unavailable));

/** What reading a journal found. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) WorkoutCoreJournalStatus *intact __attribute__((swift_name("intact")));
@property (class, readonly) WorkoutCoreJournalStatus *tailRepaired __attribute__((swift_name("tailRepaired")));
@property (class, readonly) WorkoutCoreJournalStatus *partial __attribute__((swift_name("partial")));
+ (WorkoutCoreKotlinArray<WorkoutCoreJournalStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<WorkoutCoreJournalStatus *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecoveredWorkout")))
@interface WorkoutCoreRecoveredWorkout : WorkoutCoreBase
- (instancetype)initWithRestored:(WorkoutCoreRestoredSession *)restored read:(WorkoutCoreJournalRead *)read __attribute__((swift_name("init(restored:read:)"))) __attribute__((objc_designated_initializer));
@property (readonly) WorkoutCoreJournalRead *read __attribute__((swift_name("read")));
@property (readonly) WorkoutCoreRestoredSession *restored __attribute__((swift_name("restored")));
@end


/**
 * The text form of the workout events: one line per event, `W1|seq|type|atMs|fields...|crc`, where the crc (CRC-32 of everything
 * before it, in hex) lets a cut or damaged line be recognised. Text with `|`, `%` and line breaks is percent-escaped. This is the
 * WORKOUT journal: it is independent of the GPS journal and never holds a coordinate.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutJournal")))
@interface WorkoutCoreWorkoutJournal : WorkoutCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * The text form of the workout events: one line per event, `W1|seq|type|atMs|fields...|crc`, where the crc (CRC-32 of everything
 * before it, in hex) lets a cut or damaged line be recognised. Text with `|`, `%` and line breaks is percent-escaped. This is the
 * WORKOUT journal: it is independent of the GPS journal and never holds a coordinate.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)workoutJournal __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) WorkoutCoreWorkoutJournal *shared __attribute__((swift_name("shared")));

/** The event of a line, or null when the line is damaged, cut, of another version or unknown. */
- (WorkoutCoreWorkoutEvent * _Nullable)decodeLine:(NSString *)line __attribute__((swift_name("decode(line:)")));
- (NSString *)encodeE:(WorkoutCoreWorkoutEvent *)e __attribute__((swift_name("encode(e:)")));

/**
 * Reads the lines of a journal: every intact line in order. The first damaged line ends the reading; when it is the LAST one it is
 * a write that was cut short (TAIL_REPAIRED), otherwise the damage is in the middle and only the prefix is trusted (PARTIAL).
 */
- (WorkoutCoreJournalRead *)readLines:(NSArray<NSString *> *)lines __attribute__((swift_name("read(lines:)")));

/**
 * Rebuilds the workout from its journal lines. Null when there is no usable Started line. The session comes back PAUSED if it
 * was running; `restored.recoveryEvents` are to be appended to the journal (encode them like any event).
 */
- (WorkoutCoreRecoveredWorkout * _Nullable)recoverLines:(NSArray<NSString *> *)lines __attribute__((swift_name("recover(lines:)")));
@end


/** One place a distance can come from. Two sources of the SAME device (its counter and its speed) are two sources. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceSource")))
@interface WorkoutCoreDistanceSource : WorkoutCoreBase
- (instancetype)initWithId:(NSString *)id kind:(WorkoutCoreDistanceSourceKind *)kind __attribute__((swift_name("init(id:kind:)"))) __attribute__((objc_designated_initializer));
- (WorkoutCoreDistanceSource *)doCopyId:(NSString *)id kind:(WorkoutCoreDistanceSourceKind *)kind __attribute__((swift_name("doCopy(id:kind:)")));

/** One place a distance can come from. Two sources of the SAME device (its counter and its speed) are two sources. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** One place a distance can come from. Two sources of the SAME device (its counter and its speed) are two sources. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) WorkoutCoreDistanceSourceKind *kind __attribute__((swift_name("kind")));
@end


/** How a distance reaches the ledger. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceSourceKind")))
@interface WorkoutCoreDistanceSourceKind : WorkoutCoreKotlinEnum<WorkoutCoreDistanceSourceKind *>
+ (instancetype)alloc __attribute__((unavailable));

/** How a distance reaches the ledger. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) WorkoutCoreDistanceSourceKind *gps __attribute__((swift_name("gps")));
@property (class, readonly) WorkoutCoreDistanceSourceKind *counter __attribute__((swift_name("counter")));
@property (class, readonly) WorkoutCoreDistanceSourceKind *speed __attribute__((swift_name("speed")));
+ (WorkoutCoreKotlinArray<WorkoutCoreDistanceSourceKind *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<WorkoutCoreDistanceSourceKind *> *entries __attribute__((swift_name("entries")));
@end


/**
 * Everything that changes a workout is an event with a sequence number: the journal stores these, and replaying them gives the
 * same session again. `seq` grows by one per event of a session; `atMs` is the phone's monotonic clock.
 */
__attribute__((swift_name("WorkoutEvent")))
@interface WorkoutCoreWorkoutEvent : WorkoutCoreBase
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end


/** A source's counter was read as the new zero point: no distance is credited for it. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.BaselineEstablished")))
@interface WorkoutCoreWorkoutEventBaselineEstablished : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs source:(WorkoutCoreDistanceSource *)source value:(double)value reason:(NSString *)reason __attribute__((swift_name("init(seq:atMs:source:value:reason:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) NSString *reason __attribute__((swift_name("reason")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) WorkoutCoreDistanceSource *source __attribute__((swift_name("source")));
@property (readonly) double value __attribute__((swift_name("value")));
@end


/** [deltaMeters] (positive) were added to the workout distance, from [source]. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.DistanceAdvanced")))
@interface WorkoutCoreWorkoutEventDistanceAdvanced : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs source:(WorkoutCoreDistanceSource *)source deltaMeters:(double)deltaMeters __attribute__((swift_name("init(seq:atMs:source:deltaMeters:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) double deltaMeters __attribute__((swift_name("deltaMeters")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) WorkoutCoreDistanceSource *source __attribute__((swift_name("source")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.Finished")))
@interface WorkoutCoreWorkoutEventFinished : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.Paused")))
@interface WorkoutCoreWorkoutEventPaused : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.Resumed")))
@interface WorkoutCoreWorkoutEventResumed : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end


/** The distance now comes from [source]. The distance already counted is kept; the new source starts from a new baseline. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.SourceSelected")))
@interface WorkoutCoreWorkoutEventSourceSelected : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs source:(WorkoutCoreDistanceSource *)source reason:(NSString *)reason __attribute__((swift_name("init(seq:atMs:source:reason:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) NSString *reason __attribute__((swift_name("reason")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) WorkoutCoreDistanceSource *source __attribute__((swift_name("source")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutEvent.Started")))
@interface WorkoutCoreWorkoutEventStarted : WorkoutCoreWorkoutEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs mode:(WorkoutCoreWorkoutMode *)mode __attribute__((swift_name("init(seq:atMs:mode:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) WorkoutCoreWorkoutMode *mode __attribute__((swift_name("mode")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end


/** The kind of workout. It decides which distance source is preferred. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutMode")))
@interface WorkoutCoreWorkoutMode : WorkoutCoreKotlinEnum<WorkoutCoreWorkoutMode *>
+ (instancetype)alloc __attribute__((unavailable));

/** The kind of workout. It decides which distance source is preferred. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) WorkoutCoreWorkoutMode *outdoorRunning __attribute__((swift_name("outdoorRunning")));
@property (class, readonly) WorkoutCoreWorkoutMode *indoorRunning __attribute__((swift_name("indoorRunning")));
@property (class, readonly) WorkoutCoreWorkoutMode *outdoorCycling __attribute__((swift_name("outdoorCycling")));
@property (class, readonly) WorkoutCoreWorkoutMode *indoorCycling __attribute__((swift_name("indoorCycling")));
+ (WorkoutCoreKotlinArray<WorkoutCoreWorkoutMode *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<WorkoutCoreWorkoutMode *> *entries __attribute__((swift_name("entries")));
@property (readonly) BOOL isIndoor __attribute__((swift_name("isIndoor")));
@end


/** What the workout shows now. Times are milliseconds of the phone's monotonic clock; a pause is NOT in [activeMs]. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutSnapshot")))
@interface WorkoutCoreWorkoutSnapshot : WorkoutCoreBase
- (instancetype)initWithState:(WorkoutCoreWorkoutState *)state mode:(WorkoutCoreWorkoutMode * _Nullable)mode activeMs:(int64_t)activeMs pausedMs:(int64_t)pausedMs distanceMeters:(double)distanceMeters distanceSource:(WorkoutCoreDistanceSource * _Nullable)distanceSource lastDistanceSource:(WorkoutCoreDistanceSource * _Nullable)lastDistanceSource lastSeq:(int64_t)lastSeq __attribute__((swift_name("init(state:mode:activeMs:pausedMs:distanceMeters:distanceSource:lastDistanceSource:lastSeq:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t activeMs __attribute__((swift_name("activeMs")));
@property (readonly) double distanceMeters __attribute__((swift_name("distanceMeters")));

/** The source that is counting NOW, or null when none is chosen yet or the chosen one went quiet (the distance so far is kept). */
@property (readonly) WorkoutCoreDistanceSource * _Nullable distanceSource __attribute__((swift_name("distanceSource")));

/** The source that credited last, even if it went quiet: a history, not a promise that it is counting. */
@property (readonly) WorkoutCoreDistanceSource * _Nullable lastDistanceSource __attribute__((swift_name("lastDistanceSource")));
@property (readonly) int64_t lastSeq __attribute__((swift_name("lastSeq")));
@property (readonly) WorkoutCoreWorkoutMode * _Nullable mode __attribute__((swift_name("mode")));
@property (readonly) int64_t pausedMs __attribute__((swift_name("pausedMs")));
@property (readonly) WorkoutCoreWorkoutState *state __attribute__((swift_name("state")));
@end


/** The lifecycle of a session. A session is NOT a Bluetooth connection: a sensor can stay connected between two workouts. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutState")))
@interface WorkoutCoreWorkoutState : WorkoutCoreKotlinEnum<WorkoutCoreWorkoutState *>
+ (instancetype)alloc __attribute__((unavailable));

/** The lifecycle of a session. A session is NOT a Bluetooth connection: a sensor can stay connected between two workouts. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) WorkoutCoreWorkoutState *idle __attribute__((swift_name("idle")));
@property (class, readonly) WorkoutCoreWorkoutState *running __attribute__((swift_name("running")));
@property (class, readonly) WorkoutCoreWorkoutState *paused __attribute__((swift_name("paused")));
@property (class, readonly) WorkoutCoreWorkoutState *finished __attribute__((swift_name("finished")));
+ (WorkoutCoreKotlinArray<WorkoutCoreWorkoutState *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<WorkoutCoreWorkoutState *> *entries __attribute__((swift_name("entries")));
@end


/** A restored session and the events the recovery itself adds (to append to the journal). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RestoredSession")))
@interface WorkoutCoreRestoredSession : WorkoutCoreBase
- (instancetype)initWithSession:(WorkoutCoreWorkoutSession *)session recoveryEvents:(NSArray<WorkoutCoreWorkoutEvent *> *)recoveryEvents ignoredEvents:(int32_t)ignoredEvents __attribute__((swift_name("init(session:recoveryEvents:ignoredEvents:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int32_t ignoredEvents __attribute__((swift_name("ignoredEvents")));
@property (readonly) NSArray<WorkoutCoreWorkoutEvent *> *recoveryEvents __attribute__((swift_name("recoveryEvents")));
@property (readonly) WorkoutCoreWorkoutSession *session __attribute__((swift_name("session")));
@end


/**
 * One workout: a state machine (IDLE, RUNNING, PAUSED, FINISHED), the active and paused time, and the [DistanceLedger]. It owns
 * the state of the SESSION; a sensor connection is not part of it, so a sensor that stays connected between two workouts never
 * puts the old workout's data into the new one, and a lost sensor never stops the clock.
 *
 * Every call returns the events it caused (with a sequence number): the journal stores them. Times are the phone's monotonic
 * clock. The pause is not in `activeMs`. An invalid transition (pause while paused, anything after finish) does nothing and
 * returns no event. Not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutSession")))
@interface WorkoutCoreWorkoutSession : WorkoutCoreBase
- (instancetype)initWithMode:(WorkoutCoreWorkoutMode *)mode config:(WorkoutCoreDistanceLedgerConfig *)config __attribute__((swift_name("init(mode:config:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) WorkoutCoreWorkoutSessionCompanion *companion __attribute__((swift_name("companion")));
- (NSArray<WorkoutCoreWorkoutEvent *> *)finishNowMs:(int64_t)nowMs __attribute__((swift_name("finish(nowMs:)")));

/** A cumulative distance (a GPS total, a footpod, a treadmill). [epoch] grows with every new connection of the source. */
- (NSArray<WorkoutCoreWorkoutEvent *> *)onCounterSource:(WorkoutCoreDistanceSource *)source epoch:(int64_t)epoch meters:(double)meters atMs:(int64_t)atMs __attribute__((swift_name("onCounter(source:epoch:meters:atMs:)")));

/** An instantaneous speed in metres per second, integrated over time while the workout runs. */
- (NSArray<WorkoutCoreWorkoutEvent *> *)onSpeedSource:(WorkoutCoreDistanceSource *)source epoch:(int64_t)epoch mps:(double)mps atMs:(int64_t)atMs __attribute__((swift_name("onSpeed(source:epoch:mps:atMs:)")));
- (NSArray<WorkoutCoreWorkoutEvent *> *)pauseNowMs:(int64_t)nowMs __attribute__((swift_name("pause(nowMs:)")));
- (NSArray<WorkoutCoreWorkoutEvent *> *)resumeNowMs:(int64_t)nowMs __attribute__((swift_name("resume(nowMs:)")));

/** The user's choice of distance source (null clears it). */
- (NSArray<WorkoutCoreWorkoutEvent *> *)setPreferredSourceSource:(WorkoutCoreDistanceSource * _Nullable)source nowMs:(int64_t)nowMs __attribute__((swift_name("setPreferredSource(source:nowMs:)")));
- (WorkoutCoreWorkoutSnapshot *)snapshotNowMs:(int64_t)nowMs __attribute__((swift_name("snapshot(nowMs:)")));
- (NSArray<WorkoutCoreWorkoutEvent *> *)startNowMs:(int64_t)nowMs __attribute__((swift_name("start(nowMs:)")));

/** Lets a source that went quiet lose the distance to another one, without waiting for a sample. */
- (NSArray<WorkoutCoreWorkoutEvent *> *)tickNowMs:(int64_t)nowMs __attribute__((swift_name("tick(nowMs:)")));
@property (readonly) WorkoutCoreWorkoutState *currentState __attribute__((swift_name("currentState")));
@property (readonly) WorkoutCoreWorkoutMode *mode __attribute__((swift_name("mode")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WorkoutSession.Companion")))
@interface WorkoutCoreWorkoutSessionCompanion : WorkoutCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) WorkoutCoreWorkoutSessionCompanion *shared __attribute__((swift_name("shared")));

/** A session with the default limits of [mode] (Swift cannot use Kotlin default arguments). */
- (WorkoutCoreWorkoutSession *)forModeMode:(WorkoutCoreWorkoutMode *)mode __attribute__((swift_name("forMode(mode:)")));

/**
 * Rebuilds a session from its journal events, in any order and with duplicates: an event whose sequence number was already
 * applied is ignored, so replaying twice (or a journal with a repeated line) gives the same session. A session that was
 * RUNNING when the process died comes back PAUSED at its last event: the time since is NOT credited as activity and no
 * distance is invented; the recovery adds a Paused event for the journal. Returns null when there is no Started event.
 */
- (WorkoutCoreRestoredSession * _Nullable)restoreEvents:(NSArray<WorkoutCoreWorkoutEvent *> *)events __attribute__((swift_name("restore(events:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface WorkoutCoreKotlinEnumCompanion : WorkoutCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) WorkoutCoreKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface WorkoutCoreKotlinArray<T> : WorkoutCoreBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(WorkoutCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<WorkoutCoreKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("KotlinIterator")))
@protocol WorkoutCoreKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
