#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class ChallengeCoreChallengeDefinition, ChallengeCoreChallengeEngine, ChallengeCoreChallengeEngineCompanion, ChallengeCoreChallengeEvent, ChallengeCoreChallengeJournal, ChallengeCoreChallengeResult, ChallengeCoreChallengeResultCompanion, ChallengeCoreChallengeSession, ChallengeCoreChallengeSessionCompanion, ChallengeCoreChallengeSnapshot, ChallengeCoreChallengeState, ChallengeCoreCompletedStage, ChallengeCoreCompletionEvidence, ChallengeCoreCompletionPolicy, ChallengeCoreJournalRead, ChallengeCoreJournalStatus, ChallengeCoreKotlinArray<T>, ChallengeCoreKotlinEnum<E>, ChallengeCoreKotlinEnumCompanion, ChallengeCoreProgressMetric, ChallengeCoreProgressSample, ChallengeCoreRecoveredChallenge, ChallengeCoreRefusal, ChallengeCoreRestoredEngine, ChallengeCoreRestoredSession, ChallengeCoreStageDefinition, ChallengeCoreStageStatus;

@protocol ChallengeCoreKotlinComparable, ChallengeCoreKotlinIterator;

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
@interface ChallengeCoreBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface ChallengeCoreBase (ChallengeCoreBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface ChallengeCoreMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface ChallengeCoreMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorChallengeCoreKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface ChallengeCoreNumber : NSNumber
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
@interface ChallengeCoreByte : ChallengeCoreNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface ChallengeCoreUByte : ChallengeCoreNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface ChallengeCoreShort : ChallengeCoreNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface ChallengeCoreUShort : ChallengeCoreNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface ChallengeCoreInt : ChallengeCoreNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface ChallengeCoreUInt : ChallengeCoreNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface ChallengeCoreLong : ChallengeCoreNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface ChallengeCoreULong : ChallengeCoreNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface ChallengeCoreFloat : ChallengeCoreNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface ChallengeCoreDouble : ChallengeCoreNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface ChallengeCoreBoolean : ChallengeCoreNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end


/**
 * The challenge as a state machine of events. Every input returns a [ChallengeResult]: the events it caused (to be journaled BEFORE
 * the result is shown) or the reason it did nothing (never an exception for a bad input). Replaying the events gives the same
 * challenge ([restore]).
 *
 * Rules: one stage is active at a time; a sample counts only for the stage activation it was made for, from an allowed source and
 * with the stage's own metric, once (by event id); a stage that completes stays completed and never runs again; the total time
 * includes the transitions, the stage time freezes at completion, a pause is in neither. Not thread-safe: call it through one
 * serialized executor. All times come from one monotonic clock.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEngine")))
@interface ChallengeCoreChallengeEngine : ChallengeCoreBase
- (instancetype)initWithDefinition:(ChallengeCoreChallengeDefinition *)definition sessionId:(NSString *)sessionId __attribute__((swift_name("init(definition:sessionId:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) ChallengeCoreChallengeEngineCompanion *companion __attribute__((swift_name("companion")));
- (ChallengeCoreChallengeResult *)acceptSample:(ChallengeCoreProgressSample *)sample __attribute__((swift_name("accept(sample:)")));

/**
 * Whether a measurement taken at [atMs] may be looked at now: the challenge is ACTIVE and the measurement is not older than the
 * stage start, the last resume or the last accepted event. The session asks BEFORE it lets a counter touch a baseline: a stale
 * measurement that the engine would refuse must not become the baseline of the next one.
 */
- (BOOL)canIngestMeasurementAtAtMs:(int64_t)atMs __attribute__((swift_name("canIngestMeasurementAt(atMs:)")));

/**
 * Confirms the active stage. A MANUAL or SENSOR_OR_MANUAL stage takes MANUAL or JUDGE evidence; a JUDGE_REQUIRED one only JUDGE;
 * an AUTO one none. The judge is NOT authenticated here: the host or a backend must do that.
 */
- (ChallengeCoreChallengeResult *)confirmEvidence:(ChallengeCoreCompletionEvidence *)evidence atMs:(int64_t)atMs __attribute__((swift_name("confirm(evidence:atMs:)")));

/** The stage that is active now, or null before the start and after the end. */
- (int32_t)currentStageIndex __attribute__((swift_name("currentStageIndex()")));

/** Starts the next stage explicitly, so the transition time stays in the total. */
- (ChallengeCoreChallengeResult *)nextStageAtMs:(int64_t)atMs __attribute__((swift_name("nextStage(atMs:)")));

/** A pause by the user (refused when the definition forbids it). */
- (ChallengeCoreChallengeResult *)pauseAtMs:(int64_t)atMs __attribute__((swift_name("pause(atMs:)")));
- (ChallengeCoreChallengeResult *)resumeAtMs:(int64_t)atMs __attribute__((swift_name("resume(atMs:)")));
- (ChallengeCoreChallengeSnapshot *)snapshotAtMs:(int64_t)atMs __attribute__((swift_name("snapshot(atMs:)")));

/** The stage activation a sample must carry to count now. */
- (int64_t)stageActivation __attribute__((swift_name("stageActivation()")));
- (ChallengeCoreChallengeResult *)startAtMs:(int64_t)atMs __attribute__((swift_name("start(atMs:)")));

/**
 * The clock of a DURATION stage. Call it regularly (the runners do, once a second): when the ACTIVE time of the stage has reached its
 * target, the stage reaches its target AT THE MOMENT the time was reached (not when the tick came), and an AUTO stage completes with
 * TIMER evidence. The completion is an event like any other: it is journaled before it is shown, and a replay gives the same
 * result. Nothing happens in another state: a paused challenge does not run out of time, and neither does one that is not running.
 */
- (ChallengeCoreChallengeResult *)tickAtMs:(int64_t)atMs __attribute__((swift_name("tick(atMs:)")));
@property (readonly) ChallengeCoreChallengeState *currentState __attribute__((swift_name("currentState")));
@property (readonly) ChallengeCoreChallengeDefinition *definition __attribute__((swift_name("definition")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEngine.Companion")))
@interface ChallengeCoreChallengeEngineCompanion : ChallengeCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) ChallengeCoreChallengeEngineCompanion *shared __attribute__((swift_name("shared")));

/**
 * Rebuilds a challenge from its journal events, in any order and with duplicates (an event whose sequence number was already
 * applied is ignored). The definition comes from the Created event. A challenge that was ACTIVE or in a TRANSITION when the
 * process died comes back PAUSED at its last event, even when the definition forbids pausing: the time since is not counted
 * and the snapshot's `recoveries` says so, so a result with a recovery can be treated as not time-verified. The recovery adds a
 * Paused event for the journal. Null when there is no Created event.
 */
- (ChallengeCoreRestoredEngine * _Nullable)restoreEvents:(NSArray<ChallengeCoreChallengeEvent *> *)events __attribute__((swift_name("restore(events:)")));

/** How often a running DURATION stage leaves a checkpoint (an unmeasured starting value). */
@property (readonly) int64_t CHECKPOINT_EVERY_MS __attribute__((swift_name("CHECKPOINT_EVERY_MS")));
@end


/** A restored challenge and the events the recovery itself adds (to append to the journal). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RestoredEngine")))
@interface ChallengeCoreRestoredEngine : ChallengeCoreBase
- (instancetype)initWithEngine:(ChallengeCoreChallengeEngine *)engine recoveryEvents:(NSArray<ChallengeCoreChallengeEvent *> *)recoveryEvents ignoredEvents:(int32_t)ignoredEvents __attribute__((swift_name("init(engine:recoveryEvents:ignoredEvents:)"))) __attribute__((objc_designated_initializer));
@property (readonly) ChallengeCoreChallengeEngine *engine __attribute__((swift_name("engine")));
@property (readonly) int32_t ignoredEvents __attribute__((swift_name("ignoredEvents")));
@property (readonly) NSArray<ChallengeCoreChallengeEvent *> *recoveryEvents __attribute__((swift_name("recoveryEvents")));
@end


/**
 * The text form of the challenge events: one line per event, `C1|seq|type|atMs|fields...|crc`, the crc being a CRC-32 of everything
 * before it. The Created line carries the whole definition, so a challenge can be rebuilt from its journal alone. Independent of the
 * GPS and workout journals: it never holds a coordinate, and the three are never merged. Text is percent-escaped.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeJournal")))
@interface ChallengeCoreChallengeJournal : ChallengeCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * The text form of the challenge events: one line per event, `C1|seq|type|atMs|fields...|crc`, the crc being a CRC-32 of everything
 * before it. The Created line carries the whole definition, so a challenge can be rebuilt from its journal alone. Independent of the
 * GPS and workout journals: it never holds a coordinate, and the three are never merged. Text is percent-escaped.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)challengeJournal __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) ChallengeCoreChallengeJournal *shared __attribute__((swift_name("shared")));

/** The event of a line, or null when it is damaged, cut, forged, of another version or unknown. */
- (ChallengeCoreChallengeEvent * _Nullable)decodeLine:(NSString *)line __attribute__((swift_name("decode(line:)")));
- (NSString *)encodeE:(ChallengeCoreChallengeEvent *)e __attribute__((swift_name("encode(e:)")));

/**
 * Reads the lines of a journal: every intact line in order. The first damaged line ends the reading: when it is the LAST one it is
 * a write cut short (TAIL_REPAIRED), otherwise the damage is in the middle and only the prefix is trusted (PARTIAL).
 */
- (ChallengeCoreJournalRead *)readLines:(NSArray<NSString *> *)lines __attribute__((swift_name("read(lines:)")));

/** Rebuilds the challenge from its journal lines (null without a usable Created line). The session comes back PAUSED if it was running. */
- (ChallengeCoreRecoveredChallenge * _Nullable)recoverLines:(NSArray<NSString *> *)lines __attribute__((swift_name("recover(lines:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRead")))
@interface ChallengeCoreJournalRead : ChallengeCoreBase
- (instancetype)initWithEvents:(NSArray<ChallengeCoreChallengeEvent *> *)events status:(ChallengeCoreJournalStatus *)status droppedLines:(int32_t)droppedLines __attribute__((swift_name("init(events:status:droppedLines:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int32_t droppedLines __attribute__((swift_name("droppedLines")));
@property (readonly) NSArray<ChallengeCoreChallengeEvent *> *events __attribute__((swift_name("events")));
@property (readonly) ChallengeCoreJournalStatus *status __attribute__((swift_name("status")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol ChallengeCoreKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface ChallengeCoreKotlinEnum<E> : ChallengeCoreBase <ChallengeCoreKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) ChallengeCoreKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
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
@interface ChallengeCoreJournalStatus : ChallengeCoreKotlinEnum<ChallengeCoreJournalStatus *>
+ (instancetype)alloc __attribute__((unavailable));

/** What reading a journal found. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreJournalStatus *intact __attribute__((swift_name("intact")));
@property (class, readonly) ChallengeCoreJournalStatus *tailRepaired __attribute__((swift_name("tailRepaired")));
@property (class, readonly) ChallengeCoreJournalStatus *partial __attribute__((swift_name("partial")));
+ (ChallengeCoreKotlinArray<ChallengeCoreJournalStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreJournalStatus *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecoveredChallenge")))
@interface ChallengeCoreRecoveredChallenge : ChallengeCoreBase
- (instancetype)initWithRestored:(ChallengeCoreRestoredSession *)restored read:(ChallengeCoreJournalRead *)read __attribute__((swift_name("init(restored:read:)"))) __attribute__((objc_designated_initializer));
@property (readonly) ChallengeCoreJournalRead *read __attribute__((swift_name("read")));
@property (readonly) ChallengeCoreRestoredSession *restored __attribute__((swift_name("restored")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeDefinition")))
@interface ChallengeCoreChallengeDefinition : ChallengeCoreBase
- (instancetype)initWithId:(NSString *)id version:(int32_t)version stages:(NSArray<ChallengeCoreStageDefinition *> *)stages allowPause:(BOOL)allowPause __attribute__((swift_name("init(id:version:stages:allowPause:)"))) __attribute__((objc_designated_initializer));

/** False for a format where the clock must not stop. (A recovery after the process died still pauses: see the session.) */
@property (readonly) BOOL allowPause __attribute__((swift_name("allowPause")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSArray<ChallengeCoreStageDefinition *> *stages __attribute__((swift_name("stages")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@end


/**
 * Everything that changes a challenge is an event with a sequence number: the journal stores these and replaying them gives the same
 * challenge. `atMs` is the phone's monotonic clock.
 */
__attribute__((swift_name("ChallengeEvent")))
@interface ChallengeCoreChallengeEvent : ChallengeCoreBase
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end


/**
 * "The challenge was alive at [atMs]": written now and then while a DURATION stage runs, so that after the process dies the stage is
 * restored with the time it had already run (up to the last checkpoint) instead of the time of its last progress event.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.Checkpoint")))
@interface ChallengeCoreChallengeEventCheckpoint : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.Completed")))
@interface ChallengeCoreChallengeEventCompleted : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.Created")))
@interface ChallengeCoreChallengeEventCreated : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs sessionId:(NSString *)sessionId definition:(ChallengeCoreChallengeDefinition *)definition __attribute__((swift_name("init(seq:atMs:sessionId:definition:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) ChallengeCoreChallengeDefinition *definition __attribute__((swift_name("definition")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.Paused")))
@interface ChallengeCoreChallengeEventPaused : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs reason:(NSString *)reason __attribute__((swift_name("init(seq:atMs:reason:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) NSString *reason __attribute__((swift_name("reason")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.ProgressAdvanced")))
@interface ChallengeCoreChallengeEventProgressAdvanced : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs activation:(int64_t)activation eventId:(NSString *)eventId sourceId:(NSString *)sourceId delta:(double)delta __attribute__((swift_name("init(seq:atMs:activation:eventId:sourceId:delta:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t activation __attribute__((swift_name("activation")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) double delta __attribute__((swift_name("delta")));
@property (readonly) NSString *eventId __attribute__((swift_name("eventId")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) NSString *sourceId __attribute__((swift_name("sourceId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.Resumed")))
@interface ChallengeCoreChallengeEventResumed : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.StageActivated")))
@interface ChallengeCoreChallengeEventStageActivated : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs index:(int32_t)index activation:(int64_t)activation __attribute__((swift_name("init(seq:atMs:index:activation:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t activation __attribute__((swift_name("activation")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int32_t index __attribute__((swift_name("index")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.StageCompleted")))
@interface ChallengeCoreChallengeEventStageCompleted : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs activation:(int64_t)activation evidence:(ChallengeCoreCompletionEvidence *)evidence __attribute__((swift_name("init(seq:atMs:activation:evidence:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t activation __attribute__((swift_name("activation")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) ChallengeCoreCompletionEvidence *evidence __attribute__((swift_name("evidence")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.Started")))
@interface ChallengeCoreChallengeEventStarted : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs __attribute__((swift_name("init(seq:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeEvent.TargetReached")))
@interface ChallengeCoreChallengeEventTargetReached : ChallengeCoreChallengeEvent
- (instancetype)initWithSeq:(int64_t)seq atMs:(int64_t)atMs activation:(int64_t)activation __attribute__((swift_name("init(seq:atMs:activation:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t activation __attribute__((swift_name("activation")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@end


/** What an input caused: the events to journal, or the reason nothing happened. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeResult")))
@interface ChallengeCoreChallengeResult : ChallengeCoreBase
- (instancetype)initWithEvents:(NSArray<ChallengeCoreChallengeEvent *> *)events refusal:(ChallengeCoreRefusal * _Nullable)refusal __attribute__((swift_name("init(events:refusal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) ChallengeCoreChallengeResultCompanion *companion __attribute__((swift_name("companion")));
@property (readonly) BOOL accepted __attribute__((swift_name("accepted")));
@property (readonly) NSArray<ChallengeCoreChallengeEvent *> *events __attribute__((swift_name("events")));
@property (readonly) ChallengeCoreRefusal * _Nullable refusal __attribute__((swift_name("refusal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeResult.Companion")))
@interface ChallengeCoreChallengeResultCompanion : ChallengeCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) ChallengeCoreChallengeResultCompanion *shared __attribute__((swift_name("shared")));
- (ChallengeCoreChallengeResult *)refusedReason:(ChallengeCoreRefusal *)reason __attribute__((swift_name("refused(reason:)")));
@property (readonly) ChallengeCoreChallengeResult *NONE __attribute__((swift_name("NONE")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeSnapshot")))
@interface ChallengeCoreChallengeSnapshot : ChallengeCoreBase
- (instancetype)initWithState:(ChallengeCoreChallengeState *)state definitionId:(NSString *)definitionId definitionVersion:(int32_t)definitionVersion stageIndex:(int32_t)stageIndex stageId:(NSString * _Nullable)stageId stageActivation:(int64_t)stageActivation stageStatus:(ChallengeCoreStageStatus *)stageStatus stageProgress:(double)stageProgress stageTarget:(double)stageTarget totalElapsedMs:(int64_t)totalElapsedMs stageElapsedMs:(int64_t)stageElapsedMs completed:(NSArray<ChallengeCoreCompletedStage *> *)completed lastSeq:(int64_t)lastSeq recoveries:(int32_t)recoveries __attribute__((swift_name("init(state:definitionId:definitionVersion:stageIndex:stageId:stageActivation:stageStatus:stageProgress:stageTarget:totalElapsedMs:stageElapsedMs:completed:lastSeq:recoveries:)"))) __attribute__((objc_designated_initializer));
@property (readonly) NSArray<ChallengeCoreCompletedStage *> *completed __attribute__((swift_name("completed")));
@property (readonly) NSString *definitionId __attribute__((swift_name("definitionId")));
@property (readonly) int32_t definitionVersion __attribute__((swift_name("definitionVersion")));
@property (readonly) int64_t lastSeq __attribute__((swift_name("lastSeq")));

/** How many times the challenge was recovered after the process died: a result with a recovery is not time-verified. */
@property (readonly) int32_t recoveries __attribute__((swift_name("recoveries")));
@property (readonly) int64_t stageActivation __attribute__((swift_name("stageActivation")));

/** The current stage; frozen once it completes. */
@property (readonly) int64_t stageElapsedMs __attribute__((swift_name("stageElapsedMs")));
@property (readonly) NSString * _Nullable stageId __attribute__((swift_name("stageId")));
@property (readonly) int32_t stageIndex __attribute__((swift_name("stageIndex")));
@property (readonly) double stageProgress __attribute__((swift_name("stageProgress")));
@property (readonly) ChallengeCoreStageStatus *stageStatus __attribute__((swift_name("stageStatus")));
@property (readonly) double stageTarget __attribute__((swift_name("stageTarget")));
@property (readonly) ChallengeCoreChallengeState *state __attribute__((swift_name("state")));

/** The whole challenge, transitions included; a pause is not in it. */
@property (readonly) int64_t totalElapsedMs __attribute__((swift_name("totalElapsedMs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeState")))
@interface ChallengeCoreChallengeState : ChallengeCoreKotlinEnum<ChallengeCoreChallengeState *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreChallengeState *idle __attribute__((swift_name("idle")));
@property (class, readonly) ChallengeCoreChallengeState *active __attribute__((swift_name("active")));
@property (class, readonly) ChallengeCoreChallengeState *transition __attribute__((swift_name("transition")));
@property (class, readonly) ChallengeCoreChallengeState *paused __attribute__((swift_name("paused")));
@property (class, readonly) ChallengeCoreChallengeState *completed __attribute__((swift_name("completed")));
+ (ChallengeCoreKotlinArray<ChallengeCoreChallengeState *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreChallengeState *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CompletedStage")))
@interface ChallengeCoreCompletedStage : ChallengeCoreBase
- (instancetype)initWithStageId:(NSString *)stageId durationMs:(int64_t)durationMs progress:(double)progress evidence:(ChallengeCoreCompletionEvidence *)evidence __attribute__((swift_name("init(stageId:durationMs:progress:evidence:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t durationMs __attribute__((swift_name("durationMs")));
@property (readonly) ChallengeCoreCompletionEvidence *evidence __attribute__((swift_name("evidence")));
@property (readonly) double progress __attribute__((swift_name("progress")));
@property (readonly) NSString *stageId __attribute__((swift_name("stageId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CompletionEvidence")))
@interface ChallengeCoreCompletionEvidence : ChallengeCoreKotlinEnum<ChallengeCoreCompletionEvidence *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreCompletionEvidence *sensor __attribute__((swift_name("sensor")));
@property (class, readonly) ChallengeCoreCompletionEvidence *manual __attribute__((swift_name("manual")));
@property (class, readonly) ChallengeCoreCompletionEvidence *judge __attribute__((swift_name("judge")));
@property (class, readonly) ChallengeCoreCompletionEvidence *timer __attribute__((swift_name("timer")));
+ (ChallengeCoreKotlinArray<ChallengeCoreCompletionEvidence *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreCompletionEvidence *> *entries __attribute__((swift_name("entries")));
@end


/** How a stage is completed. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CompletionPolicy")))
@interface ChallengeCoreCompletionPolicy : ChallengeCoreKotlinEnum<ChallengeCoreCompletionPolicy *>
+ (instancetype)alloc __attribute__((unavailable));

/** How a stage is completed. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreCompletionPolicy *auto_ __attribute__((swift_name("auto_")));
@property (class, readonly) ChallengeCoreCompletionPolicy *manual __attribute__((swift_name("manual")));
@property (class, readonly) ChallengeCoreCompletionPolicy *sensorOrManual __attribute__((swift_name("sensorOrManual")));
@property (class, readonly) ChallengeCoreCompletionPolicy *judgeRequired __attribute__((swift_name("judgeRequired")));
+ (ChallengeCoreKotlinArray<ChallengeCoreCompletionPolicy *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreCompletionPolicy *> *entries __attribute__((swift_name("entries")));
@end


/** What a stage measures. A domain metric, never a generic "distance": a rower's metres cannot complete a run stage. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProgressMetric")))
@interface ChallengeCoreProgressMetric : ChallengeCoreKotlinEnum<ChallengeCoreProgressMetric *>
+ (instancetype)alloc __attribute__((unavailable));

/** What a stage measures. A domain metric, never a generic "distance": a rower's metres cannot complete a run stage. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreProgressMetric *runMeters __attribute__((swift_name("runMeters")));
@property (class, readonly) ChallengeCoreProgressMetric *rowMeters __attribute__((swift_name("rowMeters")));
@property (class, readonly) ChallengeCoreProgressMetric *skiMeters __attribute__((swift_name("skiMeters")));
@property (class, readonly) ChallengeCoreProgressMetric *sledMeters __attribute__((swift_name("sledMeters")));
@property (class, readonly) ChallengeCoreProgressMetric *swimMeters __attribute__((swift_name("swimMeters")));
@property (class, readonly) ChallengeCoreProgressMetric *reps __attribute__((swift_name("reps")));
@property (class, readonly) ChallengeCoreProgressMetric *duration __attribute__((swift_name("duration")));
@property (class, readonly) ChallengeCoreProgressMetric *cycleMeters __attribute__((swift_name("cycleMeters")));
+ (ChallengeCoreKotlinArray<ChallengeCoreProgressMetric *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreProgressMetric *> *entries __attribute__((swift_name("entries")));
@property (readonly) double maxRatePerSecond __attribute__((swift_name("maxRatePerSecond")));
@end


/** An already normalized and validated DELTA of a stage, NOT a device's cumulative counter. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProgressSample")))
@interface ChallengeCoreProgressSample : ChallengeCoreBase
- (instancetype)initWithEventId:(NSString *)eventId sessionId:(NSString *)sessionId stageActivation:(int64_t)stageActivation sourceId:(NSString *)sourceId metric:(ChallengeCoreProgressMetric *)metric delta:(double)delta atMs:(int64_t)atMs __attribute__((swift_name("init(eventId:sessionId:stageActivation:sourceId:metric:delta:atMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) double delta __attribute__((swift_name("delta")));

/** Unique per measurement and stable across restarts: a repeated id is never credited twice. */
@property (readonly) NSString *eventId __attribute__((swift_name("eventId")));
@property (readonly) ChallengeCoreProgressMetric *metric __attribute__((swift_name("metric")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@property (readonly) NSString *sourceId __attribute__((swift_name("sourceId")));

/** The stage activation the sample was made for: a callback of an older stage can never advance a newer one. */
@property (readonly) int64_t stageActivation __attribute__((swift_name("stageActivation")));
@end


/** Why an input did nothing (a diagnosis, not an exception). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Refusal")))
@interface ChallengeCoreRefusal : ChallengeCoreKotlinEnum<ChallengeCoreRefusal *>
+ (instancetype)alloc __attribute__((unavailable));

/** Why an input did nothing (a diagnosis, not an exception). */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreRefusal *wrongState __attribute__((swift_name("wrongState")));
@property (class, readonly) ChallengeCoreRefusal *notAllowed __attribute__((swift_name("notAllowed")));
@property (class, readonly) ChallengeCoreRefusal *pauseNotAllowed __attribute__((swift_name("pauseNotAllowed")));
@property (class, readonly) ChallengeCoreRefusal *timeBackwards __attribute__((swift_name("timeBackwards")));
@property (class, readonly) ChallengeCoreRefusal *wrongSession __attribute__((swift_name("wrongSession")));
@property (class, readonly) ChallengeCoreRefusal *staleActivation __attribute__((swift_name("staleActivation")));
@property (class, readonly) ChallengeCoreRefusal *wrongMetric __attribute__((swift_name("wrongMetric")));
@property (class, readonly) ChallengeCoreRefusal *sourceNotAllowed __attribute__((swift_name("sourceNotAllowed")));
@property (class, readonly) ChallengeCoreRefusal *badEventId __attribute__((swift_name("badEventId")));
@property (class, readonly) ChallengeCoreRefusal *duplicate __attribute__((swift_name("duplicate")));
@property (class, readonly) ChallengeCoreRefusal *badDelta __attribute__((swift_name("badDelta")));
@property (class, readonly) ChallengeCoreRefusal *targetReached __attribute__((swift_name("targetReached")));
+ (ChallengeCoreKotlinArray<ChallengeCoreRefusal *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreRefusal *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StageDefinition")))
@interface ChallengeCoreStageDefinition : ChallengeCoreBase
- (instancetype)initWithId:(NSString *)id metric:(ChallengeCoreProgressMetric *)metric target:(double)target policy:(ChallengeCoreCompletionPolicy *)policy allowedSources:(NSSet<NSString *> *)allowedSources __attribute__((swift_name("init(id:metric:target:policy:allowedSources:)"))) __attribute__((objc_designated_initializer));

/** Explicit bindings: only these sources may advance the stage ("gps-primary", "pm5-rower", "manual"). */
@property (readonly) NSSet<NSString *> *allowedSources __attribute__((swift_name("allowedSources")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) ChallengeCoreProgressMetric *metric __attribute__((swift_name("metric")));
@property (readonly) ChallengeCoreCompletionPolicy *policy __attribute__((swift_name("policy")));
@property (readonly) double target __attribute__((swift_name("target")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StageStatus")))
@interface ChallengeCoreStageStatus : ChallengeCoreKotlinEnum<ChallengeCoreStageStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) ChallengeCoreStageStatus *pending __attribute__((swift_name("pending")));
@property (class, readonly) ChallengeCoreStageStatus *active __attribute__((swift_name("active")));
@property (class, readonly) ChallengeCoreStageStatus *targetReached __attribute__((swift_name("targetReached")));
@property (class, readonly) ChallengeCoreStageStatus *completed __attribute__((swift_name("completed")));
+ (ChallengeCoreKotlinArray<ChallengeCoreStageStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<ChallengeCoreStageStatus *> *entries __attribute__((swift_name("entries")));
@end


/**
 * A [ChallengeEngine] and the feeding of it: it turns the cumulative counters that GPS and machines report into stage-local deltas.
 *
 *  - Event time decides which interval a measurement belongs to. Only an ACTIVE stage looks at counters, and a measurement made before
 *    the stage started or before the last resume is dropped (it never becomes a baseline). Every stage, and every resume, starts
 *    without a baseline: the first measurement after it is a baseline, so neither what moved while paused nor the distance of the
 *    previous stage is ever credited.
 *  - A counter advances a stage only if its source is allowed for it, and only ONE allowed source at a time (see [selectActive]).
 *  - A manual delta (reps, a station) carries its own event id from the host, so it is idempotent across restarts.
 *  - The baselines are not durable: after a restore the first sample of each source is a new baseline (a gap is never credited).
 * Not thread-safe: call it through one serialized executor.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeSession")))
@interface ChallengeCoreChallengeSession : ChallengeCoreBase
- (instancetype)initWithDefinition:(ChallengeCoreChallengeDefinition *)definition sessionId:(NSString *)sessionId __attribute__((swift_name("init(definition:sessionId:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) ChallengeCoreChallengeSessionCompanion *companion __attribute__((swift_name("companion")));
- (ChallengeCoreChallengeResult *)confirmEvidence:(ChallengeCoreCompletionEvidence *)evidence atMs:(int64_t)atMs __attribute__((swift_name("confirm(evidence:atMs:)")));

/** Like [confirm], refused with `STALE_ACTIVATION` when [expectedActivation] is not the active stage's ([CURRENT_ACTIVATION]: no check). */
- (ChallengeCoreChallengeResult *)confirmEvidence:(ChallengeCoreCompletionEvidence *)evidence atMs:(int64_t)atMs expectedActivation:(int64_t)expectedActivation __attribute__((swift_name("confirm(evidence:atMs:expectedActivation:)")));
- (ChallengeCoreChallengeResult *)nextStageAtMs:(int64_t)atMs __attribute__((swift_name("nextStage(atMs:)")));

/** A cumulative counter of [sourceId] (a GPS total, a machine's distance). */
- (ChallengeCoreChallengeResult *)onCounterSourceId:(NSString *)sourceId epoch:(int64_t)epoch counter:(double)counter atMs:(int64_t)atMs __attribute__((swift_name("onCounter(sourceId:epoch:counter:atMs:)")));

/** A delta of the current stage's metric from a source that counts for itself (reps, a station): [eventId] must be stable. */
- (ChallengeCoreChallengeResult *)onDeltaSourceId:(NSString *)sourceId eventId:(NSString *)eventId delta:(double)delta atMs:(int64_t)atMs __attribute__((swift_name("onDelta(sourceId:eventId:delta:atMs:)")));

/**
 * Like [onDelta], for the stage activation the host SAW when it made the measurement: a callback that arrives after the stage
 * changed is refused (`STALE_ACTIVATION`) instead of advancing the next stage. [CURRENT_ACTIVATION] means the current one.
 */
- (ChallengeCoreChallengeResult *)onDeltaSourceId:(NSString *)sourceId eventId:(NSString *)eventId delta:(double)delta atMs:(int64_t)atMs stageActivation:(int64_t)stageActivation __attribute__((swift_name("onDelta(sourceId:eventId:delta:atMs:stageActivation:)")));

/** A pause or a resume forgets every baseline: what moved while paused is never credited, however short the pause was. */
- (ChallengeCoreChallengeResult *)pauseAtMs:(int64_t)atMs __attribute__((swift_name("pause(atMs:)")));
- (ChallengeCoreChallengeResult *)resumeAtMs:(int64_t)atMs __attribute__((swift_name("resume(atMs:)")));
- (ChallengeCoreChallengeSnapshot *)snapshotAtMs:(int64_t)atMs __attribute__((swift_name("snapshot(atMs:)")));
- (ChallengeCoreChallengeResult *)startAtMs:(int64_t)atMs __attribute__((swift_name("start(atMs:)")));

/** The clock of a DURATION stage: call it about once a second (see [ChallengeEngine.tick]). */
- (ChallengeCoreChallengeResult *)tickAtMs:(int64_t)atMs __attribute__((swift_name("tick(atMs:)")));
@property (readonly) ChallengeCoreChallengeState *currentState __attribute__((swift_name("currentState")));
@property (readonly) ChallengeCoreChallengeDefinition *definition __attribute__((swift_name("definition")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChallengeSession.Companion")))
@interface ChallengeCoreChallengeSessionCompanion : ChallengeCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) ChallengeCoreChallengeSessionCompanion *shared __attribute__((swift_name("shared")));

/** A session for [definition] (Swift cannot use Kotlin default arguments). */
- (ChallengeCoreChallengeSession *)createDefinition:(ChallengeCoreChallengeDefinition *)definition sessionId:(NSString *)sessionId __attribute__((swift_name("create(definition:sessionId:)")));

/** Rebuilds a session from its journal events (see [ChallengeEngine.restore]). Null without a Created event. */
- (ChallengeCoreRestoredSession * _Nullable)restoreEvents:(NSArray<ChallengeCoreChallengeEvent *> *)events __attribute__((swift_name("restore(events:)")));

/** "The stage that is active now": the value to pass when the host does not say which activation a measurement was made for. */
@property (readonly) int64_t CURRENT_ACTIVATION __attribute__((swift_name("CURRENT_ACTIVATION")));
@end


/** A restored session and the events the recovery itself adds (to append to the journal). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RestoredSession")))
@interface ChallengeCoreRestoredSession : ChallengeCoreBase
- (instancetype)initWithSession:(ChallengeCoreChallengeSession *)session recoveryEvents:(NSArray<ChallengeCoreChallengeEvent *> *)recoveryEvents ignoredEvents:(int32_t)ignoredEvents __attribute__((swift_name("init(session:recoveryEvents:ignoredEvents:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int32_t ignoredEvents __attribute__((swift_name("ignoredEvents")));
@property (readonly) NSArray<ChallengeCoreChallengeEvent *> *recoveryEvents __attribute__((swift_name("recoveryEvents")));
@property (readonly) ChallengeCoreChallengeSession *session __attribute__((swift_name("session")));
@end


/**
 * Turns the cumulative counter of ONE source (GPS total, a machine's distance, a rep counter) into STAGE-LOCAL positive deltas for ONE
 * stage activation. The first sample after [activate] (or after a new connection epoch) is only a baseline; a counter that goes back,
 * a gap longer than [maxGapMs], or a jump faster than the metric's maximum rate is not credited. It never touches the recording the
 * counter comes from. The event id is `source/epoch/time`: the same measurement gets the same id after a restart.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StageCounterAdapter")))
@interface ChallengeCoreStageCounterAdapter : ChallengeCoreBase
- (instancetype)initWithSessionId:(NSString *)sessionId sourceId:(NSString *)sourceId metric:(ChallengeCoreProgressMetric *)metric maxRatePerSecond:(double)maxRatePerSecond maxGapMs:(int64_t)maxGapMs __attribute__((swift_name("init(sessionId:sourceId:metric:maxRatePerSecond:maxGapMs:)"))) __attribute__((objc_designated_initializer));
- (void)activateStageActivation:(int64_t)stageActivation __attribute__((swift_name("activate(stageActivation:)")));
- (ChallengeCoreProgressSample * _Nullable)onCounterConnectionEpoch:(int64_t)connectionEpoch counter:(double)counter atMs:(int64_t)atMs __attribute__((swift_name("onCounter(connectionEpoch:counter:atMs:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface ChallengeCoreKotlinEnumCompanion : ChallengeCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) ChallengeCoreKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface ChallengeCoreKotlinArray<T> : ChallengeCoreBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(ChallengeCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<ChallengeCoreKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("KotlinIterator")))
@protocol ChallengeCoreKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
