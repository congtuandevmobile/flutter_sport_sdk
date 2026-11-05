#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class TrackingCoreBridgePlan, TrackingCoreBridgeSettings, TrackingCoreBridgeSnapshot, TrackingCoreCadenceChoice, TrackingCoreCadenceResolver, TrackingCoreCadenceResolverCompanion, TrackingCoreCadenceResolverConfig, TrackingCoreCadenceResolverConfigCompanion, TrackingCoreCadenceSource, TrackingCoreCscCadenceParser, TrackingCoreCscCadenceParserCompanion, TrackingCoreDbscan, TrackingCoreDistanceLedger, TrackingCoreDistanceSource, TrackingCoreDouglasPeucker, TrackingCoreExternalCadenceHub, TrackingCoreExternalCadenceHubCompanion, TrackingCoreFixResult, TrackingCoreFixVerdict, TrackingCoreGapReconciler, TrackingCoreGapResult, TrackingCoreGeoMath, TrackingCoreGpsQuality, TrackingCoreJournalCodec, TrackingCoreJournalContents, TrackingCoreJournalRecord, TrackingCoreJournalRecordFinalized, TrackingCoreJournalRecordFinish, TrackingCoreJournalRecordFix, TrackingCoreJournalRecordHeader, TrackingCoreJournalRecordPause, TrackingCoreJournalRecordPdr, TrackingCoreJournalRecordRecovered, TrackingCoreJournalRecordResume, TrackingCoreJournalRecordSegmentSettled, TrackingCoreJournalRecordSegmentSteps, TrackingCoreJournalRecordStepCounter, TrackingCoreJournalRecordStepSensor, TrackingCoreJournalRecordStepsCorrection, TrackingCoreJournalRecordTick, TrackingCoreJournalStatus, TrackingCoreKMeans, TrackingCoreKalman2DOutput, TrackingCoreKalman2DStatus, TrackingCoreKotlinArray<T>, TrackingCoreKotlinByteArray, TrackingCoreKotlinByteIterator, TrackingCoreKotlinEnum<E>, TrackingCoreKotlinEnumCompanion, TrackingCoreKotlinIntArray, TrackingCoreKotlinIntIterator, TrackingCoreKotlinPair<__covariant A, __covariant B>, TrackingCoreLatLon, TrackingCoreLedgerEntry, TrackingCoreOutlierRejector, TrackingCorePdrPolicy, TrackingCorePedalCadenceEstimator, TrackingCorePedalCadenceEstimatorCompanion, TrackingCoreProjection, TrackingCoreRecordingState, TrackingCoreRecoveryResult, TrackingCoreRepairPlan, TrackingCoreRestoreResult, TrackingCoreRoadCandidate, TrackingCoreRoadEdge, TrackingCoreRoadGraph, TrackingCoreRoadNode, TrackingCoreRoutePath, TrackingCoreSamplingPlan, TrackingCoreSessionRecorder, TrackingCoreSessionRecorderCompanion, TrackingCoreSmoothing, TrackingCoreSport, TrackingCoreStartResult, TrackingCoreTrackingConfig, TrackingCoreTrackingConfigCompanion, TrackingCoreTrackingCoreBridge, TrackingCoreTrackingFix, TrackingCoreTrackingLog, TrackingCoreTrackingSnapshot, TrackingCoreXY;

@protocol TrackingCoreJournalSink, TrackingCoreKotlinComparable, TrackingCoreKotlinIterator;

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
@interface TrackingCoreBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface TrackingCoreBase (TrackingCoreBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface TrackingCoreMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface TrackingCoreMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorTrackingCoreKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface TrackingCoreNumber : NSNumber
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
@interface TrackingCoreByte : TrackingCoreNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface TrackingCoreUByte : TrackingCoreNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface TrackingCoreShort : TrackingCoreNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface TrackingCoreUShort : TrackingCoreNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface TrackingCoreInt : TrackingCoreNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface TrackingCoreUInt : TrackingCoreNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface TrackingCoreLong : TrackingCoreNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface TrackingCoreULong : TrackingCoreNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface TrackingCoreFloat : TrackingCoreNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface TrackingCoreDouble : TrackingCoreNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface TrackingCoreBoolean : TrackingCoreNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end


/** The chosen cadence: [rpm] is [CscCadenceParser.UNKNOWN] (negative) when [source] is [CadenceSource.NONE]. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CadenceChoice")))
@interface TrackingCoreCadenceChoice : TrackingCoreBase
- (instancetype)initWithRpm:(double)rpm source:(TrackingCoreCadenceSource *)source __attribute__((swift_name("init(rpm:source:)"))) __attribute__((objc_designated_initializer));
@property (readonly) double rpm __attribute__((swift_name("rpm")));
@property (readonly) TrackingCoreCadenceSource *source __attribute__((swift_name("source")));
@end


/**
 * Picks ONE cadence source: a healthy external sensor (a bike cadence sensor, a power meter) wins over the phone
 * estimate, which wins over nothing. Values are never mixed or averaged.
 *
 * Health is decided by connection and freshness, NEVER by the value: an external 0 rpm is a measurement (the cranks
 * are still) and keeps the source, it is not "no data" and must not fall back to the phone.
 *
 * To avoid flapping, an external source that was lost (disconnected, stale) is preferred again only after
 * [CadenceResolverConfig.externalRecoveryMinSamples] valid values over [CadenceResolverConfig.externalRecoveryMinMs].
 * All times come from one monotonic clock. Not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CadenceResolver")))
@interface TrackingCoreCadenceResolver : TrackingCoreBase
- (instancetype)initWithConfig:(TrackingCoreCadenceResolverConfig *)config __attribute__((swift_name("init(config:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCoreCadenceResolverCompanion *companion __attribute__((swift_name("companion")));

/** A measurement of the external source: [rpm] 0 or more is a value (0 = cranks still); anything else is ignored. */
- (void)onExternalRpm:(double)rpm atMs:(int64_t)atMs __attribute__((swift_name("onExternal(rpm:atMs:)")));

/** The external source (dis)connected. A disconnect drops its value at once and forgets its recovery progress. */
- (void)onExternalConnectionIsConnected:(BOOL)isConnected __attribute__((swift_name("onExternalConnection(isConnected:)")));

/** The phone estimate. Pass a negative [rpm] when it does not know (it then takes no part). */
- (void)onPhoneRpm:(double)rpm atMs:(int64_t)atMs __attribute__((swift_name("onPhone(rpm:atMs:)")));
- (void)reset __attribute__((swift_name("reset()")));
- (TrackingCoreCadenceChoice *)resultNowMs:(int64_t)nowMs __attribute__((swift_name("result(nowMs:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CadenceResolver.Companion")))
@interface TrackingCoreCadenceResolverCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreCadenceResolverCompanion *shared __attribute__((swift_name("shared")));
- (TrackingCoreCadenceResolver *)standard __attribute__((swift_name("standard()")));
@end


/** Starting values, not measured. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CadenceResolverConfig")))
@interface TrackingCoreCadenceResolverConfig : TrackingCoreBase
- (instancetype)initWithExternalStaleAfterMs:(int64_t)externalStaleAfterMs phoneStaleAfterMs:(int64_t)phoneStaleAfterMs externalRecoveryMinSamples:(int32_t)externalRecoveryMinSamples externalRecoveryMinMs:(int64_t)externalRecoveryMinMs __attribute__((swift_name("init(externalStaleAfterMs:phoneStaleAfterMs:externalRecoveryMinSamples:externalRecoveryMinMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCoreCadenceResolverConfigCompanion *companion __attribute__((swift_name("companion")));

/** ...spread over at least this long, before it is preferred again. */
@property (readonly) int64_t externalRecoveryMinMs __attribute__((swift_name("externalRecoveryMinMs")));

/** After a (re)connect or a stale spell the external source needs this many valid values... */
@property (readonly) int32_t externalRecoveryMinSamples __attribute__((swift_name("externalRecoveryMinSamples")));

/** An external source with no valid value for this long is stale. */
@property (readonly) int64_t externalStaleAfterMs __attribute__((swift_name("externalStaleAfterMs")));

/** The phone estimate older than this is stale. */
@property (readonly) int64_t phoneStaleAfterMs __attribute__((swift_name("phoneStaleAfterMs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CadenceResolverConfig.Companion")))
@interface TrackingCoreCadenceResolverConfigCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreCadenceResolverConfigCompanion *shared __attribute__((swift_name("shared")));
- (TrackingCoreCadenceResolverConfig *)standard __attribute__((swift_name("standard()")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol TrackingCoreKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface TrackingCoreKotlinEnum<E> : TrackingCoreBase <TrackingCoreKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCoreKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end


/** Where a cadence value came from. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CadenceSource")))
@interface TrackingCoreCadenceSource : TrackingCoreKotlinEnum<TrackingCoreCadenceSource *>
+ (instancetype)alloc __attribute__((unavailable));

/** Where a cadence value came from. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreCadenceSource *none __attribute__((swift_name("none")));
@property (class, readonly) TrackingCoreCadenceSource *phone __attribute__((swift_name("phone")));
@property (class, readonly) TrackingCoreCadenceSource *external __attribute__((swift_name("external")));
+ (TrackingCoreKotlinArray<TrackingCoreCadenceSource *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreCadenceSource *> *entries __attribute__((swift_name("entries")));
@end


/**
 * Decodes the Bluetooth "CSC Measurement" characteristic (0x2A5B) and turns the crank counters into a cadence.
 * Pure Kotlin: no Bluetooth, no clock of its own. The host (a BLE plugin) owns the connection and hands the raw bytes.
 *
 * Packet: flags (1 byte; bit 0 = wheel data, bit 1 = crank data), then wheel revolutions (uint32) and last wheel event
 * time (uint16) when bit 0 is set, then crank revolutions (uint16) and last crank event time (uint16, 1/1024 s) when
 * bit 1 is set. A wheel-only packet carries no cadence.
 *
 * [onMeasurement] answers with a cadence in rpm, [ZERO] when the cranks are verified stopped, or [UNKNOWN]:
 *  - A value is computed between two consecutive crank EVENTS, so the 16-bit counters may wrap freely.
 *  - "Stopped" needs valid notifications that keep arriving with an unchanged crank counter for longer than a
 *    revolution can take ([zeroAfterMs], or twice the last revolution time when that is longer). The lack of
 *    notifications is NOT zero: it is "unknown" once [staleMs] passes (see [rpm]).
 *  - The 16-bit event clock wraps every 64 s: when the previous revolution is [eventClockSpanMs] or more in the past the
 *    two samples are not comparable, so a new baseline is taken and no value is given.
 *  - A counter jump the elapsed time cannot explain (a sensor reset, a reconnect) takes a new baseline too.
 * Call [reset] for every new connection: the last sample of an old connection must never be compared with the first
 * of a new one. All `nowMs` must come from the same monotonic clock. Not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CscCadenceParser")))
@interface TrackingCoreCscCadenceParser : TrackingCoreBase
- (instancetype)initWithStaleMs:(int64_t)staleMs zeroAfterMs:(int64_t)zeroAfterMs minRpm:(double)minRpm maxRpm:(double)maxRpm silenceResetMs:(int64_t)silenceResetMs eventClockSpanMs:(int64_t)eventClockSpanMs __attribute__((swift_name("init(staleMs:zeroAfterMs:minRpm:maxRpm:silenceResetMs:eventClockSpanMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCoreCscCadenceParserCompanion *companion __attribute__((swift_name("companion")));

/** The crank counters of one notification (already decoded), for a caller that has no `ByteArray` at hand. */
- (double)onCrankCount:(int32_t)count eventTicks:(int32_t)eventTicks nowMs:(int64_t)nowMs __attribute__((swift_name("onCrank(count:eventTicks:nowMs:)")));

/** One notification. Malformed and wheel-only packets are ignored (the answer is [UNKNOWN], the state untouched). */
- (double)onMeasurementBytes:(TrackingCoreKotlinByteArray *)bytes nowMs:(int64_t)nowMs __attribute__((swift_name("onMeasurement(bytes:nowMs:)")));

/** Forgets the baseline and the value (a new connection, a closed session). */
- (void)reset __attribute__((swift_name("reset()")));

/** The last answer while notifications keep arriving, [UNKNOWN] once none came for [staleMs] (never [ZERO]). */
- (double)rpmNowMs:(int64_t)nowMs __attribute__((swift_name("rpm(nowMs:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CscCadenceParser.Companion")))
@interface TrackingCoreCscCadenceParserCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreCscCadenceParserCompanion *shared __attribute__((swift_name("shared")));

/**
 * The crank revolution counter and the last crank event time of a CSC Measurement, or null for a packet that
 * is empty, truncated, or has no crank data (wheel only).
 */
- (TrackingCoreKotlinIntArray * _Nullable)decodeCrankBytes:(TrackingCoreKotlinByteArray *)bytes __attribute__((swift_name("decodeCrank(bytes:)")));

/** A parser with the starting values (Swift cannot use Kotlin default arguments). */
- (TrackingCoreCscCadenceParser *)standard __attribute__((swift_name("standard()")));

/** Returned when there is no usable cadence. */
@property (readonly) double UNKNOWN __attribute__((swift_name("UNKNOWN")));

/** Returned when the cranks are verified stopped. */
@property (readonly) double ZERO __attribute__((swift_name("ZERO")));
@end


/**
 * What a native engine holds for cadence that does NOT come from the phone: it takes the raw CSC notifications (or a
 * ready rpm from any other source, such as a power meter) that a host-owned BLE component pushes, and answers with the
 * chosen cadence together with the phone estimate. The SDK never scans, pairs or reconnects: the host does, and tells the
 * hub through [onConnection].
 *
 * A source is identified by `(sourceId, connectionId)`. `connectionId` is a number the host bumps for every new
 * connection to the device, so a late notification of an old connection is dropped and the counters of a new connection
 * are never compared with those of the old one. Data of a connection that was closed is ignored until the host opens a new
 * one. Live only: nothing here is journaled and nothing touches distance. All times come from one monotonic clock.
 * Not thread-safe (the engine calls it under its own lock/queue).
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ExternalCadenceHub")))
@interface TrackingCoreExternalCadenceHub : TrackingCoreBase
- (instancetype)initWithConfig:(TrackingCoreCadenceResolverConfig *)config __attribute__((swift_name("init(config:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCoreExternalCadenceHubCompanion *companion __attribute__((swift_name("companion")));

/** True while an external source is connected (it keeps the cadence available when the phone one is off). */
- (BOOL)hasExternalSource __attribute__((swift_name("hasExternalSource()")));

/** The host connected to (or lost) the device. A different identity replaces the current source. */
- (void)onConnectionSourceId:(NSString *)sourceId connectionId:(int64_t)connectionId connected:(BOOL)connected __attribute__((swift_name("onConnection(sourceId:connectionId:connected:)")));

/** A raw CSC Measurement notification. */
- (void)onCscSourceId:(NSString *)sourceId connectionId:(int64_t)connectionId bytes:(TrackingCoreKotlinByteArray *)bytes nowMs:(int64_t)nowMs __attribute__((swift_name("onCsc(sourceId:connectionId:bytes:nowMs:)")));

/** A cadence already in rpm, from a source that is not CSC. 0 is a measurement. */
- (void)onRpmSourceId:(NSString *)sourceId connectionId:(int64_t)connectionId rpm:(double)rpm nowMs:(int64_t)nowMs __attribute__((swift_name("onRpm(sourceId:connectionId:rpm:nowMs:)")));
- (void)reset __attribute__((swift_name("reset()")));

/** The cadence to show: the external source when healthy, else the phone estimate ([phoneRpm] negative if none). */
- (TrackingCoreCadenceChoice *)resolvePhoneRpm:(double)phoneRpm nowMs:(int64_t)nowMs __attribute__((swift_name("resolve(phoneRpm:nowMs:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ExternalCadenceHub.Companion")))
@interface TrackingCoreExternalCadenceHubCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreExternalCadenceHubCompanion *shared __attribute__((swift_name("shared")));
- (TrackingCoreExternalCadenceHub *)standard __attribute__((swift_name("standard()")));
@end


/**
 * Constant-velocity Kalman filter on a local tangent plane (one independent
 * filter per axis), fed by GPS positions weighted by their accuracy. In the
 * engine it is a QUALITY GATE: it says whether an observation is plausible, and
 * the distance is always measured on the RAW accepted fixes, never on the
 * filtered coordinates (smoothing would cut corners and lose distance).
 *
 * An observation too far from the prediction (chi-square gate) is rejected;
 * after [resetAfterRejects] in a row, or after a silence longer than
 * [maxGapMs], the filter re-localizes and reports a DISCONTINUITY, which the
 * caller must treat as a new anchor, never as a distance step.
 *
 * Limits: no accelerometer or gyroscope fusion, one motion model for every sport,
 * and sharp turns can be rejected.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kalman2D")))
@interface TrackingCoreKalman2D : TrackingCoreBase
- (instancetype)initWithAccelerationSigma:(double)accelerationSigma gateChiSquare:(double)gateChiSquare maxGapMs:(int64_t)maxGapMs resetAfterRejects:(int32_t)resetAfterRejects __attribute__((swift_name("init(accelerationSigma:gateChiSquare:maxGapMs:resetAfterRejects:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreKalman2DOutput *)pushLatitude:(double)latitude longitude:(double)longitude accuracyMeters:(double)accuracyMeters timeMs:(int64_t)timeMs __attribute__((swift_name("push(latitude:longitude:accuracyMeters:timeMs:)")));
- (void)reset __attribute__((swift_name("reset()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kalman2D.Output")))
@interface TrackingCoreKalman2DOutput : TrackingCoreBase
- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude accepted:(BOOL)accepted discontinuity:(BOOL)discontinuity status:(TrackingCoreKalman2DStatus *)status __attribute__((swift_name("init(latitude:longitude:accepted:discontinuity:status:)"))) __attribute__((objc_designated_initializer));

/** False when the observation was gated out (the position is the prediction). */
@property (readonly) BOOL accepted __attribute__((swift_name("accepted")));

/** True when the filter re-localized: do not measure distance across it. */
@property (readonly) BOOL discontinuity __attribute__((swift_name("discontinuity")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@property (readonly) TrackingCoreKalman2DStatus *status __attribute__((swift_name("status")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kalman2D.Status")))
@interface TrackingCoreKalman2DStatus : TrackingCoreKotlinEnum<TrackingCoreKalman2DStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreKalman2DStatus *initialized __attribute__((swift_name("initialized")));
@property (class, readonly) TrackingCoreKalman2DStatus *updated __attribute__((swift_name("updated")));
@property (class, readonly) TrackingCoreKalman2DStatus *rejected __attribute__((swift_name("rejected")));
@property (class, readonly) TrackingCoreKalman2DStatus *outOfOrder __attribute__((swift_name("outOfOrder")));
@property (class, readonly) TrackingCoreKalman2DStatus *gapReset __attribute__((swift_name("gapReset")));
@property (class, readonly) TrackingCoreKalman2DStatus *relocalized __attribute__((swift_name("relocalized")));
+ (TrackingCoreKotlinArray<TrackingCoreKalman2DStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreKalman2DStatus *> *entries __attribute__((swift_name("entries")));
@end


/**
 * Exponential moving average for scalar signals (speed, altitude) AFTER the
 * outliers were removed. Do not stack it on top of [Kalman2D] output: that only
 * adds delay.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LowPassFilter")))
@interface TrackingCoreLowPassFilter : TrackingCoreBase
- (instancetype)initWithAlpha:(double)alpha __attribute__((swift_name("init(alpha:)"))) __attribute__((objc_designated_initializer));
- (double)pushValue:(double)value __attribute__((swift_name("push(value:)")));
- (void)reset __attribute__((swift_name("reset()")));
@end


/** Rejects a position change that implies an impossible speed. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OutlierRejector")))
@interface TrackingCoreOutlierRejector : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/** Rejects a position change that implies an impossible speed. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)outlierRejector __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreOutlierRejector *shared __attribute__((swift_name("shared")));

/**
 * True when covering [distanceMeters] in [seconds] needs more than [maxSpeedMps].
 * A non-finite or negative input, or no elapsed time, is NOT a valid
 * measurement and counts as a jump.
 */
- (BOOL)isJumpDistanceMeters:(double)distanceMeters seconds:(double)seconds maxSpeedMps:(double)maxSpeedMps __attribute__((swift_name("isJump(distanceMeters:seconds:maxSpeedMps:)")));
@end


/**
 * Credits ONE measurement interval (a GPS gap) once: the larger of the straight
 * line across it, shrunk by its own uncertainty, and the step estimate that GPS
 * corroborates. It never adds the two. A pending estimate is accepted only up
 * to `lowerChord / pdrConfirmRatio`, so a large estimate cannot be taken just
 * because GPS moved a little, and a phone shaken without GPS (chord about 0)
 * adds nothing.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GapReconciler")))
@interface TrackingCoreGapReconciler : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Credits ONE measurement interval (a GPS gap) once: the larger of the straight
 * line across it, shrunk by its own uncertainty, and the step estimate that GPS
 * corroborates. It never adds the two. A pending estimate is accepted only up
 * to `lowerChord / pdrConfirmRatio`, so a large estimate cannot be taken just
 * because GPS moved a little, and a phone shaken without GPS (chord about 0)
 * adds nothing.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)gapReconciler __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreGapReconciler *shared __attribute__((swift_name("shared")));
- (TrackingCoreGapResult *)reconcileChordMeters:(double)chordMeters uncertaintyMeters:(double)uncertaintyMeters gapMs:(int64_t)gapMs pendingPdrMeters:(double)pendingPdrMeters config:(TrackingCoreTrackingConfig *)config strideCalibrated:(BOOL)strideCalibrated __attribute__((swift_name("reconcile(chordMeters:uncertaintyMeters:gapMs:pendingPdrMeters:config:strideCalibrated:)")));
@end


/** What a GPS gap is worth. [note] explains it in the log (no coordinates). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GapResult")))
@interface TrackingCoreGapResult : TrackingCoreBase
- (instancetype)initWithCreditMeters:(double)creditMeters source:(TrackingCoreDistanceSource *)source note:(NSString *)note __attribute__((swift_name("init(creditMeters:source:note:)"))) __attribute__((objc_designated_initializer));
@property (readonly) double creditMeters __attribute__((swift_name("creditMeters")));
@property (readonly) NSString *note __attribute__((swift_name("note")));
@property (readonly) TrackingCoreDistanceSource *source __attribute__((swift_name("source")));
@end


/**
 * Polyline simplification for DISPLAY and UPLOAD size. Never use the simplified
 * line to measure distance: it is shorter than the real route by design.
 * Iterative (no recursion), so a long route cannot overflow the stack.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DouglasPeucker")))
@interface TrackingCoreDouglasPeucker : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Polyline simplification for DISPLAY and UPLOAD size. Never use the simplified
 * line to measure distance: it is shorter than the real route by design.
 * Iterative (no recursion), so a long route cannot overflow the stack.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)douglasPeucker __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreDouglasPeucker *shared __attribute__((swift_name("shared")));
- (NSArray<TrackingCoreLatLon *> *)simplifyPoints:(NSArray<TrackingCoreLatLon *> *)points toleranceMeters:(double)toleranceMeters __attribute__((swift_name("simplify(points:toleranceMeters:)")));
@end


/**
 * Geodesy helpers on a sphere: accurate to well under a metre per kilometre for
 * the haversine; the local tangent plane is for SHORT ranges only (a few
 * kilometres) and refuses the poles. Longitudes wrap at +-180 degrees.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GeoMath")))
@interface TrackingCoreGeoMath : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Geodesy helpers on a sphere: accurate to well under a metre per kilometre for
 * the haversine; the local tangent plane is for SHORT ranges only (a few
 * kilometres) and refuses the poles. Longitudes wrap at +-180 degrees.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)geoMath __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreGeoMath *shared __attribute__((swift_name("shared")));

/** Metres east/north of the origin -> (latitude, longitude). */
- (TrackingCoreKotlinPair<TrackingCoreDouble *, TrackingCoreDouble *> *)fromXYOriginLat:(double)originLat originLon:(double)originLon p:(TrackingCoreXY *)p __attribute__((swift_name("fromXY(originLat:originLon:p:)")));

/** Great-circle distance in metres. Throws for an invalid coordinate. */
- (double)haversineMetersLat1:(double)lat1 lon1:(double)lon1 lat2:(double)lat2 lon2:(double)lon2 __attribute__((swift_name("haversineMeters(lat1:lon1:lat2:lon2:)")));
- (double)metersPerDegreeLat __attribute__((swift_name("metersPerDegreeLat()")));
- (double)metersPerDegreeLonLatitude:(double)latitude __attribute__((swift_name("metersPerDegreeLon(latitude:)")));

/** Projects a point onto the segment a-b, clamped to its ends. Short segments only. */
- (TrackingCoreProjection *)projectLat:(double)lat lon:(double)lon aLat:(double)aLat aLon:(double)aLon bLat:(double)bLat bLon:(double)bLon __attribute__((swift_name("project(lat:lon:aLat:aLon:bLat:bLon:)")));

/** Coordinates -> metres east/north of the origin (short ranges, not at the poles). */
- (TrackingCoreXY *)toXYOriginLat:(double)originLat originLon:(double)originLon lat:(double)lat lon:(double)lon __attribute__((swift_name("toXY(originLat:originLon:lat:lon:)")));

/** True for a finite coordinate on Earth. */
- (BOOL)validLatitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("valid(latitude:longitude:)")));
@property (readonly) double EARTH_RADIUS_METERS __attribute__((swift_name("EARTH_RADIUS_METERS")));
@end


/** A coordinate pair for polyline work. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LatLon")))
@interface TrackingCoreLatLon : TrackingCoreBase
- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("init(latitude:longitude:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreLatLon *)doCopyLatitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("doCopy(latitude:longitude:)")));

/** A coordinate pair for polyline work. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** A coordinate pair for polyline work. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** A coordinate pair for polyline work. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@end


/** Result of projecting a point onto a segment. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Projection")))
@interface TrackingCoreProjection : TrackingCoreBase
- (instancetype)initWithFraction:(double)fraction distanceMeters:(double)distanceMeters latitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("init(fraction:distanceMeters:latitude:longitude:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreProjection *)doCopyFraction:(double)fraction distanceMeters:(double)distanceMeters latitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("doCopy(fraction:distanceMeters:latitude:longitude:)")));

/** Result of projecting a point onto a segment. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** Result of projecting a point onto a segment. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** Result of projecting a point onto a segment. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double distanceMeters __attribute__((swift_name("distanceMeters")));
@property (readonly) double fraction __attribute__((swift_name("fraction")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@end


/** A point on a local tangent plane, metres east / north of an origin. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("XY")))
@interface TrackingCoreXY : TrackingCoreBase
- (instancetype)initWithX:(double)x y:(double)y __attribute__((swift_name("init(x:y:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreXY *)doCopyX:(double)x y:(double)y __attribute__((swift_name("doCopy(x:y:)")));

/** A point on a local tangent plane, metres east / north of an origin. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** A point on a local tangent plane, metres east / north of an origin. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** A point on a local tangent plane, metres east / north of an origin. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double x __attribute__((swift_name("x")));
@property (readonly) double y __attribute__((swift_name("y")));
@end


/**
 * Estimates the pedalling cadence (revolutions per minute) from a phone accelerometer carried on the rider's leg
 * (trouser pocket, thigh). The leg moves once per crank revolution, so the acceleration seen by the phone is periodic
 * with the cadence; the period is found by autocorrelation.
 *
 * Pipeline, every [recomputeEveryMs]:
 *  1. The last [windowMs] of samples are averaged into uniform bins of [binMs] (a box filter, which also keeps vibration
 *     above the bin rate from aliasing); empty bins are interpolated, too many empty bins means "not enough data".
 *  2. The mean of each axis is removed (gravity and a fixed orientation), then the axis of greatest variance is found
 *     (power iteration on the 3x3 covariance) and the signal is projected on it. The phone's orientation in the pocket
 *     is unknown, so no fixed axis is assumed, and a projection (not the vector magnitude) keeps the fundamental
 *     frequency instead of doubling it.
 *  3. A signal weaker than [minAmplitude] (m/s^2, standard deviation) means no pedalling motion.
 *  4. The normalized autocorrelation is searched for peaks between [minRpm] and [maxRpm]. Among the peaks near the
 *     highest one the SMALLEST lag wins, so a peak at twice the period (a sub-harmonic) is not chosen. A best
 *     correlation below [minCorrelation] means the signal is not periodic enough to trust.
 *  5. The peak is refined by parabolic interpolation and smoothed with an exponential average.
 *
 * It answers with a negative number when it does not know, never with a guess: warming up (less than 75% of the window),
 * a stale feed, no motion, no clear period. A value is held for [holdMs] after the last good estimate.
 *
 * Limits: only meaningful with the phone on the leg (a handlebar mount sees road vibration, not the legs); coasting
 * with the legs still, or standing and pedalling out of rhythm, gives "unknown". Every number below is a STARTING
 * value chosen by reasoning, not measured on a bike: tune it from recordings.
 *
 * All times (`timeMs`, `nowMs`) must come from the SAME clock. Not thread-safe; O(window) per recompute.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PedalCadenceEstimator")))
@interface TrackingCorePedalCadenceEstimator : TrackingCoreBase
- (instancetype)initWithWindowMs:(int64_t)windowMs binMs:(int64_t)binMs minRpm:(double)minRpm maxRpm:(double)maxRpm minAmplitude:(double)minAmplitude minCorrelation:(double)minCorrelation subHarmonicRatio:(double)subHarmonicRatio smoothing:(double)smoothing holdMs:(int64_t)holdMs recomputeEveryMs:(int64_t)recomputeEveryMs __attribute__((swift_name("init(windowMs:binMs:minRpm:maxRpm:minAmplitude:minCorrelation:subHarmonicRatio:smoothing:holdMs:recomputeEveryMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCorePedalCadenceEstimatorCompanion *companion __attribute__((swift_name("companion")));

/** Feeds one reading (m/s^2, any orientation). Invalid or not-newer samples are ignored. */
- (void)pushTimeMs:(int64_t)timeMs x:(double)x y:(double)y z:(double)z __attribute__((swift_name("push(timeMs:x:y:z:)")));

/** Forgets every sample and the last estimate (a new segment, a pause). */
- (void)reset __attribute__((swift_name("reset()")));

/** The cadence in revolutions per minute at [nowMs], or a NEGATIVE number when unknown. */
- (double)rpmNowMs:(int64_t)nowMs __attribute__((swift_name("rpm(nowMs:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PedalCadenceEstimator.Companion")))
@interface TrackingCorePedalCadenceEstimatorCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCorePedalCadenceEstimatorCompanion *shared __attribute__((swift_name("shared")));

/** An estimator with the starting values (Swift cannot use Kotlin default arguments). */
- (TrackingCorePedalCadenceEstimator *)standard __attribute__((swift_name("standard()")));

/** No sample for this long: the feed stopped. */
@property (readonly) int64_t STALE_FEED_MS __attribute__((swift_name("STALE_FEED_MS")));

/** What [rpm] returns when it does not know. */
@property (readonly) double UNKNOWN __attribute__((swift_name("UNKNOWN")));
@end


/**
 * Session-relative step accounting, the same policy on both platforms.
 *
 *  - Steps of closed segments are ACCEPTED and never change again (except by
 *    [correctClosedSegment], which replaces a segment's estimate with an exact count).
 *  - The first device-counter reading of a segment is only a BASELINE: it adds
 *    nothing, so steps taken before it (or while paused) are never counted.
 *  - A counter that goes backwards (reboot, sensor reset) keeps the accepted
 *    total and becomes the new baseline.
 *  - A segment-relative count (iOS `CMPedometer` counting from a start date) is
 *    cumulative within the segment: a lower reading is ignored.
 *
 * Each `on...` returns the steps it ADDED to [total] (never negative), which is
 * what the engine needs for distance. Not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StepSession")))
@interface TrackingCoreStepSession : TrackingCoreBase

/**
 * Session-relative step accounting, the same policy on both platforms.
 *
 *  - Steps of closed segments are ACCEPTED and never change again (except by
 *    [correctClosedSegment], which replaces a segment's estimate with an exact count).
 *  - The first device-counter reading of a segment is only a BASELINE: it adds
 *    nothing, so steps taken before it (or while paused) are never counted.
 *  - A counter that goes backwards (reboot, sensor reset) keeps the accepted
 *    total and becomes the new baseline.
 *  - A segment-relative count (iOS `CMPedometer` counting from a start date) is
 *    cumulative within the segment: a lower reading is ignored.
 *
 * Each `on...` returns the steps it ADDED to [total] (never negative), which is
 * what the engine needs for distance. Not thread-safe.
 */
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));

/**
 * Session-relative step accounting, the same policy on both platforms.
 *
 *  - Steps of closed segments are ACCEPTED and never change again (except by
 *    [correctClosedSegment], which replaces a segment's estimate with an exact count).
 *  - The first device-counter reading of a segment is only a BASELINE: it adds
 *    nothing, so steps taken before it (or while paused) are never counted.
 *  - A counter that goes backwards (reboot, sensor reset) keeps the accepted
 *    total and becomes the new baseline.
 *  - A segment-relative count (iOS `CMPedometer` counting from a start date) is
 *    cumulative within the segment: a lower reading is ignored.
 *
 * Each `on...` returns the steps it ADDED to [total] (never negative), which is
 * what the engine needs for distance. Not thread-safe.
 */
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));

/**
 * Folds the open segment into the accepted total. A no-op when no segment is
 * open (finishing a session that is already paused): it must not overwrite
 * what [correctClosedSegment] needs to know about the last closed segment.
 */
- (void)closeSegment __attribute__((swift_name("closeSegment()")));

/**
 * Replaces the just-closed segment's count with [exactSteps] (iOS asks the
 * OS for the exact range at a boundary). Ignored once the next segment has
 * counted steps, or for a negative value. Returns the change to [total].
 */
- (int64_t)correctClosedSegmentExactSteps:(int64_t)exactSteps __attribute__((swift_name("correctClosedSegment(exactSteps:)")));

/** A reading of the device's cumulative counter (Android `TYPE_STEP_COUNTER`). */
- (int64_t)onCounterRaw:(int64_t)raw __attribute__((swift_name("onCounter(raw:)")));

/** A count since the segment started (iOS). A lower reading is ignored. */
- (int64_t)onSegmentCountSteps:(int64_t)steps __attribute__((swift_name("onSegmentCount(steps:)")));

/** A new segment: fresh baseline, accepted total kept. */
- (void)openSegment __attribute__((swift_name("openSegment()")));

/** New session. [initialSteps] restores a saved total (the device counter is never added to it). */
- (void)resetInitialSteps:(int64_t)initialSteps __attribute__((swift_name("reset(initialSteps:)")));

/** Accepted steps of closed segments plus the open one. */
@property (readonly) int64_t total __attribute__((swift_name("total")));
@end


/**
 * Online stay-point detector. The phone is STOPPED once it stayed within
 * [radiusMeters] of one point AND showed no sign of motion (no Doppler speed at
 * or above [stationarySpeedMps]) for at least [minDwellMs], without a hole in
 * the observations longer than [maxObservationGapMs]. Leaving the radius, or
 * moving at speed, ends the stop at once and starts a new window.
 *
 * It is a CANDIDATE signal for moving time, not the sole authority. O(1) per
 * fix; a runner passing the same place twice is not a stop.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StopDetector")))
@interface TrackingCoreStopDetector : TrackingCoreBase
- (instancetype)initWithRadiusMeters:(double)radiusMeters minDwellMs:(int64_t)minDwellMs stationarySpeedMps:(double)stationarySpeedMps maxObservationGapMs:(int64_t)maxObservationGapMs __attribute__((swift_name("init(radiusMeters:minDwellMs:stationarySpeedMps:maxObservationGapMs:)"))) __attribute__((objc_designated_initializer));
- (BOOL)pushTimeMs:(int64_t)timeMs latitude:(double)latitude longitude:(double)longitude speedMps:(TrackingCoreDouble * _Nullable)speedMps __attribute__((swift_name("push(timeMs:latitude:longitude:speedMps:)")));
- (void)reset __attribute__((swift_name("reset()")));

/** True while the current stay lasted at least [minDwellMs]. */
@property (readonly) BOOL isStopped __attribute__((swift_name("isStopped")));
@end


/**
 * Learns the user's stride length (metres per step) from stretches where GPS is
 * good, so a step count can later stand in for distance while GPS is weak.
 *
 * It accumulates steps and GPS metres of the SAME window and only produces a
 * sample once both are big enough to average out step batching (the OS reports
 * steps in lots, up to ~10 s late on Android) and GPS noise. A window with many
 * steps but almost no GPS distance (standing still, phone shaken in the hand) is
 * abandoned, and a sample outside [minStride, maxStride] is discarded: neither
 * can pollute the estimate.
 *
 * The estimate is an exponential moving average, so one odd window moves it only
 * a little. Not measured on devices: every number is a starting value.
 *
 * Not thread-safe; O(1) per call.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StrideEstimator")))
@interface TrackingCoreStrideEstimator : TrackingCoreBase
- (instancetype)initWithInitialStrideMeters:(TrackingCoreDouble * _Nullable)initialStrideMeters minSteps:(int64_t)minSteps minMeters:(double)minMeters minStride:(double)minStride maxStride:(double)maxStride alpha:(double)alpha abandonSteps:(int64_t)abandonSteps __attribute__((swift_name("init(initialStrideMeters:minSteps:minMeters:minStride:maxStride:alpha:abandonSteps:)"))) __attribute__((objc_designated_initializer));
- (void)addMetersMeters:(double)meters __attribute__((swift_name("addMeters(meters:)")));
- (void)addStepsSteps:(int64_t)steps __attribute__((swift_name("addSteps(steps:)")));

/**
 * Drops the open window: the GPS quality changed, so steps and metres no
 * longer describe the same stretch. The learned stride is kept.
 */
- (void)breakWindow __attribute__((swift_name("breakWindow()")));

/** New session: forgets what was learned and starts from the configured value. */
- (void)reset __attribute__((swift_name("reset()")));

/** How many windows taught the stride in this session. */
@property (readonly) int32_t sampleCount __attribute__((swift_name("sampleCount")));

/** Metres per step, or null until the first plausible window (or an initial value). */
@property (readonly) TrackingCoreDouble * _Nullable strideMeters __attribute__((swift_name("strideMeters")));
@end


/**
 * Picks a sampling plan from the speed, with hysteresis so it does not flap.
 * An invalid or unknown speed, or a clock that went backwards, resets the
 * standstill timer and returns the moving plan (never a sparse one). Starting
 * values to benchmark, not measured. Geofencing is deliberately not used while
 * recording: the workout needs continuous fixes.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AdaptiveSamplingPolicy")))
@interface TrackingCoreAdaptiveSamplingPolicy : TrackingCoreBase
- (instancetype)initWithBatterySaver:(BOOL)batterySaver stillAfterMs:(int64_t)stillAfterMs __attribute__((swift_name("init(batterySaver:stillAfterMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreSamplingPlan *)planSpeedMps:(TrackingCoreDouble * _Nullable)speedMps nowMs:(int64_t)nowMs __attribute__((swift_name("plan(speedMps:nowMs:)")));
- (void)reset __attribute__((swift_name("reset()")));
@end


/** What to ask the OS for. The OS may still deliver faster or slower. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SamplingPlan")))
@interface TrackingCoreSamplingPlan : TrackingCoreBase
- (instancetype)initWithIntervalMs:(int64_t)intervalMs minDistanceMeters:(double)minDistanceMeters highAccuracy:(BOOL)highAccuracy __attribute__((swift_name("init(intervalMs:minDistanceMeters:highAccuracy:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreSamplingPlan *)doCopyIntervalMs:(int64_t)intervalMs minDistanceMeters:(double)minDistanceMeters highAccuracy:(BOOL)highAccuracy __attribute__((swift_name("doCopy(intervalMs:minDistanceMeters:highAccuracy:)")));

/** What to ask the OS for. The OS may still deliver faster or slower. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** What to ask the OS for. The OS may still deliver faster or slower. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/**
 * How long without a fix means "GPS is silent": at least four intervals,
 * never below [floorMs]. A sparse plan must not be mistaken for an outage.
 */
- (int64_t)silenceAfterMsFloorMs:(int64_t)floorMs __attribute__((swift_name("silenceAfterMs(floorMs:)")));

/** What to ask the OS for. The OS may still deliver faster or slower. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL highAccuracy __attribute__((swift_name("highAccuracy")));
@property (readonly) int64_t intervalMs __attribute__((swift_name("intervalMs")));
@property (readonly) double minDistanceMeters __attribute__((swift_name("minDistanceMeters")));
@end


/**
 * OFFLINE analysis only (not part of the distance): groups points that are
 * close in SPACE. It cannot tell a continuous rest from a runner who passes the
 * same place twice; for a stop during recording use `StopDetector`.
 * O(n²): fine for a recorded trace, not for a city.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Dbscan")))
@interface TrackingCoreDbscan : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * OFFLINE analysis only (not part of the distance): groups points that are
 * close in SPACE. It cannot tell a continuous rest from a runner who passes the
 * same place twice; for a stop during recording use `StopDetector`.
 * O(n²): fine for a recorded trace, not for a city.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)dbscan __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreDbscan *shared __attribute__((swift_name("shared")));

/** Indices of the points of each cluster; noise points belong to none. */
- (NSArray<NSArray<TrackingCoreInt *> *> *)clusterPoints:(NSArray<TrackingCoreLatLon *> *)points epsilonMeters:(double)epsilonMeters minPoints:(int32_t)minPoints __attribute__((swift_name("cluster(points:epsilonMeters:minPoints:)")));
@end


/**
 * OFFLINE analysis only: splits a set of places into [k] regions. Centers start
 * evenly spread over the input order, so the result is deterministic.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KMeans")))
@interface TrackingCoreKMeans : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * OFFLINE analysis only: splits a set of places into [k] regions. Centers start
 * evenly spread over the input order, so the result is deterministic.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)kMeans __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreKMeans *shared __attribute__((swift_name("shared")));
- (NSArray<TrackingCoreLatLon *> *)centersPoints:(NSArray<TrackingCoreLatLon *> *)points k:(int32_t)k maxIterations:(int32_t)maxIterations __attribute__((swift_name("centers(points:k:maxIterations:)")));
@end


/**
 * OFFLINE Viterbi map matching (Newson and Krumm style, reduced): emission by
 * the lateral distance to the road, transition by how well the road distance
 * matches the straight distance between two samples. A sample with no road
 * within the radius, or no legal transition, splits the trace.
 *
 * Reduced: no time or heading, no confidence, no spatial index. Use a routing
 * engine (OSRM Match, Valhalla) for production; split the trace at every Pause
 * before calling this.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HmmMapMatcher")))
@interface TrackingCoreHmmMapMatcher : TrackingCoreBase
- (instancetype)initWithGraph:(TrackingCoreRoadGraph *)graph sigmaMeters:(double)sigmaMeters betaMeters:(double)betaMeters __attribute__((swift_name("init(graph:sigmaMeters:betaMeters:)"))) __attribute__((objc_designated_initializer));

/** One entry per sample: the matched road position, or null when unmatched. */
- (NSArray<id> *)matchSamples:(NSArray<TrackingCoreLatLon *> *)samples radiusMeters:(double)radiusMeters __attribute__((swift_name("match(samples:radiusMeters:)")));
@end


/** A GPS point projected on one road segment. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoadCandidate")))
@interface TrackingCoreRoadCandidate : TrackingCoreBase
- (instancetype)initWithEdge:(TrackingCoreRoadEdge *)edge fraction:(double)fraction lateralMeters:(double)lateralMeters latitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("init(edge:fraction:lateralMeters:latitude:longitude:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreRoadCandidate *)doCopyEdge:(TrackingCoreRoadEdge *)edge fraction:(double)fraction lateralMeters:(double)lateralMeters latitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("doCopy(edge:fraction:lateralMeters:latitude:longitude:)")));

/** A GPS point projected on one road segment. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** A GPS point projected on one road segment. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** A GPS point projected on one road segment. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TrackingCoreRoadEdge *edge __attribute__((swift_name("edge")));
@property (readonly) double fraction __attribute__((swift_name("fraction")));
@property (readonly) double lateralMeters __attribute__((swift_name("lateralMeters")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@end


/** A DIRECTED road segment; a two-way road needs an edge each way. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoadEdge")))
@interface TrackingCoreRoadEdge : TrackingCoreBase
- (instancetype)initWithId:(NSString *)id from:(NSString *)from to:(NSString *)to lengthMeters:(double)lengthMeters __attribute__((swift_name("init(id:from:to:lengthMeters:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreRoadEdge *)doCopyId:(NSString *)id from:(NSString *)from to:(NSString *)to lengthMeters:(double)lengthMeters __attribute__((swift_name("doCopy(id:from:to:lengthMeters:)")));

/** A DIRECTED road segment; a two-way road needs an edge each way. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** A DIRECTED road segment; a two-way road needs an edge each way. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** A DIRECTED road segment; a two-way road needs an edge each way. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *from __attribute__((swift_name("from")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) double lengthMeters __attribute__((swift_name("lengthMeters")));
@property (readonly) NSString *to __attribute__((swift_name("to")));
@end


/**
 * OFFLINE / auxiliary: a directed road graph for map matching and routing. It
 * never feeds the recorded distance (matched coordinates must not replace the
 * real ones without a reconciliation and ground-truth tests). Needs a graph with
 * real road or trail data; the app has none, so this is for server-side or
 * future use.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoadGraph")))
@interface TrackingCoreRoadGraph : TrackingCoreBase
- (instancetype)initWithNodes:(NSArray<TrackingCoreRoadNode *> *)nodes edges:(NSArray<TrackingCoreRoadEdge *> *)edges __attribute__((swift_name("init(nodes:edges:)"))) __attribute__((objc_designated_initializer));

/** Geometric matching: the nearest segments within [radiusMeters], closest first. */
- (NSArray<TrackingCoreRoadCandidate *> *)candidatesLatitude:(double)latitude longitude:(double)longitude radiusMeters:(double)radiusMeters limit:(int32_t)limit __attribute__((swift_name("candidates(latitude:longitude:radiusMeters:limit:)")));
- (TrackingCoreRoadNode * _Nullable)nodeId:(NSString *)id __attribute__((swift_name("node(id:)")));

/** Shortest path. [useAStar] false = Dijkstra; true = A* with the straight-line heuristic. */
- (TrackingCoreRoutePath * _Nullable)routeStart:(NSString *)start goal:(NSString *)goal useAStar:(BOOL)useAStar __attribute__((swift_name("route(start:goal:useAStar:)")));

/**
 * Topological matching: the road distance from [a] to [b] along connected,
 * correctly directed segments, or null when no legal path exists.
 */
- (TrackingCoreDouble * _Nullable)travelDistanceA:(TrackingCoreRoadCandidate *)a b:(TrackingCoreRoadCandidate *)b __attribute__((swift_name("travelDistance(a:b:)")));
@property (readonly) NSArray<TrackingCoreRoadEdge *> *edges __attribute__((swift_name("edges")));
@property (readonly) NSArray<TrackingCoreRoadNode *> *nodes __attribute__((swift_name("nodes")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoadNode")))
@interface TrackingCoreRoadNode : TrackingCoreBase
- (instancetype)initWithId:(NSString *)id latitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("init(id:latitude:longitude:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreRoadNode *)doCopyId:(NSString *)id latitude:(double)latitude longitude:(double)longitude __attribute__((swift_name("doCopy(id:latitude:longitude:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoutePath")))
@interface TrackingCoreRoutePath : TrackingCoreBase
- (instancetype)initWithLengthMeters:(double)lengthMeters nodes:(NSArray<NSString *> *)nodes __attribute__((swift_name("init(lengthMeters:nodes:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreRoutePath *)doCopyLengthMeters:(double)lengthMeters nodes:(NSArray<NSString *> *)nodes __attribute__((swift_name("doCopy(lengthMeters:nodes:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double lengthMeters __attribute__((swift_name("lengthMeters")));
@property (readonly) NSArray<NSString *> *nodes __attribute__((swift_name("nodes")));
@end


/** What to ask the OS for (see `AdaptiveSamplingPolicy`). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BridgePlan")))
@interface TrackingCoreBridgePlan : TrackingCoreBase
- (instancetype)initWithIntervalMs:(int64_t)intervalMs minDistanceMeters:(double)minDistanceMeters highAccuracy:(BOOL)highAccuracy silenceAfterMs:(int64_t)silenceAfterMs __attribute__((swift_name("init(intervalMs:minDistanceMeters:highAccuracy:silenceAfterMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) BOOL highAccuracy __attribute__((swift_name("highAccuracy")));
@property (readonly) int64_t intervalMs __attribute__((swift_name("intervalMs")));
@property (readonly) double minDistanceMeters __attribute__((swift_name("minDistanceMeters")));
@property (readonly) int64_t silenceAfterMs __attribute__((swift_name("silenceAfterMs")));
@end


/** A flat copy of `TrackingSnapshot`: only primitives, so Swift and Kotlin read it the same way. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BridgeSnapshot")))
@interface TrackingCoreBridgeSnapshot : TrackingCoreBase
- (instancetype)initWithState:(int32_t)state quality:(int32_t)quality totalMeters:(double)totalMeters gpsMeters:(double)gpsMeters gapBridgeMeters:(double)gapBridgeMeters pdrMeters:(double)pdrMeters pendingPdrMeters:(double)pendingPdrMeters segmentId:(int32_t)segmentId fixCount:(int32_t)fixCount speedMps:(double)speedMps lastFixAtMs:(int64_t)lastFixAtMs movingTimeMs:(int64_t)movingTimeMs isStopped:(BOOL)isStopped steps:(int64_t)steps strideMeters:(double)strideMeters activeTimeMs:(int64_t)activeTimeMs bridgedGapMs:(int64_t)bridgedGapMs uncreditedGapMs:(int64_t)uncreditedGapMs uncreditedGaps:(int32_t)uncreditedGaps ambiguousSteps:(int64_t)ambiguousSteps distanceEligibleSteps:(int64_t)distanceEligibleSteps __attribute__((swift_name("init(state:quality:totalMeters:gpsMeters:gapBridgeMeters:pdrMeters:pendingPdrMeters:segmentId:fixCount:speedMps:lastFixAtMs:movingTimeMs:isStopped:steps:strideMeters:activeTimeMs:bridgedGapMs:uncreditedGapMs:uncreditedGaps:ambiguousSteps:distanceEligibleSteps:)"))) __attribute__((objc_designated_initializer));

/** Workout time: running legs only, pauses excluded. */
@property (readonly) int64_t activeTimeMs __attribute__((swift_name("activeTimeMs")));

/** Steps in batches that straddle a GPS-quality change: kept in the total, used for no estimate. */
@property (readonly) int64_t ambiguousSteps __attribute__((swift_name("ambiguousSteps")));

/** Time of GPS gaps that were credited (bridge or estimate). */
@property (readonly) int64_t bridgedGapMs __attribute__((swift_name("bridgedGapMs")));

/** Steps that taught the stride or became a pending estimate. */
@property (readonly) int64_t distanceEligibleSteps __attribute__((swift_name("distanceEligibleSteps")));
@property (readonly) int32_t fixCount __attribute__((swift_name("fixCount")));
@property (readonly) double gapBridgeMeters __attribute__((swift_name("gapBridgeMeters")));
@property (readonly) double gpsMeters __attribute__((swift_name("gpsMeters")));
@property (readonly) BOOL isStopped __attribute__((swift_name("isStopped")));

/** Negative = none yet. */
@property (readonly) int64_t lastFixAtMs __attribute__((swift_name("lastFixAtMs")));
@property (readonly) int64_t movingTimeMs __attribute__((swift_name("movingTimeMs")));
@property (readonly) double pdrMeters __attribute__((swift_name("pdrMeters")));
@property (readonly) double pendingPdrMeters __attribute__((swift_name("pendingPdrMeters")));

/** 0 unknown, 1 good, 2 degraded, 3 unavailable, 4 recovering. */
@property (readonly) int32_t quality __attribute__((swift_name("quality")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));

/** Negative = unknown. */
@property (readonly) double speedMps __attribute__((swift_name("speedMps")));

/** 0 idle, 1 running, 2 paused, 3 finished (stable codes, see [TrackingCoreBridge]). */
@property (readonly) int32_t state __attribute__((swift_name("state")));

/** Accepted steps of the session (closed segments + the open one). */
@property (readonly) int64_t steps __attribute__((swift_name("steps")));

/** Learned or configured metres per step; negative = unknown. */
@property (readonly) double strideMeters __attribute__((swift_name("strideMeters")));
@property (readonly) double totalMeters __attribute__((swift_name("totalMeters")));

/** Time of GPS gaps and unmeasured intervals that were NOT credited. */
@property (readonly) int64_t uncreditedGapMs __attribute__((swift_name("uncreditedGapMs")));
@property (readonly) int32_t uncreditedGaps __attribute__((swift_name("uncreditedGaps")));
@end


/**
 * The one door through which Swift and Kotlin-Android reach the engine. Kotlin
 * default arguments, nullable numbers and enums are awkward from Swift, so
 * everything here is a primitive (unknown values are negative) and every
 * parameter is explicit.
 *
 * Not thread-safe: call it from one lock or one serial context. It also owns the
 * adaptive sampling policy, so the plan follows the same speed the engine sees.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrackingCoreBridge")))
@interface TrackingCoreTrackingCoreBridge : TrackingCoreBase
- (instancetype)initWithMaxAccuracyMeters:(double)maxAccuracyMeters maxFixAgeMs:(int64_t)maxFixAgeMs silenceAfterMs:(int64_t)silenceAfterMs maxSpeedMps:(double)maxSpeedMps minStepMeters:(double)minStepMeters accuracyNoiseFactor:(double)accuracyNoiseFactor stationarySpeedMps:(double)stationarySpeedMps maxBridgeMs:(int64_t)maxBridgeMs reanchorAfterRejects:(int32_t)reanchorAfterRejects rejectMock:(BOOL)rejectMock pdrEnabled:(BOOL)pdrEnabled pdrConfirmRatio:(double)pdrConfirmRatio kalman:(BOOL)kalman stopRadiusMeters:(double)stopRadiusMeters stopMinDwellMs:(int64_t)stopMinDwellMs initialStrideMeters:(double)initialStrideMeters pdrTrustedWhenCalibrated:(BOOL)pdrTrustedWhenCalibrated recoveryStepEvidenceAfterMs:(int64_t)recoveryStepEvidenceAfterMs adaptiveSampling:(BOOL)adaptiveSampling batterySaver:(BOOL)batterySaver __attribute__((swift_name("init(maxAccuracyMeters:maxFixAgeMs:silenceAfterMs:maxSpeedMps:minStepMeters:accuracyNoiseFactor:stationarySpeedMps:maxBridgeMs:reanchorAfterRejects:rejectMock:pdrEnabled:pdrConfirmRatio:kalman:stopRadiusMeters:stopMinDwellMs:initialStrideMeters:pdrTrustedWhenCalibrated:recoveryStepEvidenceAfterMs:adaptiveSampling:batterySaver:)"))) __attribute__((objc_designated_initializer));

/**
 * An exact count for the segment that was just paused or finished (iOS asks
 * the OS for the range up to the boundary). Changes the displayed total only:
 * distance is never derived from it.
 */
- (void)correctClosedSegmentExactSteps:(int64_t)exactSteps __attribute__((swift_name("correctClosedSegment(exactSteps:)")));
- (void)finishAtMs:(int64_t)atMs __attribute__((swift_name("finish(atMs:)")));

/** The process died for [gapMs] while recording: an unmeasured interval (see `GpsDistanceEngine.markInterruption`). */
- (void)markInterruptionGapMs:(int64_t)gapMs __attribute__((swift_name("markInterruption(gapMs:)")));

/**
 * Feeds one fix; returns the `FixVerdict` code. Exactly `-1.0` means unknown
 * for [horizontalAccuracy], [speed] and [speedAccuracy]; NaN, infinity or any
 * other negative value is INVALID, not unknown. [timeMs] and [nowMs] must come
 * from the SAME (monotonic) clock. [replay] skips the age and future checks.
 */
- (int32_t)onFixSessionId:(NSString *)sessionId segmentId:(int32_t)segmentId seq:(int64_t)seq timeMs:(int64_t)timeMs latitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(double)horizontalAccuracy speed:(double)speed speedAccuracy:(double)speedAccuracy isMock:(BOOL)isMock nowMs:(int64_t)nowMs replay:(BOOL)replay __attribute__((swift_name("onFix(sessionId:segmentId:seq:timeMs:latitude:longitude:horizontalAccuracy:speed:speedAccuracy:isMock:nowMs:replay:)")));

/**
 * A step count since the segment started (iOS `CMPedometer` from a start
 * date) measured up to [measuredAtMs] (the data's end date) and delivered at
 * [deliveredAtMs].
 */
- (void)onSegmentStepsSegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs segmentSteps:(int64_t)segmentSteps __attribute__((swift_name("onSegmentSteps(segmentId:measuredAtMs:deliveredAtMs:segmentSteps:)")));

/**
 * A reading of the device's CUMULATIVE step counter (Android
 * `TYPE_STEP_COUNTER`) in [segmentId]. [measuredAtMs] is the sensor's own time
 * of the reading (the time of its LAST step), [deliveredAtMs] when it reached
 * us, both on the engine's clock. The first reading of a segment is a
 * baseline; the next ones carry the interval since the previous reading,
 * which is what the engine classifies by GPS quality.
 */
- (void)onStepCounterSegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs raw:(int64_t)raw __attribute__((swift_name("onStepCounter(segmentId:measuredAtMs:deliveredAtMs:raw:)")));

/** Returns the GPS quality code. */
- (int32_t)onTickNowMs:(int64_t)nowMs __attribute__((swift_name("onTick(nowMs:)")));
- (void)pauseAtMs:(int64_t)atMs __attribute__((swift_name("pause(atMs:)")));

/** Coordinate-free timeline of the engine's decisions. */
- (NSString *)report __attribute__((swift_name("report()")));
- (void)resumeAtMs:(int64_t)atMs segmentId:(int32_t)segmentId __attribute__((swift_name("resume(atMs:segmentId:)")));

/**
 * The sampling plan for now. With adaptive sampling off it is always the same
 * fixed plan. With it on, the engine's silence limit follows the plan so a
 * sparse plan is never mistaken for an outage.
 */
- (TrackingCoreBridgePlan *)samplingPlanNowMs:(int64_t)nowMs __attribute__((swift_name("samplingPlan(nowMs:)")));

/** The step sensor works (hardware and permission): its silence becomes evidence. */
- (void)setStepSensorActiveActive:(BOOL)active __attribute__((swift_name("setStepSensorActive(active:)")));
- (TrackingCoreBridgeSnapshot *)snapshot __attribute__((swift_name("snapshot()")));

/** [initialSteps] restores a saved session total (the device counter is never added to it). */
- (void)startSessionId:(NSString *)sessionId atMs:(int64_t)atMs segmentId:(int32_t)segmentId initialSteps:(int64_t)initialSteps __attribute__((swift_name("start(sessionId:atMs:segmentId:initialSteps:)")));

/** A step estimate for [segmentId]; one of another segment is refused. */
- (void)submitPdrSegmentId:(int32_t)segmentId atMs:(int64_t)atMs meters:(double)meters __attribute__((swift_name("submitPdr(segmentId:atMs:meters:)")));
@end


/**
 * Append-only record of accepted distance. The total is the sum of its entries,
 * so it can only grow, and every metre has a source.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceLedger")))
@interface TrackingCoreDistanceLedger : TrackingCoreBase

/**
 * Append-only record of accepted distance. The total is the sum of its entries,
 * so it can only grow, and every metre has a source.
 */
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));

/**
 * Append-only record of accepted distance. The total is the sum of its entries,
 * so it can only grow, and every metre has a source.
 */
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));

/**
 * Adds [meters]. A negative or non-finite amount is a bug in the caller and
 * throws; zero is ignored. The total must stay finite.
 */
- (void)addSegmentId:(int32_t)segmentId source:(TrackingCoreDistanceSource *)source meters:(double)meters atMs:(int64_t)atMs __attribute__((swift_name("add(segmentId:source:meters:atMs:)")));
- (void)clear __attribute__((swift_name("clear()")));
- (double)metersSource:(TrackingCoreDistanceSource *)source __attribute__((swift_name("meters(source:)")));
@property (readonly) NSArray<TrackingCoreLedgerEntry *> *entries __attribute__((swift_name("entries")));
@property (readonly) double totalMeters __attribute__((swift_name("totalMeters")));
@end


/**
 * Decides what counts as distance. Pure and deterministic: time is passed in,
 * nothing is read from the platform, so a recording can be replayed fix by fix.
 *
 * Every time given to the engine (`fix.timeMs`, `nowMs`, `atMs`) must come from
 * the SAME clock. The native layers use a monotonic one, so a wall-clock jump
 * can neither reorder nor age a fix.
 *
 * Rules:
 *  - GPS is the truth. A step estimate is only ever PENDING until the GPS that
 *    returns confirms it; a phone shaken without GPS therefore adds 0 m.
 *  - Distance is measured on RAW accepted fixes. The Kalman filter (optional) is
 *    only a quality gate; it never supplies coordinates.
 *  - One source per stretch: a gap is credited once, never as a sum.
 *  - Nothing is bridged across a pause or a segment boundary, and a fix or a
 *    step estimate of another session or segment is refused.
 *  - A Doppler speed below the stationary limit means no distance.
 *  - A GPS gap is decided from the time of the last HEALTHY fix, not from the
 *    accounting anchor (which stays put on purpose while standing).
 *  - The total only grows.
 *  - Time is split like workout apps do: ACTIVE time (running legs, pauses
 *    excluded), MOVING time (speed or credited gaps) and UNCREDITED gap time
 *    (GPS gaps nothing was credited for), which is reported, never hidden.
 *  - A step batch carries the interval it was MEASURED in and is classified by
 *    the GPS quality during that interval: wholly good teaches the stride,
 *    wholly weak becomes a pending estimate, a batch straddling a quality change
 *    is counted as ambiguous and used for nothing.
 *
 * Not thread-safe: drive it from one serial context.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GpsDistanceEngine")))
@interface TrackingCoreGpsDistanceEngine : TrackingCoreBase
- (instancetype)initWithConfig:(TrackingCoreTrackingConfig *)config log:(TrackingCoreTrackingLog *)log __attribute__((swift_name("init(config:log:)"))) __attribute__((objc_designated_initializer));

/** Freezes the result. Later fixes are ignored. */
- (void)finishAtMs:(int64_t)atMs __attribute__((swift_name("finish(atMs:)")));

/**
 * The process died for [gapMs] while recording. If GPS was healthy nothing opened a gap, so the silence is
 * recorded here as an unmeasured interval; if a gap was already open, closing the leg counts it (never twice).
 */
- (void)markInterruptionGapMs:(int64_t)gapMs __attribute__((swift_name("markInterruption(gapMs:)")));

/**
 * [nowMs] is when the fix arrived, on the SAME clock as `fix.timeMs`.
 * [replay] skips the age and future checks (a fix read back from storage).
 * Never throws for data: a bad fix gets a verdict.
 */
- (TrackingCoreFixResult *)onFixFix:(TrackingCoreTrackingFix *)fix nowMs:(int64_t)nowMs replay:(BOOL)replay __attribute__((swift_name("onFix(fix:nowMs:replay:)")));

/** A batch measured and delivered at [atMs] (an instant). */
- (void)onStepsSegmentId:(int32_t)segmentId atMs:(int64_t)atMs steps:(int64_t)steps __attribute__((swift_name("onSteps(segmentId:atMs:steps:)")));

/**
 * New steps of [segmentId] measured in `[fromMs, toMs]` (a DELTA, not a
 * running total) and delivered at [deliveredAtMs]. The batch is judged by the
 * GPS quality DURING its interval, never by the quality at delivery:
 *  - wholly GPS-good: the steps teach the stride (with the GPS metres of the
 *    same window); they are not distance;
 *  - wholly weak, and a stride known: `steps * stride` becomes a PENDING
 *    estimate that the returning GPS must confirm (see [submitPdr]);
 *  - straddling a quality change: counted in `ambiguousSteps`, used for nothing.
 * A batch that ends before the leg started, another segment, or a non-running
 * engine is refused.
 */
- (void)onStepsSegmentId:(int32_t)segmentId fromMs:(int64_t)fromMs toMs:(int64_t)toMs deliveredAtMs:(int64_t)deliveredAtMs steps:(int64_t)steps __attribute__((swift_name("onSteps(segmentId:fromMs:toMs:deliveredAtMs:steps:)")));

/** Call about once per second. Detects GPS silence. */
- (TrackingCoreGpsQuality *)onTickNowMs:(int64_t)nowMs __attribute__((swift_name("onTick(nowMs:)")));

/** Closes the segment: the anchor is forgotten and a pending estimate dropped. */
- (void)pauseAtMs:(int64_t)atMs __attribute__((swift_name("pause(atMs:)")));
- (void)resumeAtMs:(int64_t)atMs segmentId:(int32_t)segmentId __attribute__((swift_name("resume(atMs:segmentId:)")));

/** The step sensor is working (hardware and permission): its silence is evidence. */
- (void)setStepSensorActiveActive:(BOOL)active __attribute__((swift_name("setStepSensorActive(active:)")));
- (void)startSessionId:(NSString *)sessionId atMs:(int64_t)atMs segmentId:(int32_t)segmentId __attribute__((swift_name("start(sessionId:atMs:segmentId:)")));

/**
 * A step-based estimate for a stretch without GPS, for [segmentId]. It is
 * refused when it belongs to another segment (a late estimate must not leak
 * into the segment that follows a resume), and held as pending only while
 * GPS is not good. It only counts if the GPS that returns confirms it.
 */
- (void)submitPdrSegmentId:(int32_t)segmentId atMs:(int64_t)atMs meters:(double)meters __attribute__((swift_name("submitPdr(segmentId:atMs:meters:)")));

/** Workout time: running legs only, up to the latest time the engine saw. */
@property (readonly) int64_t activeTimeMs __attribute__((swift_name("activeTimeMs")));
@property (readonly) TrackingCoreTrackingConfig *config __attribute__((swift_name("config")));
@property (readonly) TrackingCoreDistanceLedger *ledger __attribute__((swift_name("ledger")));
@property (readonly) TrackingCoreTrackingLog *log __attribute__((swift_name("log")));
@property (readonly) TrackingCoreGpsQuality *quality __attribute__((swift_name("quality")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));

/**
 * How long without a fix means "GPS is silent". Starts at the configured
 * value; an adaptive sampling plan may raise it so sparse fixes are not
 * mistaken for an outage.
 */
@property int64_t silenceAfterMs __attribute__((swift_name("silenceAfterMs")));
@property (readonly) TrackingCoreTrackingSnapshot *snapshot __attribute__((swift_name("snapshot")));
@property (readonly) TrackingCoreRecordingState *state __attribute__((swift_name("state")));
@property (readonly) double totalMeters __attribute__((swift_name("totalMeters")));
@end


/**
 * Bounded, coordinate-free timeline of what the engine decided. Coordinates
 * never enter it: it is meant to be copied out of a device and shared.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrackingLog")))
@interface TrackingCoreTrackingLog : TrackingCoreBase
- (instancetype)initWithCapacity:(int32_t)capacity __attribute__((swift_name("init(capacity:)"))) __attribute__((objc_designated_initializer));
- (void)clear __attribute__((swift_name("clear()")));
- (void)noteAtMs:(int64_t)atMs text:(NSString *)text __attribute__((swift_name("note(atMs:text:)")));
- (NSString *)report __attribute__((swift_name("report()")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end


/**
 * Everything the engine was configured with, as primitives. Stored in the journal
 * header so a restore replays with the SAME configuration the session ran with,
 * whatever the app passes later.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BridgeSettings")))
@interface TrackingCoreBridgeSettings : TrackingCoreBase
- (instancetype)initWithMaxAccuracyMeters:(double)maxAccuracyMeters maxFixAgeMs:(int64_t)maxFixAgeMs silenceAfterMs:(int64_t)silenceAfterMs maxSpeedMps:(double)maxSpeedMps minStepMeters:(double)minStepMeters accuracyNoiseFactor:(double)accuracyNoiseFactor stationarySpeedMps:(double)stationarySpeedMps maxBridgeMs:(int64_t)maxBridgeMs reanchorAfterRejects:(int32_t)reanchorAfterRejects rejectMock:(BOOL)rejectMock pdrEnabled:(BOOL)pdrEnabled pdrConfirmRatio:(double)pdrConfirmRatio kalman:(BOOL)kalman stopRadiusMeters:(double)stopRadiusMeters stopMinDwellMs:(int64_t)stopMinDwellMs initialStrideMeters:(double)initialStrideMeters pdrTrustedWhenCalibrated:(BOOL)pdrTrustedWhenCalibrated recoveryStepEvidenceAfterMs:(int64_t)recoveryStepEvidenceAfterMs adaptiveSampling:(BOOL)adaptiveSampling batterySaver:(BOOL)batterySaver __attribute__((swift_name("init(maxAccuracyMeters:maxFixAgeMs:silenceAfterMs:maxSpeedMps:minStepMeters:accuracyNoiseFactor:stationarySpeedMps:maxBridgeMs:reanchorAfterRejects:rejectMock:pdrEnabled:pdrConfirmRatio:kalman:stopRadiusMeters:stopMinDwellMs:initialStrideMeters:pdrTrustedWhenCalibrated:recoveryStepEvidenceAfterMs:adaptiveSampling:batterySaver:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreBridgeSettings *)doCopyMaxAccuracyMeters:(double)maxAccuracyMeters maxFixAgeMs:(int64_t)maxFixAgeMs silenceAfterMs:(int64_t)silenceAfterMs maxSpeedMps:(double)maxSpeedMps minStepMeters:(double)minStepMeters accuracyNoiseFactor:(double)accuracyNoiseFactor stationarySpeedMps:(double)stationarySpeedMps maxBridgeMs:(int64_t)maxBridgeMs reanchorAfterRejects:(int32_t)reanchorAfterRejects rejectMock:(BOOL)rejectMock pdrEnabled:(BOOL)pdrEnabled pdrConfirmRatio:(double)pdrConfirmRatio kalman:(BOOL)kalman stopRadiusMeters:(double)stopRadiusMeters stopMinDwellMs:(int64_t)stopMinDwellMs initialStrideMeters:(double)initialStrideMeters pdrTrustedWhenCalibrated:(BOOL)pdrTrustedWhenCalibrated recoveryStepEvidenceAfterMs:(int64_t)recoveryStepEvidenceAfterMs adaptiveSampling:(BOOL)adaptiveSampling batterySaver:(BOOL)batterySaver __attribute__((swift_name("doCopy(maxAccuracyMeters:maxFixAgeMs:silenceAfterMs:maxSpeedMps:minStepMeters:accuracyNoiseFactor:stationarySpeedMps:maxBridgeMs:reanchorAfterRejects:rejectMock:pdrEnabled:pdrConfirmRatio:kalman:stopRadiusMeters:stopMinDwellMs:initialStrideMeters:pdrTrustedWhenCalibrated:recoveryStepEvidenceAfterMs:adaptiveSampling:batterySaver:)")));

/**
 * Everything the engine was configured with, as primitives. Stored in the journal
 * header so a restore replays with the SAME configuration the session ran with,
 * whatever the app passes later.
 */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * Everything the engine was configured with, as primitives. Stored in the journal
 * header so a restore replays with the SAME configuration the session ran with,
 * whatever the app passes later.
 */
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (TrackingCoreTrackingCoreBridge *)toBridge __attribute__((swift_name("toBridge()")));

/**
 * Everything the engine was configured with, as primitives. Stored in the journal
 * header so a restore replays with the SAME configuration the session ran with,
 * whatever the app passes later.
 */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double accuracyNoiseFactor __attribute__((swift_name("accuracyNoiseFactor")));
@property (readonly) BOOL adaptiveSampling __attribute__((swift_name("adaptiveSampling")));
@property (readonly) BOOL batterySaver __attribute__((swift_name("batterySaver")));
@property (readonly) double initialStrideMeters __attribute__((swift_name("initialStrideMeters")));
@property (readonly) BOOL kalman __attribute__((swift_name("kalman")));
@property (readonly) double maxAccuracyMeters __attribute__((swift_name("maxAccuracyMeters")));
@property (readonly) int64_t maxBridgeMs __attribute__((swift_name("maxBridgeMs")));
@property (readonly) int64_t maxFixAgeMs __attribute__((swift_name("maxFixAgeMs")));
@property (readonly) double maxSpeedMps __attribute__((swift_name("maxSpeedMps")));
@property (readonly) double minStepMeters __attribute__((swift_name("minStepMeters")));
@property (readonly) double pdrConfirmRatio __attribute__((swift_name("pdrConfirmRatio")));
@property (readonly) BOOL pdrEnabled __attribute__((swift_name("pdrEnabled")));
@property (readonly) BOOL pdrTrustedWhenCalibrated __attribute__((swift_name("pdrTrustedWhenCalibrated")));
@property (readonly) int32_t reanchorAfterRejects __attribute__((swift_name("reanchorAfterRejects")));
@property (readonly) int64_t recoveryStepEvidenceAfterMs __attribute__((swift_name("recoveryStepEvidenceAfterMs")));
@property (readonly) BOOL rejectMock __attribute__((swift_name("rejectMock")));
@property (readonly) int64_t silenceAfterMs __attribute__((swift_name("silenceAfterMs")));
@property (readonly) double stationarySpeedMps __attribute__((swift_name("stationarySpeedMps")));
@property (readonly) int64_t stopMinDwellMs __attribute__((swift_name("stopMinDwellMs")));
@property (readonly) double stopRadiusMeters __attribute__((swift_name("stopRadiusMeters")));
@end


/**
 * One record per line: `CRC32|TYPE|field|field...`. The CRC covers everything
 * after it, so a half-written or flipped line is detected, never guessed at.
 * Numbers use Kotlin's shortest round-trip text; text fields are escaped.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalCodec")))
@interface TrackingCoreJournalCodec : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * One record per line: `CRC32|TYPE|field|field...`. The CRC covers everything
 * after it, so a half-written or flipped line is detected, never guessed at.
 * Numbers use Kotlin's shortest round-trip text; text fields are escaped.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)journalCodec __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreJournalCodec *shared __attribute__((swift_name("shared")));

/** Null when the line is damaged (bad CRC, wrong field count, unknown type, malformed number). */
- (TrackingCoreJournalRecord * _Nullable)decodeLine:(NSString *)line __attribute__((swift_name("decode(line:)")));
- (NSString *)encodeR:(TrackingCoreJournalRecord *)r __attribute__((swift_name("encode(r:)")));

/**
 * Reads every line. The first damaged LAST line is a normal crash artefact
 * ([JournalStatus.TRUNCATED_TAIL]); a damaged line followed by more lines is
 * real corruption ([JournalStatus.CORRUPT]). Either way only the intact prefix
 * is returned, and the first record must be a header of a known version.
 */
- (TrackingCoreJournalContents *)readLines:(NSArray<NSString *> *)lines __attribute__((swift_name("read(lines:)")));

/**
 * The RULES of the engine (`GpsDistanceEngine` and what it uses). Bump it whenever a
 * change can alter a result. A journal replays with the code that reads it, so a journal
 * written by another engine version is replayed anyway but flagged: restore is
 * "rebuild what was shown" only while the version matches.
 */
@property (readonly) int32_t ENGINE_VERSION __attribute__((swift_name("ENGINE_VERSION")));

/** The oldest format this code still reads (version 1 has no `Z`/`Y` records). */
@property (readonly) int32_t MIN_VERSION __attribute__((swift_name("MIN_VERSION")));

/**
 * The journal FORMAT written by this code. Bump it whenever a record is added or changed in a way an
 * older reader would misread: an older reader refuses a newer version (UNSUPPORTED_VERSION) instead of
 * treating a valid new record as damage. Version 2 added `Z` (finalized) and `Y` (segment settled); version 3 added `Q` (recovered after a process death) and the optional calendar time of a `T` tick.
 */
@property (readonly) int32_t VERSION __attribute__((swift_name("VERSION")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalContents")))
@interface TrackingCoreJournalContents : TrackingCoreBase
- (instancetype)initWithRecords:(NSArray<TrackingCoreJournalRecord *> *)records status:(TrackingCoreJournalStatus *)status damagedLine:(int32_t)damagedLine __attribute__((swift_name("init(records:status:damagedLine:)"))) __attribute__((objc_designated_initializer));

/** Zero-based index of the first damaged line, or -1. */
@property (readonly) int32_t damagedLine __attribute__((swift_name("damagedLine")));
@property (readonly) NSArray<TrackingCoreJournalRecord *> *records __attribute__((swift_name("records")));
@property (readonly) TrackingCoreJournalStatus *status __attribute__((swift_name("status")));
@end


/** One line of the journal. Times named `...AtMs` are on the engine's monotonic clock. */
__attribute__((swift_name("JournalRecord")))
@interface TrackingCoreJournalRecord : TrackingCoreBase
@end


/**
 * Written once, after `Finish`, when the step total was settled: [stepsFinal] is true when the
 * platform's exact count was obtained (or there is no step sensor), false when the total is
 * only the live count. A journal that ends at `Finish` without it was cut before settling:
 * its steps are provisional.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Finalized")))
@interface TrackingCoreJournalRecordFinalized : TrackingCoreJournalRecord
- (instancetype)initWithStepsFinal:(BOOL)stepsFinal __attribute__((swift_name("init(stepsFinal:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordFinalized *)doCopyStepsFinal:(BOOL)stepsFinal __attribute__((swift_name("doCopy(stepsFinal:)")));

/**
 * Written once, after `Finish`, when the step total was settled: [stepsFinal] is true when the
 * platform's exact count was obtained (or there is no step sensor), false when the total is
 * only the live count. A journal that ends at `Finish` without it was cut before settling:
 * its steps are provisional.
 */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * Written once, after `Finish`, when the step total was settled: [stepsFinal] is true when the
 * platform's exact count was obtained (or there is no step sensor), false when the total is
 * only the live count. A journal that ends at `Finish` without it was cut before settling:
 * its steps are provisional.
 */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/**
 * Written once, after `Finish`, when the step total was settled: [stepsFinal] is true when the
 * platform's exact count was obtained (or there is no step sensor), false when the total is
 * only the live count. A journal that ends at `Finish` without it was cut before settling:
 * its steps are provisional.
 */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL stepsFinal __attribute__((swift_name("stepsFinal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Finish")))
@interface TrackingCoreJournalRecordFinish : TrackingCoreJournalRecord
- (instancetype)initWithAtMs:(int64_t)atMs __attribute__((swift_name("init(atMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordFinish *)doCopyAtMs:(int64_t)atMs __attribute__((swift_name("doCopy(atMs:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@end


/** A raw fix as the platform produced it, with the time it arrived ([nowMs]). Negative = unknown. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Fix")))
@interface TrackingCoreJournalRecordFix : TrackingCoreJournalRecord
- (instancetype)initWithSessionId:(NSString *)sessionId segmentId:(int32_t)segmentId seq:(int64_t)seq timeMs:(int64_t)timeMs wallTimeMs:(int64_t)wallTimeMs latitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(double)horizontalAccuracy speed:(double)speed speedAccuracy:(double)speedAccuracy course:(double)course altitude:(double)altitude verticalAccuracy:(double)verticalAccuracy provider:(NSString *)provider isMock:(BOOL)isMock nowMs:(int64_t)nowMs __attribute__((swift_name("init(sessionId:segmentId:seq:timeMs:wallTimeMs:latitude:longitude:horizontalAccuracy:speed:speedAccuracy:course:altitude:verticalAccuracy:provider:isMock:nowMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordFix *)doCopySessionId:(NSString *)sessionId segmentId:(int32_t)segmentId seq:(int64_t)seq timeMs:(int64_t)timeMs wallTimeMs:(int64_t)wallTimeMs latitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(double)horizontalAccuracy speed:(double)speed speedAccuracy:(double)speedAccuracy course:(double)course altitude:(double)altitude verticalAccuracy:(double)verticalAccuracy provider:(NSString *)provider isMock:(BOOL)isMock nowMs:(int64_t)nowMs __attribute__((swift_name("doCopy(sessionId:segmentId:seq:timeMs:wallTimeMs:latitude:longitude:horizontalAccuracy:speed:speedAccuracy:course:altitude:verticalAccuracy:provider:isMock:nowMs:)")));

/** A raw fix as the platform produced it, with the time it arrived ([nowMs]). Negative = unknown. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** A raw fix as the platform produced it, with the time it arrived ([nowMs]). Negative = unknown. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** A raw fix as the platform produced it, with the time it arrived ([nowMs]). Negative = unknown. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double altitude __attribute__((swift_name("altitude")));
@property (readonly) double course __attribute__((swift_name("course")));
@property (readonly) double horizontalAccuracy __attribute__((swift_name("horizontalAccuracy")));
@property (readonly) BOOL isMock __attribute__((swift_name("isMock")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@property (readonly) int64_t nowMs __attribute__((swift_name("nowMs")));
@property (readonly) NSString *provider __attribute__((swift_name("provider")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@property (readonly) double speed __attribute__((swift_name("speed")));
@property (readonly) double speedAccuracy __attribute__((swift_name("speedAccuracy")));
@property (readonly) int64_t timeMs __attribute__((swift_name("timeMs")));
@property (readonly) double verticalAccuracy __attribute__((swift_name("verticalAccuracy")));
@property (readonly) int64_t wallTimeMs __attribute__((swift_name("wallTimeMs")));
@end


/** The first record: configuration and the session's identity. [extras] is for the host (notification text, intervals...). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Header")))
@interface TrackingCoreJournalRecordHeader : TrackingCoreJournalRecord
- (instancetype)initWithVersion:(int32_t)version engineVersion:(int32_t)engineVersion sessionId:(NSString *)sessionId atMs:(int64_t)atMs wallAtMs:(int64_t)wallAtMs segmentId:(int32_t)segmentId initialSteps:(int64_t)initialSteps settings:(TrackingCoreBridgeSettings *)settings extras:(NSDictionary<NSString *, NSString *> *)extras __attribute__((swift_name("init(version:engineVersion:sessionId:atMs:wallAtMs:segmentId:initialSteps:settings:extras:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordHeader *)doCopyVersion:(int32_t)version engineVersion:(int32_t)engineVersion sessionId:(NSString *)sessionId atMs:(int64_t)atMs wallAtMs:(int64_t)wallAtMs segmentId:(int32_t)segmentId initialSteps:(int64_t)initialSteps settings:(TrackingCoreBridgeSettings *)settings extras:(NSDictionary<NSString *, NSString *> *)extras __attribute__((swift_name("doCopy(version:engineVersion:sessionId:atMs:wallAtMs:segmentId:initialSteps:settings:extras:)")));

/** The first record: configuration and the session's identity. [extras] is for the host (notification text, intervals...). */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** The first record: configuration and the session's identity. [extras] is for the host (notification text, intervals...). */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** The first record: configuration and the session's identity. [extras] is for the host (notification text, intervals...). */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));

/** The rules that produced the recorded result (`JournalCodec.ENGINE_VERSION`). A replay with other rules may differ. */
@property (readonly) int32_t engineVersion __attribute__((swift_name("engineVersion")));
@property (readonly) NSDictionary<NSString *, NSString *> *extras __attribute__((swift_name("extras")));
@property (readonly) int64_t initialSteps __attribute__((swift_name("initialSteps")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@property (readonly) TrackingCoreBridgeSettings *settings __attribute__((swift_name("settings")));
@property (readonly) int32_t version __attribute__((swift_name("version")));
@property (readonly) int64_t wallAtMs __attribute__((swift_name("wallAtMs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Pause")))
@interface TrackingCoreJournalRecordPause : TrackingCoreJournalRecord
- (instancetype)initWithAtMs:(int64_t)atMs __attribute__((swift_name("init(atMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordPause *)doCopyAtMs:(int64_t)atMs __attribute__((swift_name("doCopy(atMs:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Pdr")))
@interface TrackingCoreJournalRecordPdr : TrackingCoreJournalRecord
- (instancetype)initWithSegmentId:(int32_t)segmentId atMs:(int64_t)atMs meters:(double)meters __attribute__((swift_name("init(segmentId:atMs:meters:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordPdr *)doCopySegmentId:(int32_t)segmentId atMs:(int64_t)atMs meters:(double)meters __attribute__((swift_name("doCopy(segmentId:atMs:meters:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) double meters __attribute__((swift_name("meters")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@end


/**
 * The process died and came back. ONE record that applies a recovery completely, so a crash after it is written
 * loses nothing: the engine's clock moves to [targetMs] (calendar time [gapMs] elapsed while nothing ran), every
 * later live input is shifted by [offsetMs], and when the session was recording its leg is closed there and a new
 * segment opens. Replay applies exactly the same steps. [anomaly]: the calendar clock went BACKWARDS.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Recovered")))
@interface TrackingCoreJournalRecordRecovered : TrackingCoreJournalRecord
- (instancetype)initWithTargetMs:(int64_t)targetMs offsetMs:(int64_t)offsetMs gapMs:(int64_t)gapMs wasRunning:(BOOL)wasRunning nextSegmentId:(int32_t)nextSegmentId anomaly:(BOOL)anomaly wallMs:(int64_t)wallMs __attribute__((swift_name("init(targetMs:offsetMs:gapMs:wasRunning:nextSegmentId:anomaly:wallMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordRecovered *)doCopyTargetMs:(int64_t)targetMs offsetMs:(int64_t)offsetMs gapMs:(int64_t)gapMs wasRunning:(BOOL)wasRunning nextSegmentId:(int32_t)nextSegmentId anomaly:(BOOL)anomaly wallMs:(int64_t)wallMs __attribute__((swift_name("doCopy(targetMs:offsetMs:gapMs:wasRunning:nextSegmentId:anomaly:wallMs:)")));

/**
 * The process died and came back. ONE record that applies a recovery completely, so a crash after it is written
 * loses nothing: the engine's clock moves to [targetMs] (calendar time [gapMs] elapsed while nothing ran), every
 * later live input is shifted by [offsetMs], and when the session was recording its leg is closed there and a new
 * segment opens. Replay applies exactly the same steps. [anomaly]: the calendar clock went BACKWARDS.
 */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * The process died and came back. ONE record that applies a recovery completely, so a crash after it is written
 * loses nothing: the engine's clock moves to [targetMs] (calendar time [gapMs] elapsed while nothing ran), every
 * later live input is shifted by [offsetMs], and when the session was recording its leg is closed there and a new
 * segment opens. Replay applies exactly the same steps. [anomaly]: the calendar clock went BACKWARDS.
 */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/**
 * The process died and came back. ONE record that applies a recovery completely, so a crash after it is written
 * loses nothing: the engine's clock moves to [targetMs] (calendar time [gapMs] elapsed while nothing ran), every
 * later live input is shifted by [offsetMs], and when the session was recording its leg is closed there and a new
 * segment opens. Replay applies exactly the same steps. [anomaly]: the calendar clock went BACKWARDS.
 */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL anomaly __attribute__((swift_name("anomaly")));
@property (readonly) int64_t gapMs __attribute__((swift_name("gapMs")));
@property (readonly) int32_t nextSegmentId __attribute__((swift_name("nextSegmentId")));
@property (readonly) int64_t offsetMs __attribute__((swift_name("offsetMs")));

/** The engine time the clock moves to. */
@property (readonly) int64_t targetMs __attribute__((swift_name("targetMs")));
@property (readonly) int64_t wallMs __attribute__((swift_name("wallMs")));

/** The session was RECORDING: the leg is closed at [targetMs] and a new one opens in [nextSegmentId]. */
@property (readonly) BOOL wasRunning __attribute__((swift_name("wasRunning")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Resume")))
@interface TrackingCoreJournalRecordResume : TrackingCoreJournalRecord
- (instancetype)initWithAtMs:(int64_t)atMs segmentId:(int32_t)segmentId __attribute__((swift_name("init(atMs:segmentId:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordResume *)doCopyAtMs:(int64_t)atMs segmentId:(int32_t)segmentId __attribute__((swift_name("doCopy(atMs:segmentId:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@end


/**
 * The platform's exact step count for the CLOSED segment [segmentId] was obtained ([exact] true) or
 * could not be ([exact] false). A session's steps are exact only when EVERY segment in which the
 * step sensor was active is settled exact; one failed or lost close keeps it provisional.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.SegmentSettled")))
@interface TrackingCoreJournalRecordSegmentSettled : TrackingCoreJournalRecord
- (instancetype)initWithSegmentId:(int32_t)segmentId exact:(BOOL)exact __attribute__((swift_name("init(segmentId:exact:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordSegmentSettled *)doCopySegmentId:(int32_t)segmentId exact:(BOOL)exact __attribute__((swift_name("doCopy(segmentId:exact:)")));

/**
 * The platform's exact step count for the CLOSED segment [segmentId] was obtained ([exact] true) or
 * could not be ([exact] false). A session's steps are exact only when EVERY segment in which the
 * step sensor was active is settled exact; one failed or lost close keeps it provisional.
 */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * The platform's exact step count for the CLOSED segment [segmentId] was obtained ([exact] true) or
 * could not be ([exact] false). A session's steps are exact only when EVERY segment in which the
 * step sensor was active is settled exact; one failed or lost close keeps it provisional.
 */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/**
 * The platform's exact step count for the CLOSED segment [segmentId] was obtained ([exact] true) or
 * could not be ([exact] false). A session's steps are exact only when EVERY segment in which the
 * step sensor was active is settled exact; one failed or lost close keeps it provisional.
 */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL exact __attribute__((swift_name("exact")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.SegmentSteps")))
@interface TrackingCoreJournalRecordSegmentSteps : TrackingCoreJournalRecord
- (instancetype)initWithSegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs count:(int64_t)count __attribute__((swift_name("init(segmentId:measuredAtMs:deliveredAtMs:count:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordSegmentSteps *)doCopySegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs count:(int64_t)count __attribute__((swift_name("doCopy(segmentId:measuredAtMs:deliveredAtMs:count:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t count __attribute__((swift_name("count")));
@property (readonly) int64_t deliveredAtMs __attribute__((swift_name("deliveredAtMs")));
@property (readonly) int64_t measuredAtMs __attribute__((swift_name("measuredAtMs")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.StepCounter")))
@interface TrackingCoreJournalRecordStepCounter : TrackingCoreJournalRecord
- (instancetype)initWithSegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs raw:(int64_t)raw __attribute__((swift_name("init(segmentId:measuredAtMs:deliveredAtMs:raw:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordStepCounter *)doCopySegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs raw:(int64_t)raw __attribute__((swift_name("doCopy(segmentId:measuredAtMs:deliveredAtMs:raw:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t deliveredAtMs __attribute__((swift_name("deliveredAtMs")));
@property (readonly) int64_t measuredAtMs __attribute__((swift_name("measuredAtMs")));
@property (readonly) int64_t raw __attribute__((swift_name("raw")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.StepSensor")))
@interface TrackingCoreJournalRecordStepSensor : TrackingCoreJournalRecord
- (instancetype)initWithActive:(BOOL)active __attribute__((swift_name("init(active:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordStepSensor *)doCopyActive:(BOOL)active __attribute__((swift_name("doCopy(active:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL active __attribute__((swift_name("active")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.StepsCorrection")))
@interface TrackingCoreJournalRecordStepsCorrection : TrackingCoreJournalRecord
- (instancetype)initWithExactSteps:(int64_t)exactSteps __attribute__((swift_name("init(exactSteps:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordStepsCorrection *)doCopyExactSteps:(int64_t)exactSteps __attribute__((swift_name("doCopy(exactSteps:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t exactSteps __attribute__((swift_name("exactSteps")));
@end


/**
 * A 1 Hz tick. [wallMs] is the CALENDAR time at the tick (-1 when the host did not give one): it is the
 * reference a process-death recovery measures the dead interval against.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalRecord.Tick")))
@interface TrackingCoreJournalRecordTick : TrackingCoreJournalRecord
- (instancetype)initWithAtMs:(int64_t)atMs wallMs:(int64_t)wallMs __attribute__((swift_name("init(atMs:wallMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreJournalRecordTick *)doCopyAtMs:(int64_t)atMs wallMs:(int64_t)wallMs __attribute__((swift_name("doCopy(atMs:wallMs:)")));

/**
 * A 1 Hz tick. [wallMs] is the CALENDAR time at the tick (-1 when the host did not give one): it is the
 * reference a process-death recovery measures the dead interval against.
 */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * A 1 Hz tick. [wallMs] is the CALENDAR time at the tick (-1 when the host did not give one): it is the
 * reference a process-death recovery measures the dead interval against.
 */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/**
 * A 1 Hz tick. [wallMs] is the CALENDAR time at the tick (-1 when the host did not give one): it is the
 * reference a process-death recovery measures the dead interval against.
 */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) int64_t wallMs __attribute__((swift_name("wallMs")));
@end


/**
 * Where the journal goes. The host implements it with ONE serial writer: [append] must not block or
 * reorder, and [flush] must return only when every appended line is durable. It returns `true` ONLY when
 * that is so: a write or sync failure, or a barrier that timed out, is `false` and stays `false` (the host
 * keeps the failure sticky), so a lost line can never be reported as saved.
 */
__attribute__((swift_name("JournalSink")))
@protocol TrackingCoreJournalSink
@required
- (void)appendLine:(NSString *)line __attribute__((swift_name("append(line:)")));
- (BOOL)flush __attribute__((swift_name("flush()")));
@end


/** How reading a journal ended. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("JournalStatus")))
@interface TrackingCoreJournalStatus : TrackingCoreKotlinEnum<TrackingCoreJournalStatus *>
+ (instancetype)alloc __attribute__((unavailable));

/** How reading a journal ended. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreJournalStatus *ok __attribute__((swift_name("ok")));
@property (class, readonly) TrackingCoreJournalStatus *truncatedTail __attribute__((swift_name("truncatedTail")));
@property (class, readonly) TrackingCoreJournalStatus *corrupt __attribute__((swift_name("corrupt")));
@property (class, readonly) TrackingCoreJournalStatus *unsupportedVersion __attribute__((swift_name("unsupportedVersion")));
@property (class, readonly) TrackingCoreJournalStatus *empty __attribute__((swift_name("empty")));
+ (TrackingCoreKotlinArray<TrackingCoreJournalStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreJournalStatus *> *entries __attribute__((swift_name("entries")));
@end


/** What [SessionRecorder.recoverAfterProcessDeath] did. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecoveryResult")))
@interface TrackingCoreRecoveryResult : TrackingCoreBase
- (instancetype)initWithRecovered:(BOOL)recovered gapMs:(int64_t)gapMs clockAnomaly:(BOOL)clockAnomaly gapTooLong:(BOOL)gapTooLong segmentId:(int32_t)segmentId __attribute__((swift_name("init(recovered:gapMs:clockAnomaly:gapTooLong:segmentId:)"))) __attribute__((objc_designated_initializer));

/** The calendar clock went backwards: the gap could not be measured and counts as 0. */
@property (readonly) BOOL clockAnomaly __attribute__((swift_name("clockAnomaly")));

/** Calendar time that passed while nothing ran (>= 0). */
@property (readonly) int64_t gapMs __attribute__((swift_name("gapMs")));

/** The gap exceeded the limit: the session was parked as PAUSED at the last event instead. */
@property (readonly) BOOL gapTooLong __attribute__((swift_name("gapTooLong")));

/** The dead interval was added to the session's clock (and the recording continues in a NEW segment). */
@property (readonly) BOOL recovered __attribute__((swift_name("recovered")));

/** The segment the session is in after recovery. */
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@end


/**
 * What a restore must do to a journal BEFORE anything is appended to it (see [SessionRecorder.plan]).
 * [lines] is the trusted, replayable prefix (migrated header included): rewrite the file with it when
 * [needsRewrite], keep a `.corrupt` copy when [keepBackup], and only then open the writer and restore.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RepairPlan")))
@interface TrackingCoreRepairPlan : TrackingCoreBase
- (instancetype)initWithLines:(NSArray<NSString *> *)lines status:(TrackingCoreJournalStatus *)status damagedLine:(int32_t)damagedLine migrated:(BOOL)migrated usable:(BOOL)usable __attribute__((swift_name("init(lines:status:damagedLine:migrated:usable:)"))) __attribute__((objc_designated_initializer));

/** Zero-based index of the first record that was dropped, or -1. */
@property (readonly) int32_t damagedLine __attribute__((swift_name("damagedLine")));

/** Damage in the middle, or a migration, drops or changes data: keep the original next to the new file. */
@property (readonly) BOOL keepBackup __attribute__((swift_name("keepBackup")));

/** The lines to keep: every one is CRC-valid AND applies in the engine. Empty when [usable] is false. */
@property (readonly) NSArray<NSString *> *lines __attribute__((swift_name("lines")));

/** The header was written by an older format and is rewritten as the current one (new records need it). */
@property (readonly) BOOL migrated __attribute__((swift_name("migrated")));

/** The file on disk must be replaced by [lines] before the writer is opened. */
@property (readonly) BOOL needsRewrite __attribute__((swift_name("needsRewrite")));

/** The verdict of the whole check, codec AND replay (a CRC-valid but impossible record is `CORRUPT`). */
@property (readonly) TrackingCoreJournalStatus *status __attribute__((swift_name("status")));
@property (readonly) BOOL usable __attribute__((swift_name("usable")));
@end


/** What a restore found. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RestoreResult")))
@interface TrackingCoreRestoreResult : TrackingCoreBase
- (instancetype)initWithRecorder:(TrackingCoreSessionRecorder * _Nullable)recorder status:(TrackingCoreJournalStatus *)status damagedLine:(int32_t)damagedLine sessionId:(NSString *)sessionId segmentId:(int32_t)segmentId nextSeq:(int64_t)nextSeq fixCount:(int32_t)fixCount lastFixWallMs:(int64_t)lastFixWallMs extras:(NSDictionary<NSString *, NSString *> *)extras engineVersion:(int32_t)engineVersion engineChanged:(BOOL)engineChanged finished:(BOOL)finished stepsFinal:(BOOL)stepsFinal wasRunning:(BOOL)wasRunning lastEventMs:(int64_t)lastEventMs __attribute__((swift_name("init(recorder:status:damagedLine:sessionId:segmentId:nextSeq:fixCount:lastFixWallMs:extras:engineVersion:engineChanged:finished:stepsFinal:wasRunning:lastEventMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int32_t damagedLine __attribute__((swift_name("damagedLine")));

/** True when [engineVersion] differs from this code's: the replay may not equal what was shown live. */
@property (readonly) BOOL engineChanged __attribute__((swift_name("engineChanged")));

/** The engine rules the journal was recorded with. */
@property (readonly) int32_t engineVersion __attribute__((swift_name("engineVersion")));
@property (readonly) NSDictionary<NSString *, NSString *> *extras __attribute__((swift_name("extras")));

/** The journal ended with `Finish`: the session is over and read-only (it is NOT paused). */
@property (readonly) BOOL finished __attribute__((swift_name("finished")));
@property (readonly) int32_t fixCount __attribute__((swift_name("fixCount")));

/** Engine time of the last journaled event. */
@property (readonly) int64_t lastEventMs __attribute__((swift_name("lastEventMs")));

/** Wall-clock time of the last restored fix, or -1. */
@property (readonly) int64_t lastFixWallMs __attribute__((swift_name("lastFixWallMs")));

/** The next seq to give a fix. */
@property (readonly) int64_t nextSeq __attribute__((swift_name("nextSeq")));
@property (readonly) TrackingCoreSessionRecorder * _Nullable recorder __attribute__((swift_name("recorder")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@property (readonly) TrackingCoreJournalStatus *status __attribute__((swift_name("status")));

/** Only meaningful when [finished]: the step total was settled (see `JournalRecord.Finalized`). */
@property (readonly) BOOL stepsFinal __attribute__((swift_name("stepsFinal")));

/** The journal ended while RECORDING (the process died, it was not paused or finished). */
@property (readonly) BOOL wasRunning __attribute__((swift_name("wasRunning")));
@end


/**
 * The engine plus its journal, in ONE place, so Android, iOS and a watch record and restore identically. Every
 * input is written to the journal BEFORE it is applied (write-ahead), and the engine is a pure function of
 * those inputs, so replaying the journal reproduces the live result exactly: the distance, the pending
 * estimates, the stride, the step totals, the gaps and the times (EVERY tick is an input: the active time of a
 * running leg depends on it).
 *
 * An input that is invalid in the current state (a pause while not recording, a resume that does not open a new
 * segment...) is NOT journaled: a journal only ever holds inputs the engine accepts, so it can always be
 * replayed. No public method throws: a refused input sets [lastFailure] instead, because a Kotlin exception
 * would crash an iOS app.
 *
 * Not thread-safe: call it from one serial context.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SessionRecorder")))
@interface TrackingCoreSessionRecorder : TrackingCoreBase
@property (class, readonly, getter=companion) TrackingCoreSessionRecorderCompanion *companion __attribute__((swift_name("companion")));

/** True when every segment in which the step sensor was active has an exact count (vacuously true with none). */
- (BOOL)allStepsExact __attribute__((swift_name("allStepsExact()")));
- (void)correctClosedSegmentExactSteps:(int64_t)exactSteps __attribute__((swift_name("correctClosedSegment(exactSteps:)")));

/**
 * Time from the start to the finish, PAUSES INCLUDED: it keeps running until [finish]. [nowMs] is the host's
 * monotonic clock; it is shifted onto the engine's time line like every other live input.
 */
- (int64_t)elapsedTimeMsNowMs:(int64_t)nowMs __attribute__((swift_name("elapsedTimeMs(nowMs:)")));
- (void)finishAtMs:(int64_t)atMs __attribute__((swift_name("finish(atMs:)")));

/** Barrier: true only when everything appended so far is DURABLE. Call before reading, clearing or reporting a final result. */
- (BOOL)flush __attribute__((swift_name("flush()")));

/**
 * The CALENDAR time of the latest accepted fix, taken from that fix at ingest (so it never moves when the user
 * changes the system clock) and rebuilt from the journal on restore; -1 when there is none.
 */
- (int64_t)lastAcceptedFixWallMs __attribute__((swift_name("lastAcceptedFixWallMs()")));

/**
 * Settles a finished session: [stepsFinal] says whether the step total is exact or only the live count.
 * Journaled, so a restore of a finished session reports the same finality as the live result. Call once,
 * after [finish] and after any [correctClosedSegment].
 */
- (void)markFinalizedStepsFinal:(BOOL)stepsFinal __attribute__((swift_name("markFinalized(stepsFinal:)")));

/**
 * The exact step count of the CLOSED [segmentId] was obtained ([exact] true) or could not be. Journaled per
 * segment: the session's steps are exact ([allStepsExact]) only when every segment with an active sensor is.
 */
- (void)markSegmentSettledSegmentId:(int32_t)segmentId exact:(BOOL)exact __attribute__((swift_name("markSegmentSettled(segmentId:exact:)")));

/** Returns the `FixVerdict` code. Exactly `-1.0` is unknown for the accuracies, speed and course. */
- (int32_t)onFixSessionId:(NSString *)sessionId segmentId:(int32_t)segmentId seq:(int64_t)seq timeMs:(int64_t)timeMs wallTimeMs:(int64_t)wallTimeMs latitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(double)horizontalAccuracy speed:(double)speed speedAccuracy:(double)speedAccuracy course:(double)course altitude:(double)altitude verticalAccuracy:(double)verticalAccuracy provider:(NSString *)provider isMock:(BOOL)isMock nowMs:(int64_t)nowMs __attribute__((swift_name("onFix(sessionId:segmentId:seq:timeMs:wallTimeMs:latitude:longitude:horizontalAccuracy:speed:speedAccuracy:course:altitude:verticalAccuracy:provider:isMock:nowMs:)")));
- (void)onSegmentStepsSegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs count:(int64_t)count __attribute__((swift_name("onSegmentSteps(segmentId:measuredAtMs:deliveredAtMs:count:)")));
- (void)onStepCounterSegmentId:(int32_t)segmentId measuredAtMs:(int64_t)measuredAtMs deliveredAtMs:(int64_t)deliveredAtMs raw:(int64_t)raw __attribute__((swift_name("onStepCounter(segmentId:measuredAtMs:deliveredAtMs:raw:)")));

/**
 * A 1 Hz tick. EVERY tick is journaled: it moves the running leg's active time and detects silence, so a
 * restore that did not see it would lose time that was shown. Returns the quality code.
 */
- (int32_t)onTickNowMs:(int64_t)nowMs __attribute__((swift_name("onTick(nowMs:)")));

/** As [onTick], with the CALENDAR time of the tick (journaled: it is how a process-death recovery measures the gap). */
- (int32_t)onTickNowMs:(int64_t)nowMs wallMs:(int64_t)wallMs __attribute__((swift_name("onTick(nowMs:wallMs:)")));
- (void)pauseAtMs:(int64_t)atMs __attribute__((swift_name("pause(atMs:)")));

/**
 * Continues a session whose process died (restored with `pauseIfRunning = false`). The calendar time that passed
 * since the last journaled moment is the DEAD INTERVAL: it is added to the session's clock, so the elapsed time
 * and (when the session was recording) the active time include it. What the person did in it is unknown, so no
 * distance is invented: the interval is closed as a GPS gap (reported in `uncreditedGapMs`) and a recording
 * continues in a NEW segment, which is never joined to the old one.
 *
 *  * a FINISHED or idle session is untouched;
 *  * a PAUSED session keeps its active time (only the elapsed time grows) and stays paused;
 *  * when the calendar clock went backwards the gap counts as 0 and [RecoveryResult.clockAnomaly] is set;
 *  * a gap above [maxGapMs] (> 0) is NOT credited: the session is parked PAUSED at the last event, as a plain
 *    restore does ([RecoveryResult.gapTooLong]).
 *
 * [nowMonoMs] / [nowWallMs] are the host's CURRENT clocks. The result is journaled as absolute records, so
 * recovering twice at the same moment adds nothing the second time. Call it once per restore.
 */
- (TrackingCoreRecoveryResult *)recoverAfterProcessDeathNowMonoMs:(int64_t)nowMonoMs nowWallMs:(int64_t)nowWallMs maxGapMs:(int64_t)maxGapMs __attribute__((swift_name("recoverAfterProcessDeath(nowMonoMs:nowWallMs:maxGapMs:)")));
- (NSString *)report __attribute__((swift_name("report()")));
- (void)resumeAtMs:(int64_t)atMs segmentId:(int32_t)segmentId __attribute__((swift_name("resume(atMs:segmentId:)")));
- (TrackingCoreBridgePlan *)samplingPlanNowMs:(int64_t)nowMs __attribute__((swift_name("samplingPlan(nowMs:)")));
- (void)setStepSensorActiveActive:(BOOL)active __attribute__((swift_name("setStepSensorActive(active:)")));
- (TrackingCoreBridgeSnapshot *)snapshot __attribute__((swift_name("snapshot()")));
- (void)submitPdrSegmentId:(int32_t)segmentId atMs:(int64_t)atMs meters:(double)meters __attribute__((swift_name("submitPdr(segmentId:atMs:meters:)")));

/** The calendar clock went backwards across a recovery at least once. */
@property (readonly) BOOL clockAnomaly __attribute__((swift_name("clockAnomaly")));

/** Why the latest input was refused, or null. Sticky until the next refusal; never thrown. */
@property (readonly) NSString * _Nullable lastFailure __attribute__((swift_name("lastFailure")));

/** The sampling plan after the latest fix (adaptive sampling only), or null. */
@property (readonly) TrackingCoreBridgePlan * _Nullable lastPlan __attribute__((swift_name("lastPlan")));

/** Calendar time that passed while the process was dead, summed over every recovery. */
@property (readonly) int64_t recoveredGapMs __attribute__((swift_name("recoveredGapMs")));

/** True once the step total of a FINISHED session was settled (journaled by [markFinalized]). */
@property (readonly) BOOL stepsFinal __attribute__((swift_name("stepsFinal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SessionRecorder.Companion")))
@interface TrackingCoreSessionRecorderCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreSessionRecorderCompanion *shared __attribute__((swift_name("shared")));

/** The raw fixes of a journal, oldest first (for drawing or exporting the route). */
- (NSArray<TrackingCoreJournalRecordFix *> *)fixesLines:(NSArray<NSString *> *)lines __attribute__((swift_name("fixes(lines:)")));

/**
 * Checks a journal BEFORE it is restored or appended to: runs the replay on a sink that writes nothing and
 * keeps the longest prefix that is both intact (CRC) and applicable (the engine accepts every record).
 * The status is the WORST of the codec's and the replay's, so a CRC-valid record that cannot be applied
 * (for example a resume that reuses a segment) is `CORRUPT` here, and nothing is ever appended after it.
 * An older header version is migrated to the current one, because records of the current format must
 * never follow an older header (an old reader would take them for damage instead of refusing the file).
 * A FINISHED journal is read-only and is not migrated.
 */
- (TrackingCoreRepairPlan *)planLines:(NSArray<NSString *> *)lines __attribute__((swift_name("plan(lines:)")));

/**
 * REPROCESS: replays the journal's inputs through the CURRENT engine, optionally with other [settings] than
 * the ones it was recorded with, and returns the result without touching any file. Unlike [restore] the
 * result may differ from what was shown live; use it to recompute after a rule change, never to resume.
 */
- (TrackingCoreBridgeSnapshot * _Nullable)reprocessLines:(NSArray<NSString *> *)lines settings:(TrackingCoreBridgeSettings * _Nullable)settings __attribute__((swift_name("reprocess(lines:settings:)")));

/**
 * Rebuilds a session from its journal lines by replaying every record with the configuration stored in
 * the header. A session that was running comes back PAUSED: a `Pause` is appended at the time of the LAST
 * journaled event, not at "now", so the time the process was dead is never counted as workout time, and a
 * reboot (the monotonic clock restarts) cannot make the leg's duration negative. `resume` continues in a
 * new segment, so nothing measured on the old clock is ever joined to the new one.
 *
 * Replay STOPS at the first record that cannot be applied (valid CRC but impossible content): everything
 * after it is NOT applied, the status becomes `CORRUPT` and `damagedLine` points at it. [recorder] is null
 * when nothing usable was found. Restore REBUILDS what was shown; to compute it again with other settings
 * use [reprocess].
 */
- (TrackingCoreRestoreResult *)restoreSink:(id<TrackingCoreJournalSink>)sink lines:(NSArray<NSString *> *)lines __attribute__((swift_name("restore(sink:lines:)")));

/**
 * As [restore]. With [pauseIfRunning] false a session that was RECORDING when the process died is left
 * recording (`RestoreResult.wasRunning`), so the host can call [recoverAfterProcessDeath] to credit the dead
 * interval and continue; the default pauses it at the last event, which never counts the dead interval.
 */
- (TrackingCoreRestoreResult *)restoreSink:(id<TrackingCoreJournalSink>)sink lines:(NSArray<NSString *> *)lines pauseIfRunning:(BOOL)pauseIfRunning __attribute__((swift_name("restore(sink:lines:pauseIfRunning:)")));

/**
 * Starts a new session: writes the header (configuration, identity and the host's [extras]) and starts the
 * engine. Throws on invalid settings; the platform layers use [tryStart], which never throws.
 */
- (TrackingCoreSessionRecorder *)startSink:(id<TrackingCoreJournalSink>)sink settings:(TrackingCoreBridgeSettings *)settings sessionId:(NSString *)sessionId atMs:(int64_t)atMs wallAtMs:(int64_t)wallAtMs segmentId:(int32_t)segmentId initialSteps:(int64_t)initialSteps extras:(NSDictionary<NSString *, NSString *> *)extras __attribute__((swift_name("start(sink:settings:sessionId:atMs:wallAtMs:segmentId:initialSteps:extras:)")));

/** [start] without a throw: invalid settings or ids come back as [StartResult.error] and nothing is written. */
- (TrackingCoreStartResult *)tryStartSink:(id<TrackingCoreJournalSink>)sink settings:(TrackingCoreBridgeSettings *)settings sessionId:(NSString *)sessionId atMs:(int64_t)atMs wallAtMs:(int64_t)wallAtMs segmentId:(int32_t)segmentId initialSteps:(int64_t)initialSteps extras:(NSDictionary<NSString *, NSString *> *)extras __attribute__((swift_name("tryStart(sink:settings:sessionId:atMs:wallAtMs:segmentId:initialSteps:extras:)")));
@end


/** A start that cannot throw across the platform boundary (Kotlin exceptions are not catchable from Swift). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StartResult")))
@interface TrackingCoreStartResult : TrackingCoreBase
- (instancetype)initWithRecorder:(TrackingCoreSessionRecorder * _Nullable)recorder error:(NSString * _Nullable)error __attribute__((swift_name("init(recorder:error:)"))) __attribute__((objc_designated_initializer));
@property (readonly) NSString * _Nullable error __attribute__((swift_name("error")));
@property (readonly) TrackingCoreSessionRecorder * _Nullable recorder __attribute__((swift_name("recorder")));
@end


/** Where a metre of the total came from. One source per stretch of time. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DistanceSource")))
@interface TrackingCoreDistanceSource : TrackingCoreKotlinEnum<TrackingCoreDistanceSource *>
+ (instancetype)alloc __attribute__((unavailable));

/** Where a metre of the total came from. One source per stretch of time. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreDistanceSource *gps __attribute__((swift_name("gps")));
@property (class, readonly) TrackingCoreDistanceSource *gapBridge __attribute__((swift_name("gapBridge")));
@property (class, readonly) TrackingCoreDistanceSource *pdr __attribute__((swift_name("pdr")));
+ (TrackingCoreKotlinArray<TrackingCoreDistanceSource *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreDistanceSource *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FixResult")))
@interface TrackingCoreFixResult : TrackingCoreBase
- (instancetype)initWithVerdict:(TrackingCoreFixVerdict *)verdict addedMeters:(double)addedMeters source:(TrackingCoreDistanceSource * _Nullable)source __attribute__((swift_name("init(verdict:addedMeters:source:)"))) __attribute__((objc_designated_initializer));
@property (readonly) double addedMeters __attribute__((swift_name("addedMeters")));
@property (readonly) TrackingCoreDistanceSource * _Nullable source __attribute__((swift_name("source")));
@property (readonly) TrackingCoreFixVerdict *verdict __attribute__((swift_name("verdict")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FixVerdict")))
@interface TrackingCoreFixVerdict : TrackingCoreKotlinEnum<TrackingCoreFixVerdict *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreFixVerdict *anchor __attribute__((swift_name("anchor")));
@property (class, readonly) TrackingCoreFixVerdict *accepted __attribute__((swift_name("accepted")));
@property (class, readonly) TrackingCoreFixVerdict *recovered __attribute__((swift_name("recovered")));
@property (class, readonly) TrackingCoreFixVerdict *noise __attribute__((swift_name("noise")));
@property (class, readonly) TrackingCoreFixVerdict *stationary __attribute__((swift_name("stationary")));
@property (class, readonly) TrackingCoreFixVerdict *jump __attribute__((swift_name("jump")));
@property (class, readonly) TrackingCoreFixVerdict *outlier __attribute__((swift_name("outlier")));
@property (class, readonly) TrackingCoreFixVerdict *lowAccuracy __attribute__((swift_name("lowAccuracy")));
@property (class, readonly) TrackingCoreFixVerdict *stale __attribute__((swift_name("stale")));
@property (class, readonly) TrackingCoreFixVerdict *duplicate __attribute__((swift_name("duplicate")));
@property (class, readonly) TrackingCoreFixVerdict *wrongSegment __attribute__((swift_name("wrongSegment")));
@property (class, readonly) TrackingCoreFixVerdict *mock __attribute__((swift_name("mock")));
@property (class, readonly) TrackingCoreFixVerdict *notRunning __attribute__((swift_name("notRunning")));
@property (class, readonly) TrackingCoreFixVerdict *wrongSession __attribute__((swift_name("wrongSession")));
@property (class, readonly) TrackingCoreFixVerdict *invalid __attribute__((swift_name("invalid")));
@property (class, readonly) TrackingCoreFixVerdict *future __attribute__((swift_name("future")));
@property (class, readonly) TrackingCoreFixVerdict *reanchored __attribute__((swift_name("reanchored")));
+ (TrackingCoreKotlinArray<TrackingCoreFixVerdict *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreFixVerdict *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GpsQuality")))
@interface TrackingCoreGpsQuality : TrackingCoreKotlinEnum<TrackingCoreGpsQuality *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreGpsQuality *unknown __attribute__((swift_name("unknown")));
@property (class, readonly) TrackingCoreGpsQuality *good __attribute__((swift_name("good")));
@property (class, readonly) TrackingCoreGpsQuality *degraded __attribute__((swift_name("degraded")));
@property (class, readonly) TrackingCoreGpsQuality *unavailable __attribute__((swift_name("unavailable")));
@property (class, readonly) TrackingCoreGpsQuality *recovering __attribute__((swift_name("recovering")));
+ (TrackingCoreKotlinArray<TrackingCoreGpsQuality *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreGpsQuality *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LedgerEntry")))
@interface TrackingCoreLedgerEntry : TrackingCoreBase
- (instancetype)initWithSegmentId:(int32_t)segmentId source:(TrackingCoreDistanceSource *)source meters:(double)meters atMs:(int64_t)atMs __attribute__((swift_name("init(segmentId:source:meters:atMs:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreLedgerEntry *)doCopySegmentId:(int32_t)segmentId source:(TrackingCoreDistanceSource *)source meters:(double)meters atMs:(int64_t)atMs __attribute__((swift_name("doCopy(segmentId:source:meters:atMs:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t atMs __attribute__((swift_name("atMs")));
@property (readonly) double meters __attribute__((swift_name("meters")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@property (readonly) TrackingCoreDistanceSource *source __attribute__((swift_name("source")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PdrPolicy")))
@interface TrackingCorePdrPolicy : TrackingCoreKotlinEnum<TrackingCorePdrPolicy *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCorePdrPolicy *off __attribute__((swift_name("off")));
@property (class, readonly) TrackingCorePdrPolicy *confirmedByGps __attribute__((swift_name("confirmedByGps")));
@property (class, readonly) TrackingCorePdrPolicy *trustedWhenCalibrated __attribute__((swift_name("trustedWhenCalibrated")));
+ (TrackingCoreKotlinArray<TrackingCorePdrPolicy *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCorePdrPolicy *> *entries __attribute__((swift_name("entries")));
@end


/** The recording lifecycle. Not the same thing as GPS quality or movement. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingState")))
@interface TrackingCoreRecordingState : TrackingCoreKotlinEnum<TrackingCoreRecordingState *>
+ (instancetype)alloc __attribute__((unavailable));

/** The recording lifecycle. Not the same thing as GPS quality or movement. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreRecordingState *idle __attribute__((swift_name("idle")));
@property (class, readonly) TrackingCoreRecordingState *running __attribute__((swift_name("running")));
@property (class, readonly) TrackingCoreRecordingState *paused __attribute__((swift_name("paused")));
@property (class, readonly) TrackingCoreRecordingState *finished __attribute__((swift_name("finished")));
+ (TrackingCoreKotlinArray<TrackingCoreRecordingState *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreRecordingState *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Smoothing")))
@interface TrackingCoreSmoothing : TrackingCoreKotlinEnum<TrackingCoreSmoothing *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreSmoothing *off __attribute__((swift_name("off")));
@property (class, readonly) TrackingCoreSmoothing *kalman __attribute__((swift_name("kalman")));
+ (TrackingCoreKotlinArray<TrackingCoreSmoothing *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreSmoothing *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Sport")))
@interface TrackingCoreSport : TrackingCoreKotlinEnum<TrackingCoreSport *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) TrackingCoreSport *running __attribute__((swift_name("running")));
@property (class, readonly) TrackingCoreSport *walking __attribute__((swift_name("walking")));
@property (class, readonly) TrackingCoreSport *cycling __attribute__((swift_name("cycling")));
@property (class, readonly) TrackingCoreSport *other __attribute__((swift_name("other")));
+ (TrackingCoreKotlinArray<TrackingCoreSport *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<TrackingCoreSport *> *entries __attribute__((swift_name("entries")));
@end


/**
 * Every number is a STARTING VALUE chosen by reasoning, not measured on
 * devices. Tune from real recordings, never by feel.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrackingConfig")))
@interface TrackingCoreTrackingConfig : TrackingCoreBase
- (instancetype)initWithMaxAccuracyMeters:(double)maxAccuracyMeters maxFixAgeMs:(int64_t)maxFixAgeMs silenceAfterMs:(int64_t)silenceAfterMs maxSpeedMps:(double)maxSpeedMps minStepMeters:(double)minStepMeters accuracyNoiseFactor:(double)accuracyNoiseFactor stationarySpeedMps:(double)stationarySpeedMps maxBridgeMs:(int64_t)maxBridgeMs reanchorAfterRejects:(int32_t)reanchorAfterRejects rejectMock:(BOOL)rejectMock pdrPolicy:(TrackingCorePdrPolicy *)pdrPolicy pdrConfirmRatio:(double)pdrConfirmRatio smoothing:(TrackingCoreSmoothing *)smoothing stopRadiusMeters:(double)stopRadiusMeters stopMinDwellMs:(int64_t)stopMinDwellMs initialStrideMeters:(TrackingCoreDouble * _Nullable)initialStrideMeters recoveryStepEvidenceAfterMs:(int64_t)recoveryStepEvidenceAfterMs __attribute__((swift_name("init(maxAccuracyMeters:maxFixAgeMs:silenceAfterMs:maxSpeedMps:minStepMeters:accuracyNoiseFactor:stationarySpeedMps:maxBridgeMs:reanchorAfterRejects:rejectMock:pdrPolicy:pdrConfirmRatio:smoothing:stopRadiusMeters:stopMinDwellMs:initialStrideMeters:recoveryStepEvidenceAfterMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) TrackingCoreTrackingConfigCompanion *companion __attribute__((swift_name("companion")));
- (TrackingCoreTrackingConfig *)doCopyMaxAccuracyMeters:(double)maxAccuracyMeters maxFixAgeMs:(int64_t)maxFixAgeMs silenceAfterMs:(int64_t)silenceAfterMs maxSpeedMps:(double)maxSpeedMps minStepMeters:(double)minStepMeters accuracyNoiseFactor:(double)accuracyNoiseFactor stationarySpeedMps:(double)stationarySpeedMps maxBridgeMs:(int64_t)maxBridgeMs reanchorAfterRejects:(int32_t)reanchorAfterRejects rejectMock:(BOOL)rejectMock pdrPolicy:(TrackingCorePdrPolicy *)pdrPolicy pdrConfirmRatio:(double)pdrConfirmRatio smoothing:(TrackingCoreSmoothing *)smoothing stopRadiusMeters:(double)stopRadiusMeters stopMinDwellMs:(int64_t)stopMinDwellMs initialStrideMeters:(TrackingCoreDouble * _Nullable)initialStrideMeters recoveryStepEvidenceAfterMs:(int64_t)recoveryStepEvidenceAfterMs __attribute__((swift_name("doCopy(maxAccuracyMeters:maxFixAgeMs:silenceAfterMs:maxSpeedMps:minStepMeters:accuracyNoiseFactor:stationarySpeedMps:maxBridgeMs:reanchorAfterRejects:rejectMock:pdrPolicy:pdrConfirmRatio:smoothing:stopRadiusMeters:stopMinDwellMs:initialStrideMeters:recoveryStepEvidenceAfterMs:)")));

/**
 * Every number is a STARTING VALUE chosen by reasoning, not measured on
 * devices. Tune from real recordings, never by feel.
 */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/**
 * Every number is a STARTING VALUE chosen by reasoning, not measured on
 * devices. Tune from real recordings, never by feel.
 */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/**
 * Every number is a STARTING VALUE chosen by reasoning, not measured on
 * devices. Tune from real recordings, never by feel.
 */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) double accuracyNoiseFactor __attribute__((swift_name("accuracyNoiseFactor")));

/**
 * Stride (metres per step) to start from, e.g. the one learned in the user's
 * last recording. null = none: a step count is not turned into a distance
 * estimate until GPS has taught the engine a stride in this session.
 */
@property (readonly) TrackingCoreDouble * _Nullable initialStrideMeters __attribute__((swift_name("initialStrideMeters")));
@property (readonly) double maxAccuracyMeters __attribute__((swift_name("maxAccuracyMeters")));
@property (readonly) int64_t maxBridgeMs __attribute__((swift_name("maxBridgeMs")));
@property (readonly) int64_t maxFixAgeMs __attribute__((swift_name("maxFixAgeMs")));
@property (readonly) double maxSpeedMps __attribute__((swift_name("maxSpeedMps")));
@property (readonly) double minStepMeters __attribute__((swift_name("minStepMeters")));
@property (readonly) double pdrConfirmRatio __attribute__((swift_name("pdrConfirmRatio")));
@property (readonly) TrackingCorePdrPolicy *pdrPolicy __attribute__((swift_name("pdrPolicy")));
@property (readonly) int32_t reanchorAfterRejects __attribute__((swift_name("reanchorAfterRejects")));

/**
 * With a working step sensor and a pedestrian policy, a GPS gap at least this
 * long in which the sensor measured NO steps is credited 0 m (the person was
 * standing). Shorter gaps are not judged: Android may deliver steps ~10 s
 * late. Zero or negative disables the rule.
 */
@property (readonly) int64_t recoveryStepEvidenceAfterMs __attribute__((swift_name("recoveryStepEvidenceAfterMs")));
@property (readonly) BOOL rejectMock __attribute__((swift_name("rejectMock")));
@property (readonly) int64_t silenceAfterMs __attribute__((swift_name("silenceAfterMs")));
@property (readonly) TrackingCoreSmoothing *smoothing __attribute__((swift_name("smoothing")));
@property (readonly) double stationarySpeedMps __attribute__((swift_name("stationarySpeedMps")));
@property (readonly) int64_t stopMinDwellMs __attribute__((swift_name("stopMinDwellMs")));

/** Stay-point detector used for moving time. */
@property (readonly) double stopRadiusMeters __attribute__((swift_name("stopRadiusMeters")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrackingConfig.Companion")))
@interface TrackingCoreTrackingConfigCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreTrackingConfigCompanion *shared __attribute__((swift_name("shared")));
- (TrackingCoreTrackingConfig *)forSportSport:(TrackingCoreSport *)sport __attribute__((swift_name("forSport(sport:)")));
@end


/** One raw location reading. `null` = the platform did not know the value. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrackingFix")))
@interface TrackingCoreTrackingFix : TrackingCoreBase
- (instancetype)initWithSessionId:(NSString *)sessionId segmentId:(int32_t)segmentId seq:(int64_t)seq timeMs:(int64_t)timeMs latitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(TrackingCoreDouble * _Nullable)horizontalAccuracy speed:(TrackingCoreDouble * _Nullable)speed speedAccuracy:(TrackingCoreDouble * _Nullable)speedAccuracy course:(TrackingCoreDouble * _Nullable)course altitude:(TrackingCoreDouble * _Nullable)altitude verticalAccuracy:(TrackingCoreDouble * _Nullable)verticalAccuracy provider:(NSString *)provider isMock:(BOOL)isMock __attribute__((swift_name("init(sessionId:segmentId:seq:timeMs:latitude:longitude:horizontalAccuracy:speed:speedAccuracy:course:altitude:verticalAccuracy:provider:isMock:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreTrackingFix *)doCopySessionId:(NSString *)sessionId segmentId:(int32_t)segmentId seq:(int64_t)seq timeMs:(int64_t)timeMs latitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(TrackingCoreDouble * _Nullable)horizontalAccuracy speed:(TrackingCoreDouble * _Nullable)speed speedAccuracy:(TrackingCoreDouble * _Nullable)speedAccuracy course:(TrackingCoreDouble * _Nullable)course altitude:(TrackingCoreDouble * _Nullable)altitude verticalAccuracy:(TrackingCoreDouble * _Nullable)verticalAccuracy provider:(NSString *)provider isMock:(BOOL)isMock __attribute__((swift_name("doCopy(sessionId:segmentId:seq:timeMs:latitude:longitude:horizontalAccuracy:speed:speedAccuracy:course:altitude:verticalAccuracy:provider:isMock:)")));

/** One raw location reading. `null` = the platform did not know the value. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** One raw location reading. `null` = the platform did not know the value. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** One raw location reading. `null` = the platform did not know the value. */
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) TrackingCoreDouble * _Nullable altitude __attribute__((swift_name("altitude")));
@property (readonly) TrackingCoreDouble * _Nullable course __attribute__((swift_name("course")));
@property (readonly) TrackingCoreDouble * _Nullable horizontalAccuracy __attribute__((swift_name("horizontalAccuracy")));
@property (readonly) BOOL isMock __attribute__((swift_name("isMock")));
@property (readonly) double latitude __attribute__((swift_name("latitude")));
@property (readonly) double longitude __attribute__((swift_name("longitude")));
@property (readonly) NSString *provider __attribute__((swift_name("provider")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@property (readonly) int64_t seq __attribute__((swift_name("seq")));
@property (readonly) NSString *sessionId __attribute__((swift_name("sessionId")));
@property (readonly) TrackingCoreDouble * _Nullable speed __attribute__((swift_name("speed")));
@property (readonly) TrackingCoreDouble * _Nullable speedAccuracy __attribute__((swift_name("speedAccuracy")));

/** When the position was measured, epoch ms. */
@property (readonly) int64_t timeMs __attribute__((swift_name("timeMs")));
@property (readonly) TrackingCoreDouble * _Nullable verticalAccuracy __attribute__((swift_name("verticalAccuracy")));
@end


/** What the app shows. Immutable. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrackingSnapshot")))
@interface TrackingCoreTrackingSnapshot : TrackingCoreBase
- (instancetype)initWithSessionId:(NSString * _Nullable)sessionId state:(TrackingCoreRecordingState *)state quality:(TrackingCoreGpsQuality *)quality totalMeters:(double)totalMeters gpsMeters:(double)gpsMeters gapBridgeMeters:(double)gapBridgeMeters pdrMeters:(double)pdrMeters pendingPdrMeters:(double)pendingPdrMeters segmentId:(int32_t)segmentId fixCount:(int32_t)fixCount speedMps:(TrackingCoreDouble * _Nullable)speedMps lastFixAtMs:(TrackingCoreLong * _Nullable)lastFixAtMs movingTimeMs:(int64_t)movingTimeMs isStopped:(BOOL)isStopped strideMeters:(TrackingCoreDouble * _Nullable)strideMeters activeTimeMs:(int64_t)activeTimeMs bridgedGapMs:(int64_t)bridgedGapMs uncreditedGapMs:(int64_t)uncreditedGapMs uncreditedGaps:(int32_t)uncreditedGaps ambiguousSteps:(int64_t)ambiguousSteps distanceEligibleSteps:(int64_t)distanceEligibleSteps __attribute__((swift_name("init(sessionId:state:quality:totalMeters:gpsMeters:gapBridgeMeters:pdrMeters:pendingPdrMeters:segmentId:fixCount:speedMps:lastFixAtMs:movingTimeMs:isStopped:strideMeters:activeTimeMs:bridgedGapMs:uncreditedGapMs:uncreditedGaps:ambiguousSteps:distanceEligibleSteps:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreTrackingSnapshot *)doCopySessionId:(NSString * _Nullable)sessionId state:(TrackingCoreRecordingState *)state quality:(TrackingCoreGpsQuality *)quality totalMeters:(double)totalMeters gpsMeters:(double)gpsMeters gapBridgeMeters:(double)gapBridgeMeters pdrMeters:(double)pdrMeters pendingPdrMeters:(double)pendingPdrMeters segmentId:(int32_t)segmentId fixCount:(int32_t)fixCount speedMps:(TrackingCoreDouble * _Nullable)speedMps lastFixAtMs:(TrackingCoreLong * _Nullable)lastFixAtMs movingTimeMs:(int64_t)movingTimeMs isStopped:(BOOL)isStopped strideMeters:(TrackingCoreDouble * _Nullable)strideMeters activeTimeMs:(int64_t)activeTimeMs bridgedGapMs:(int64_t)bridgedGapMs uncreditedGapMs:(int64_t)uncreditedGapMs uncreditedGaps:(int32_t)uncreditedGaps ambiguousSteps:(int64_t)ambiguousSteps distanceEligibleSteps:(int64_t)distanceEligibleSteps __attribute__((swift_name("doCopy(sessionId:state:quality:totalMeters:gpsMeters:gapBridgeMeters:pdrMeters:pendingPdrMeters:segmentId:fixCount:speedMps:lastFixAtMs:movingTimeMs:isStopped:strideMeters:activeTimeMs:bridgedGapMs:uncreditedGapMs:uncreditedGaps:ambiguousSteps:distanceEligibleSteps:)")));

/** What the app shows. Immutable. */
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));

/** What the app shows. Immutable. */
- (NSUInteger)hash __attribute__((swift_name("hash()")));

/** What the app shows. Immutable. */
- (NSString *)description __attribute__((swift_name("description()")));

/** Workout time: the running legs only, pauses excluded. */
@property (readonly) int64_t activeTimeMs __attribute__((swift_name("activeTimeMs")));

/** Steps measured in a batch that straddles a GPS-quality change: kept in the total, used for no estimate. */
@property (readonly) int64_t ambiguousSteps __attribute__((swift_name("ambiguousSteps")));

/** GPS gaps that were credited (bridge or estimate): their time. */
@property (readonly) int64_t bridgedGapMs __attribute__((swift_name("bridgedGapMs")));

/** Steps that taught the stride or became a pending estimate. */
@property (readonly) int64_t distanceEligibleSteps __attribute__((swift_name("distanceEligibleSteps")));
@property (readonly) int32_t fixCount __attribute__((swift_name("fixCount")));
@property (readonly) double gapBridgeMeters __attribute__((swift_name("gapBridgeMeters")));
@property (readonly) double gpsMeters __attribute__((swift_name("gpsMeters")));
@property (readonly) BOOL isStopped __attribute__((swift_name("isStopped")));
@property (readonly) TrackingCoreLong * _Nullable lastFixAtMs __attribute__((swift_name("lastFixAtMs")));
@property (readonly) int64_t movingTimeMs __attribute__((swift_name("movingTimeMs")));
@property (readonly) double pdrMeters __attribute__((swift_name("pdrMeters")));

/** Step estimates waiting for GPS to confirm them: NOT part of [totalMeters]. */
@property (readonly) double pendingPdrMeters __attribute__((swift_name("pendingPdrMeters")));
@property (readonly) TrackingCoreGpsQuality *quality __attribute__((swift_name("quality")));
@property (readonly) int32_t segmentId __attribute__((swift_name("segmentId")));
@property (readonly) NSString * _Nullable sessionId __attribute__((swift_name("sessionId")));
@property (readonly) TrackingCoreDouble * _Nullable speedMps __attribute__((swift_name("speedMps")));
@property (readonly) TrackingCoreRecordingState *state __attribute__((swift_name("state")));

/** Learned (or configured) metres per step; null while unknown. */
@property (readonly) TrackingCoreDouble * _Nullable strideMeters __attribute__((swift_name("strideMeters")));

/** Accepted distance. Never decreases while recording. */
@property (readonly) double totalMeters __attribute__((swift_name("totalMeters")));

/** GPS gaps and unmeasured intervals that were NOT credited: their time. */
@property (readonly) int64_t uncreditedGapMs __attribute__((swift_name("uncreditedGapMs")));
@property (readonly) int32_t uncreditedGaps __attribute__((swift_name("uncreditedGaps")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface TrackingCoreKotlinEnumCompanion : TrackingCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) TrackingCoreKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface TrackingCoreKotlinArray<T> : TrackingCoreBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(TrackingCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<TrackingCoreKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinByteArray")))
@interface TrackingCoreKotlinByteArray : TrackingCoreBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(TrackingCoreByte *(^)(TrackingCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (int8_t)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (TrackingCoreKotlinByteIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(int8_t)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinIntArray")))
@interface TrackingCoreKotlinIntArray : TrackingCoreBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(TrackingCoreInt *(^)(TrackingCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (int32_t)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (TrackingCoreKotlinIntIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(int32_t)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinPair")))
@interface TrackingCoreKotlinPair<__covariant A, __covariant B> : TrackingCoreBase
- (instancetype)initWithFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("init(first:second:)"))) __attribute__((objc_designated_initializer));
- (TrackingCoreKotlinPair<A, B> *)doCopyFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("doCopy(first:second:)")));
- (BOOL)equalsOther:(id _Nullable)other __attribute__((swift_name("equals(other:)")));
- (int32_t)hashCode __attribute__((swift_name("hashCode()")));
- (NSString *)toString __attribute__((swift_name("toString()")));
@property (readonly) A _Nullable first __attribute__((swift_name("first")));
@property (readonly) B _Nullable second __attribute__((swift_name("second")));
@end

__attribute__((swift_name("KotlinIterator")))
@protocol TrackingCoreKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

__attribute__((swift_name("KotlinByteIterator")))
@interface TrackingCoreKotlinByteIterator : TrackingCoreBase <TrackingCoreKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (TrackingCoreByte *)next __attribute__((swift_name("next()")));
- (int8_t)nextByte __attribute__((swift_name("nextByte()")));
@end

__attribute__((swift_name("KotlinIntIterator")))
@interface TrackingCoreKotlinIntIterator : TrackingCoreBase <TrackingCoreKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (TrackingCoreInt *)next __attribute__((swift_name("next()")));
- (int32_t)nextInt __attribute__((swift_name("nextInt()")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
