#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class SensorCoreBatteryAdapter, SensorCoreCapability, SensorCoreCounterRate, SensorCoreCounterRateCompanion, SensorCoreCyclingPowerAdapter, SensorCoreCyclingSpeedCadenceAdapter, SensorCoreDeviceDetails, SensorCoreDeviceInfoField, SensorCoreDeviceInformationAdapter, SensorCoreDeviceMetricValue, SensorCoreFitnessMachineAdapter, SensorCoreGatt, SensorCoreHeartRateAdapter, SensorCoreHeartRateMeasurement, SensorCoreHeartRateParser, SensorCoreKotlinArray<T>, SensorCoreKotlinByteArray, SensorCoreKotlinByteIterator, SensorCoreKotlinEnum<E>, SensorCoreKotlinEnumCompanion, SensorCoreMeasurementKind, SensorCoreMetricResolverConfig, SensorCoreMetricResolverConfigCompanion, SensorCoreMetricType, SensorCoreProtocolRegistry, SensorCoreResolvedMetric, SensorCoreRunningSpeedCadenceAdapter, SensorCoreRunningSpeedCadenceMeasurement, SensorCoreRunningSpeedCadenceParser, SensorCoreSensorHub, SensorCoreSensorHubCompanion, SensorCoreSensorReading, SensorCoreSourcePolicy, SensorCoreSourceState;

@protocol SensorCoreBleProtocolAdapter, SensorCoreKotlinComparable, SensorCoreKotlinIterator, SensorCoreSensorEvent;

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
@interface SensorCoreBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface SensorCoreBase (SensorCoreBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface SensorCoreMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface SensorCoreMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorSensorCoreKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface SensorCoreNumber : NSNumber
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
@interface SensorCoreByte : SensorCoreNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface SensorCoreUByte : SensorCoreNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface SensorCoreShort : SensorCoreNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface SensorCoreUShort : SensorCoreNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface SensorCoreInt : SensorCoreNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface SensorCoreUInt : SensorCoreNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface SensorCoreLong : SensorCoreNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface SensorCoreULong : SensorCoreNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface SensorCoreFloat : SensorCoreNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface SensorCoreDouble : SensorCoreNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface SensorCoreBoolean : SensorCoreNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end

__attribute__((swift_name("KotlinComparable")))
@protocol SensorCoreKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface SensorCoreKotlinEnum<E> : SensorCoreBase <SensorCoreKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SensorCoreKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end


/** What a device can do, decided from the GATT services it really exposes (never from its name). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Capability")))
@interface SensorCoreCapability : SensorCoreKotlinEnum<SensorCoreCapability *>
+ (instancetype)alloc __attribute__((unavailable));

/** What a device can do, decided from the GATT services it really exposes (never from its name). */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SensorCoreCapability *heartRate __attribute__((swift_name("heartRate")));
@property (class, readonly) SensorCoreCapability *runningSpeedCadence __attribute__((swift_name("runningSpeedCadence")));
@property (class, readonly) SensorCoreCapability *cyclingSpeedCadence __attribute__((swift_name("cyclingSpeedCadence")));
@property (class, readonly) SensorCoreCapability *cyclingPower __attribute__((swift_name("cyclingPower")));
@property (class, readonly) SensorCoreCapability *fitnessMachine __attribute__((swift_name("fitnessMachine")));
@property (class, readonly) SensorCoreCapability *battery __attribute__((swift_name("battery")));
@property (class, readonly) SensorCoreCapability *deviceInformation __attribute__((swift_name("deviceInformation")));
+ (SensorCoreKotlinArray<SensorCoreCapability *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SensorCoreCapability *> *entries __attribute__((swift_name("entries")));
@end


/** What the hub knows about one device besides its metrics. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DeviceDetails")))
@interface SensorCoreDeviceDetails : SensorCoreBase
- (instancetype)initWithManufacturer:(NSString * _Nullable)manufacturer model:(NSString * _Nullable)model firmware:(NSString * _Nullable)firmware batteryPercent:(SensorCoreInt * _Nullable)batteryPercent recentRrMs:(NSArray<SensorCoreInt *> *)recentRrMs __attribute__((swift_name("init(manufacturer:model:firmware:batteryPercent:recentRrMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) SensorCoreInt * _Nullable batteryPercent __attribute__((swift_name("batteryPercent")));
@property (readonly) NSString * _Nullable firmware __attribute__((swift_name("firmware")));
@property (readonly) NSString * _Nullable manufacturer __attribute__((swift_name("manufacturer")));
@property (readonly) NSString * _Nullable model __attribute__((swift_name("model")));

/** The R-R intervals of the latest heart rate notification that had some (empty when none yet). */
@property (readonly) NSArray<SensorCoreInt *> *recentRrMs __attribute__((swift_name("recentRrMs")));
@end


/** What a device told about itself (read once, never measured). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DeviceInfoField")))
@interface SensorCoreDeviceInfoField : SensorCoreKotlinEnum<SensorCoreDeviceInfoField *>
+ (instancetype)alloc __attribute__((unavailable));

/** What a device told about itself (read once, never measured). */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SensorCoreDeviceInfoField *manufacturer __attribute__((swift_name("manufacturer")));
@property (class, readonly) SensorCoreDeviceInfoField *model __attribute__((swift_name("model")));
@property (class, readonly) SensorCoreDeviceInfoField *firmware __attribute__((swift_name("firmware")));
@property (class, readonly) SensorCoreDeviceInfoField *hardware __attribute__((swift_name("hardware")));
@property (class, readonly) SensorCoreDeviceInfoField *software __attribute__((swift_name("software")));
+ (SensorCoreKotlinArray<SensorCoreDeviceInfoField *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SensorCoreDeviceInfoField *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MeasurementKind")))
@interface SensorCoreMeasurementKind : SensorCoreKotlinEnum<SensorCoreMeasurementKind *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SensorCoreMeasurementKind *instantaneous __attribute__((swift_name("instantaneous")));
@property (class, readonly) SensorCoreMeasurementKind *cumulative __attribute__((swift_name("cumulative")));
+ (SensorCoreKotlinArray<SensorCoreMeasurementKind *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SensorCoreMeasurementKind *> *entries __attribute__((swift_name("entries")));
@end


/** What a reading measures. Units are fixed (see each entry): an adapter converts BEFORE it makes a reading. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MetricType")))
@interface SensorCoreMetricType : SensorCoreKotlinEnum<SensorCoreMetricType *>
+ (instancetype)alloc __attribute__((unavailable));

/** What a reading measures. Units are fixed (see each entry): an adapter converts BEFORE it makes a reading. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SensorCoreMetricType *heartRate __attribute__((swift_name("heartRate")));
@property (class, readonly) SensorCoreMetricType *runningSpeed __attribute__((swift_name("runningSpeed")));
@property (class, readonly) SensorCoreMetricType *runningCadence __attribute__((swift_name("runningCadence")));
@property (class, readonly) SensorCoreMetricType *runningStrideLength __attribute__((swift_name("runningStrideLength")));
@property (class, readonly) SensorCoreMetricType *totalDistance __attribute__((swift_name("totalDistance")));
@property (class, readonly) SensorCoreMetricType *cyclingCadence __attribute__((swift_name("cyclingCadence")));
@property (class, readonly) SensorCoreMetricType *powerWatts __attribute__((swift_name("powerWatts")));
@property (class, readonly) SensorCoreMetricType *cyclingSpeed __attribute__((swift_name("cyclingSpeed")));
@property (class, readonly) SensorCoreMetricType *incline __attribute__((swift_name("incline")));
@property (class, readonly) SensorCoreMetricType *energyKcal __attribute__((swift_name("energyKcal")));
@property (class, readonly) SensorCoreMetricType *strokeRate __attribute__((swift_name("strokeRate")));
@property (class, readonly) SensorCoreMetricType *strokeCount __attribute__((swift_name("strokeCount")));
@property (class, readonly) SensorCoreMetricType *wheelRevolutions __attribute__((swift_name("wheelRevolutions")));
@property (class, readonly) SensorCoreMetricType *stepRate __attribute__((swift_name("stepRate")));
@property (class, readonly) SensorCoreMetricType *floors __attribute__((swift_name("floors")));
+ (SensorCoreKotlinArray<SensorCoreMetricType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SensorCoreMetricType *> *entries __attribute__((swift_name("entries")));
@end


/**
 * What a notification (or a read) of a characteristic turned into. A reading is a number the resolver can choose; the other
 * events are structured data that is not one number and is kept per device.
 */
__attribute__((swift_name("SensorEvent")))
@protocol SensorCoreSensorEvent
@required
@end


/** The device's own battery level, 0 to 100. Per device: it is never resolved between devices. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorEventBattery")))
@interface SensorCoreSensorEventBattery : SensorCoreBase <SensorCoreSensorEvent>
- (instancetype)initWithPercent:(int32_t)percent __attribute__((swift_name("init(percent:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int32_t percent __attribute__((swift_name("percent")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorEventDeviceInfo")))
@interface SensorCoreSensorEventDeviceInfo : SensorCoreBase <SensorCoreSensorEvent>
- (instancetype)initWithField:(SensorCoreDeviceInfoField *)field value:(NSString *)value __attribute__((swift_name("init(field:value:)"))) __attribute__((objc_designated_initializer));
@property (readonly) SensorCoreDeviceInfoField *field __attribute__((swift_name("field")));
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorEventMeasurement")))
@interface SensorCoreSensorEventMeasurement : SensorCoreBase <SensorCoreSensorEvent>
- (instancetype)initWithReading:(SensorCoreSensorReading *)reading __attribute__((swift_name("init(reading:)"))) __attribute__((objc_designated_initializer));
@property (readonly) SensorCoreSensorReading *reading __attribute__((swift_name("reading")));
@end


/** R-R intervals in milliseconds, in the order the sensor sent them. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorEventRrIntervals")))
@interface SensorCoreSensorEventRrIntervals : SensorCoreBase <SensorCoreSensorEvent>
- (instancetype)initWithIntervalsMs:(NSArray<SensorCoreInt *> *)intervalsMs __attribute__((swift_name("init(intervalsMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) NSArray<SensorCoreInt *> *intervalsMs __attribute__((swift_name("intervalsMs")));
@end


/** One number from one source. `receivedAtMs` is the receiving phone's monotonic clock, never the device's clock. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorReading")))
@interface SensorCoreSensorReading : SensorCoreBase
- (instancetype)initWithMetric:(SensorCoreMetricType *)metric value:(double)value kind:(SensorCoreMeasurementKind *)kind __attribute__((swift_name("init(metric:value:kind:)"))) __attribute__((objc_designated_initializer));
@property (readonly) SensorCoreMeasurementKind *kind __attribute__((swift_name("kind")));
@property (readonly) SensorCoreMetricType *metric __attribute__((swift_name("metric")));
@property (readonly) double value __attribute__((swift_name("value")));
@end


/**
 * One GATT service the core understands: what to subscribe to, what to read once, and how to decode. Pure Kotlin: a parser never
 * calls a Bluetooth API, so it is tested with packets. A packet that is truncated or impossible gives no events.
 */
__attribute__((swift_name("BleProtocolAdapter")))
@protocol SensorCoreBleProtocolAdapter
@required
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));

/** What this service tells about the device that has it. */
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));

/** Characteristics whose bytes are also handed to the host untouched. */
@property (readonly) NSSet<NSString *> *forwardRaw __attribute__((swift_name("forwardRaw")));

/** Characteristics to subscribe to (notify or indicate), when the device has them. */
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));

/** Characteristics to read once after connecting (their value is decoded like a notification). */
@property (readonly) NSArray<NSString *> *readCharacteristics __attribute__((swift_name("readCharacteristics")));

/** 16-bit service number, 4 lowercase hex digits. */
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end


/**
 * Reads little-endian fields in order. A read past the end flips [ok] to false and returns 0, so a parser reads everything the
 * flags announce and rejects the whole packet at the end if [ok] is false (a truncated packet is never half-used).
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ByteReader")))
@interface SensorCoreByteReader : SensorCoreBase
- (instancetype)initWithBytes:(SensorCoreKotlinByteArray *)bytes at:(int32_t)at __attribute__((swift_name("init(bytes:at:)"))) __attribute__((objc_designated_initializer));
- (int32_t)s16 __attribute__((swift_name("s16()")));
- (void)skipN:(int32_t)n __attribute__((swift_name("skip(n:)")));
- (int32_t)u16 __attribute__((swift_name("u16()")));
- (int32_t)u24 __attribute__((swift_name("u24()")));
- (int64_t)u32 __attribute__((swift_name("u32()")));
- (int32_t)u8 __attribute__((swift_name("u8()")));
@property (readonly) BOOL ok __attribute__((swift_name("ok")));
@property (readonly) int32_t remaining __attribute__((swift_name("remaining")));
@end


/**
 * The rate of a (count, event time) pair that a cycling sensor sends: revolutions of a crank or a wheel. The count wraps at 16
 * or 32 bits and the event time at 16 bits (1/[ticksPerSecond] s), so a value is computed between two consecutive EVENTS.
 *
 * Answers: a rate in events per second, [ZERO] when the rotation is verified stopped, or [UNKNOWN].
 *  - Stopped needs valid notifications that keep arriving with an unchanged counter for longer than an event can take
 *    ([zeroAfterMs], or twice the last event interval when that is longer). The lack of notifications is NOT zero: the answer
 *    is [UNKNOWN] once [staleMs] passes (see [rate]).
 *  - The 16-bit event clock wraps every 65536/[ticksPerSecond] s: when the previous event is [eventClockSpanMs] or more in the
 *    past the two samples are not comparable, so a new baseline is taken and no value is given.
 *  - A counter jump the elapsed time cannot explain at [maxRate] (a sensor reset) takes a new baseline too, and so does a clock
 *    that goes back or a silence of [silenceResetMs].
 *  - A rate below [minRate] (the first event after a long coast averages over the coast) or above [maxRate] is not a value.
 * Call [reset] for every new connection. All `nowMs` come from one monotonic clock. Not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CounterRate")))
@interface SensorCoreCounterRate : SensorCoreBase
- (instancetype)initWithTicksPerSecond:(double)ticksPerSecond countMask:(int64_t)countMask minRate:(double)minRate maxRate:(double)maxRate staleMs:(int64_t)staleMs zeroAfterMs:(int64_t)zeroAfterMs silenceResetMs:(int64_t)silenceResetMs __attribute__((swift_name("init(ticksPerSecond:countMask:minRate:maxRate:staleMs:zeroAfterMs:silenceResetMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SensorCoreCounterRateCompanion *companion __attribute__((swift_name("companion")));
- (double)onSampleCount:(int64_t)count eventTicks:(int32_t)eventTicks nowMs:(int64_t)nowMs __attribute__((swift_name("onSample(count:eventTicks:nowMs:)")));

/** The last answer while notifications keep arriving, [UNKNOWN] once none came for [staleMs] (never [ZERO]). */
- (double)rateNowMs:(int64_t)nowMs __attribute__((swift_name("rate(nowMs:)")));
- (void)reset __attribute__((swift_name("reset()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CounterRate.Companion")))
@interface SensorCoreCounterRateCompanion : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreCounterRateCompanion *shared __attribute__((swift_name("shared")));

/** A crank: 16-bit count, 1/1024 s ticks, 15 to 220 rpm. */
- (SensorCoreCounterRate *)crank __attribute__((swift_name("crank()")));

/** A wheel of a CSC sensor: 32-bit count, 1/1024 s ticks. */
- (SensorCoreCounterRate *)cscWheel __attribute__((swift_name("cscWheel()")));

/** A wheel of a power meter: 32-bit count, 1/2048 s ticks. */
- (SensorCoreCounterRate *)powerWheel __attribute__((swift_name("powerWheel()")));
@property (readonly) double UNKNOWN __attribute__((swift_name("UNKNOWN")));
@property (readonly) double ZERO __attribute__((swift_name("ZERO")));
@end


/**
 * The 16-bit Bluetooth SIG numbers this package knows, written as 4 lowercase hex digits ("180d"). A native layer converts a
 * full 128-bit UUID of the SIG base (0000xxxx-0000-1000-8000-00805f9b34fb) with [short] before it calls the core.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Gatt")))
@interface SensorCoreGatt : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * The 16-bit Bluetooth SIG numbers this package knows, written as 4 lowercase hex digits ("180d"). A native layer converts a
 * full 128-bit UUID of the SIG base (0000xxxx-0000-1000-8000-00805f9b34fb) with [short] before it calls the core.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)gatt __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreGatt *shared __attribute__((swift_name("shared")));

/** The capabilities of a device from the services it exposes. Unknown services add nothing. */
- (NSArray<SensorCoreCapability *> *)capabilitiesServiceUuids:(NSArray<NSString *> *)serviceUuids __attribute__((swift_name("capabilities(serviceUuids:)")));

/** "0000180D-0000-1000-8000-00805F9B34FB" or "180D" or "0x180d" to "180d"; any other UUID is returned lowercase. */
- (NSString *)shortUuid:(NSString *)uuid __attribute__((swift_name("short(uuid:)")));
@property (readonly) NSString *BATTERY_LEVEL __attribute__((swift_name("BATTERY_LEVEL")));
@property (readonly) NSString *BATTERY_SERVICE __attribute__((swift_name("BATTERY_SERVICE")));
@property (readonly) NSString *CROSS_TRAINER_DATA __attribute__((swift_name("CROSS_TRAINER_DATA")));
@property (readonly) NSString *CSC_MEASUREMENT __attribute__((swift_name("CSC_MEASUREMENT")));
@property (readonly) NSString *CYCLING_POWER_MEASUREMENT __attribute__((swift_name("CYCLING_POWER_MEASUREMENT")));
@property (readonly) NSString *CYCLING_POWER_SERVICE __attribute__((swift_name("CYCLING_POWER_SERVICE")));
@property (readonly) NSString *CYCLING_SPEED_CADENCE_SERVICE __attribute__((swift_name("CYCLING_SPEED_CADENCE_SERVICE")));
@property (readonly) NSString *DEVICE_INFORMATION_SERVICE __attribute__((swift_name("DEVICE_INFORMATION_SERVICE")));
@property (readonly) NSString *FIRMWARE_REVISION __attribute__((swift_name("FIRMWARE_REVISION")));
@property (readonly) NSString *FITNESS_MACHINE_SERVICE __attribute__((swift_name("FITNESS_MACHINE_SERVICE")));
@property (readonly) NSString *HARDWARE_REVISION __attribute__((swift_name("HARDWARE_REVISION")));
@property (readonly) NSString *HEART_RATE_MEASUREMENT __attribute__((swift_name("HEART_RATE_MEASUREMENT")));
@property (readonly) NSString *HEART_RATE_SERVICE __attribute__((swift_name("HEART_RATE_SERVICE")));
@property (readonly) NSString *INDOOR_BIKE_DATA __attribute__((swift_name("INDOOR_BIKE_DATA")));
@property (readonly) NSString *MANUFACTURER_NAME __attribute__((swift_name("MANUFACTURER_NAME")));
@property (readonly) NSString *MODEL_NUMBER __attribute__((swift_name("MODEL_NUMBER")));
@property (readonly) NSString *ROWER_DATA __attribute__((swift_name("ROWER_DATA")));
@property (readonly) NSString *RSC_MEASUREMENT __attribute__((swift_name("RSC_MEASUREMENT")));
@property (readonly) NSString *RUNNING_SPEED_CADENCE_SERVICE __attribute__((swift_name("RUNNING_SPEED_CADENCE_SERVICE")));
@property (readonly) NSString *SOFTWARE_REVISION __attribute__((swift_name("SOFTWARE_REVISION")));
@property (readonly) NSString *STAIR_CLIMBER_DATA __attribute__((swift_name("STAIR_CLIMBER_DATA")));
@property (readonly) NSString *STEP_CLIMBER_DATA __attribute__((swift_name("STEP_CLIMBER_DATA")));
@property (readonly) NSString *TREADMILL_DATA __attribute__((swift_name("TREADMILL_DATA")));
@end


/** One decoded Heart Rate Measurement (0x2A37). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HeartRateMeasurement")))
@interface SensorCoreHeartRateMeasurement : SensorCoreBase
- (instancetype)initWithBpm:(SensorCoreInt * _Nullable)bpm energyKj:(SensorCoreInt * _Nullable)energyKj rrIntervalsMs:(NSArray<SensorCoreInt *> *)rrIntervalsMs contactLost:(BOOL)contactLost __attribute__((swift_name("init(bpm:energyKj:rrIntervalsMs:contactLost:)"))) __attribute__((objc_designated_initializer));

/** Beats per minute, or null when the packet carries no usable value (0, or the strap has no skin contact). */
@property (readonly) SensorCoreInt * _Nullable bpm __attribute__((swift_name("bpm")));

/** True when the sensor says it has no skin contact (the value cannot be trusted). */
@property (readonly) BOOL contactLost __attribute__((swift_name("contactLost")));

/** Energy expended in kJ since the sensor reset, when present. */
@property (readonly) SensorCoreInt * _Nullable energyKj __attribute__((swift_name("energyKj")));

/** R-R intervals in milliseconds (the packet has them in 1/1024 s), when present. */
@property (readonly) NSArray<SensorCoreInt *> *rrIntervalsMs __attribute__((swift_name("rrIntervalsMs")));
@end


/**
 * Heart Rate Measurement: flags (bit 0: value is uint16 instead of uint8; bits 1-2: sensor contact, 2 = supported but not
 * detected, 3 = detected; bit 3: energy expended present, uint16 kJ; bit 4: one or more R-R intervals, uint16 each, 1/1024 s),
 * then the value, then the optional fields in that order. A truncated packet is rejected as a whole.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HeartRateParser")))
@interface SensorCoreHeartRateParser : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Heart Rate Measurement: flags (bit 0: value is uint16 instead of uint8; bits 1-2: sensor contact, 2 = supported but not
 * detected, 3 = detected; bit 3: energy expended present, uint16 kJ; bit 4: one or more R-R intervals, uint16 each, 1/1024 s),
 * then the value, then the optional fields in that order. A truncated packet is rejected as a whole.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)heartRateParser __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreHeartRateParser *shared __attribute__((swift_name("shared")));
- (SensorCoreHeartRateMeasurement * _Nullable)parseBytes:(SensorCoreKotlinByteArray *)bytes __attribute__((swift_name("parse(bytes:)")));
- (NSArray<SensorCoreSensorReading *> *)readingsBytes:(SensorCoreKotlinByteArray *)bytes __attribute__((swift_name("readings(bytes:)")));
@property (readonly) int32_t MAX_BPM __attribute__((swift_name("MAX_BPM")));
@end


/**
 * Every protocol the core understands. A native layer asks this registry WHAT to scan for, subscribe to and read (it never keeps
 * its own list), and the hub asks it HOW to decode. Adding a protocol is one adapter here.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProtocolRegistry")))
@interface SensorCoreProtocolRegistry : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Every protocol the core understands. A native layer asks this registry WHAT to scan for, subscribe to and read (it never keeps
 * its own list), and the hub asks it HOW to decode. Adding a protocol is one adapter here.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)protocolRegistry __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreProtocolRegistry *shared __attribute__((swift_name("shared")));
- (id<SensorCoreBleProtocolAdapter> _Nullable)adapterForCharacteristic:(NSString *)characteristic __attribute__((swift_name("adapterFor(characteristic:)")));

/** True when a characteristic can be turned into data or handed over. */
- (BOOL)isUsefulCharacteristic:(NSString *)characteristic __attribute__((swift_name("isUseful(characteristic:)")));

/**
 * True when a characteristic carries WORKOUT data (not just battery or device information): a device where none of these could
 * be subscribed is connected but not usable for a workout.
 */
- (BOOL)isWorkoutCharacteristicCharacteristic:(NSString *)characteristic __attribute__((swift_name("isWorkoutCharacteristic(characteristic:)")));

/** Characteristics to subscribe to after connecting (the transport keeps the ones the device really has). */
- (NSArray<NSString *> *)notifyCharacteristics __attribute__((swift_name("notifyCharacteristics()")));

/** Characteristics whose bytes are also handed to the host untouched. */
- (NSSet<NSString *> *)rawForwarded __attribute__((swift_name("rawForwarded()")));

/** Characteristics to read once after connecting. */
- (NSArray<NSString *> *)readCharacteristics __attribute__((swift_name("readCharacteristics()")));

/** Services worth scanning for: the ones that carry workout data (battery and device information are not advertised for it). */
- (NSArray<NSString *> *)scanServices __attribute__((swift_name("scanServices()")));
@property (readonly) NSArray<id<SensorCoreBleProtocolAdapter>> *adapters __attribute__((swift_name("adapters")));
@end


/** One decoded RSC Measurement (0x2A53). */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RunningSpeedCadenceMeasurement")))
@interface SensorCoreRunningSpeedCadenceMeasurement : SensorCoreBase
- (instancetype)initWithSpeedMps:(double)speedMps cadencePerMin:(int32_t)cadencePerMin strideLengthM:(SensorCoreDouble * _Nullable)strideLengthM totalDistanceM:(SensorCoreDouble * _Nullable)totalDistanceM isRunning:(BOOL)isRunning __attribute__((swift_name("init(speedMps:cadencePerMin:strideLengthM:totalDistanceM:isRunning:)"))) __attribute__((objc_designated_initializer));

/** Per minute, as the device reports it (steps or strides: devices differ, check with the real device). */
@property (readonly) int32_t cadencePerMin __attribute__((swift_name("cadencePerMin")));
@property (readonly) BOOL isRunning __attribute__((swift_name("isRunning")));

/** Metres per second. */
@property (readonly) double speedMps __attribute__((swift_name("speedMps")));

/** Metres, when the device sends it. */
@property (readonly) SensorCoreDouble * _Nullable strideLengthM __attribute__((swift_name("strideLengthM")));

/** Metres since the device's own start, when the device sends it. */
@property (readonly) SensorCoreDouble * _Nullable totalDistanceM __attribute__((swift_name("totalDistanceM")));
@end


/**
 * RSC Measurement: flags (bit 0: stride length present; bit 1: total distance present; bit 2: running (1) or walking (0)),
 * then speed (uint16, 1/256 m/s), cadence (uint8, 1/min), then stride length (uint16, 1/100 m) and total distance
 * (uint32, 1/10 m) when flagged. Speed and cadence are mandatory; a truncated packet is rejected as a whole.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RunningSpeedCadenceParser")))
@interface SensorCoreRunningSpeedCadenceParser : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * RSC Measurement: flags (bit 0: stride length present; bit 1: total distance present; bit 2: running (1) or walking (0)),
 * then speed (uint16, 1/256 m/s), cadence (uint8, 1/min), then stride length (uint16, 1/100 m) and total distance
 * (uint32, 1/10 m) when flagged. Speed and cadence are mandatory; a truncated packet is rejected as a whole.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)runningSpeedCadenceParser __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreRunningSpeedCadenceParser *shared __attribute__((swift_name("shared")));
- (SensorCoreRunningSpeedCadenceMeasurement * _Nullable)parseBytes:(SensorCoreKotlinByteArray *)bytes __attribute__((swift_name("parse(bytes:)")));
- (NSArray<SensorCoreSensorReading *> *)readingsBytes:(SensorCoreKotlinByteArray *)bytes __attribute__((swift_name("readings(bytes:)")));
@property (readonly) double MAX_SPEED_MPS __attribute__((swift_name("MAX_SPEED_MPS")));
@end


/** The decoders of one connection of one device (counters, rates): a new connection gets a new state. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SourceState")))
@interface SensorCoreSourceState : SensorCoreBase

/** The decoders of one connection of one device (counters, rates): a new connection gets a new state. */
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));

/** The decoders of one connection of one device (counters, rates): a new connection gets a new state. */
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (id)getOrPutKey:(NSString *)key make:(id (^)(void))make __attribute__((swift_name("getOrPut(key:make:)")));

/** Wheel circumference in metres, when the host knows it (a wheel sensor gives revolutions, not speed). */
@property SensorCoreDouble * _Nullable wheelCircumferenceM __attribute__((swift_name("wheelCircumferenceM")));
@end


/** Battery Level (0x2A19): one byte, 0 to 100. Read once and notified when the device supports it. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BatteryAdapter")))
@interface SensorCoreBatteryAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));

/** Battery Level (0x2A19): one byte, 0 to 100. Read once and notified when the device supports it. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)batteryAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreBatteryAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSArray<NSString *> *readCharacteristics __attribute__((swift_name("readCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end


/**
 * Cycling Power Measurement (0x2A63): flags (uint16), instantaneous power (sint16, W), then by flag: pedal power balance (bit 0,
 * uint8), accumulated torque (bit 2, uint16), wheel revolution data (bit 4: uint32 + uint16 in 1/2048 s), crank revolution data
 * (bit 5: uint16 + uint16 in 1/1024 s). Later fields (extreme forces, angles, energy) are not needed and not read. A negative
 * power is noise and becomes 0. Not every power meter sends crank data: cadence is only given when the packet has it.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CyclingPowerAdapter")))
@interface SensorCoreCyclingPowerAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Cycling Power Measurement (0x2A63): flags (uint16), instantaneous power (sint16, W), then by flag: pedal power balance (bit 0,
 * uint8), accumulated torque (bit 2, uint16), wheel revolution data (bit 4: uint32 + uint16 in 1/2048 s), crank revolution data
 * (bit 5: uint16 + uint16 in 1/1024 s). Later fields (extreme forces, angles, energy) are not needed and not read. A negative
 * power is noise and becomes 0. Not every power meter sends crank data: cadence is only given when the packet has it.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)cyclingPowerAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreCyclingPowerAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end


/**
 * Cycling Speed and Cadence Measurement (0x2A5B): flags (bit 0 wheel data, bit 1 crank data), wheel revolutions (uint32) and last
 * wheel event time (uint16, 1/1024 s), crank revolutions (uint16) and last crank event time (uint16, 1/1024 s). The crank gives
 * CYCLING_CADENCE (0 when verified still), the wheel gives the WHEEL_REVOLUTIONS counter and, when the host knows the wheel
 * circumference, CYCLING_SPEED. The raw packet is also forwarded to the host.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CyclingSpeedCadenceAdapter")))
@interface SensorCoreCyclingSpeedCadenceAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Cycling Speed and Cadence Measurement (0x2A5B): flags (bit 0 wheel data, bit 1 crank data), wheel revolutions (uint32) and last
 * wheel event time (uint16, 1/1024 s), crank revolutions (uint16) and last crank event time (uint16, 1/1024 s). The crank gives
 * CYCLING_CADENCE (0 when verified still), the wheel gives the WHEEL_REVOLUTIONS counter and, when the host knows the wheel
 * circumference, CYCLING_SPEED. The raw packet is also forwarded to the host.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)cyclingSpeedCadenceAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreCyclingSpeedCadenceAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSSet<NSString *> *forwardRaw __attribute__((swift_name("forwardRaw")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end


/** Device Information strings (manufacturer, model, firmware, hardware, software), read once. The serial number is not read. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DeviceInformationAdapter")))
@interface SensorCoreDeviceInformationAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));

/** Device Information strings (manufacturer, model, firmware, hardware, software), read once. The serial number is not read. */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)deviceInformationAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreDeviceInformationAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSArray<NSString *> *readCharacteristics __attribute__((swift_name("readCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end


/**
 * Fitness Machine Service (0x1826), READ-ONLY telemetry: the data characteristics of treadmill (0x2ACD), cross trainer (0x2ACE),
 * step climber (0x2ACF), stair climber (0x2AD0), rower (0x2AD1) and indoor bike (0x2AD2). The control point is never touched.
 *
 * Every data characteristic starts with flags and then lists its fields in a fixed order, each present or not by a flag. The
 * parser reads every field the flags announce, so a later field is never misaligned, and rejects the whole packet if it is
 * truncated. In the "more data" flag (bit 0) a value of 0 means the first field is PRESENT. The field layouts are written from
 * the Bluetooth SIG specification and golden packets, NOT yet captured from a device: the size of the Resistance Level field
 * (taken as 2 bytes) and the step and stair climber layouts in particular need a real machine to confirm.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FitnessMachineAdapter")))
@interface SensorCoreFitnessMachineAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));

/**
 * Fitness Machine Service (0x1826), READ-ONLY telemetry: the data characteristics of treadmill (0x2ACD), cross trainer (0x2ACE),
 * step climber (0x2ACF), stair climber (0x2AD0), rower (0x2AD1) and indoor bike (0x2AD2). The control point is never touched.
 *
 * Every data characteristic starts with flags and then lists its fields in a fixed order, each present or not by a flag. The
 * parser reads every field the flags announce, so a later field is never misaligned, and rejects the whole packet if it is
 * truncated. In the "more data" flag (bit 0) a value of 0 means the first field is PRESENT. The field layouts are written from
 * the Bluetooth SIG specification and golden packets, NOT yet captured from a device: the size of the Resistance Level field
 * (taken as 2 bytes) and the step and stair climber layouts in particular need a real machine to confirm.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)fitnessMachineAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreFitnessMachineAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HeartRateAdapter")))
@interface SensorCoreHeartRateAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)heartRateAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreHeartRateAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RunningSpeedCadenceAdapter")))
@interface SensorCoreRunningSpeedCadenceAdapter : SensorCoreBase <SensorCoreBleProtocolAdapter>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)runningSpeedCadenceAdapter __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreRunningSpeedCadenceAdapter *shared __attribute__((swift_name("shared")));
- (NSArray<id<SensorCoreSensorEvent>> *)decodeCharacteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes state:(SensorCoreSourceState *)state nowMs:(int64_t)nowMs __attribute__((swift_name("decode(characteristic:bytes:state:nowMs:)")));
@property (readonly) SensorCoreCapability *capability __attribute__((swift_name("capability")));
@property (readonly) NSArray<NSString *> *notifyCharacteristics __attribute__((swift_name("notifyCharacteristics")));
@property (readonly) NSString *serviceUuid __attribute__((swift_name("serviceUuid")));
@end


/**
 * The latest value of one metric of ONE device, before any source is chosen: [sourceId] and [epoch] say whose it is and of which
 * connection, [ageMs] how old it is (the consumer decides what is fresh). A caller that needs a specific device's counter (a rower's
 * distance next to a footpod's) reads it here instead of from the resolved value.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DeviceMetricValue")))
@interface SensorCoreDeviceMetricValue : SensorCoreBase
- (instancetype)initWithSourceId:(NSString *)sourceId epoch:(int64_t)epoch metric:(SensorCoreMetricType *)metric value:(double)value kind:(SensorCoreMeasurementKind *)kind ageMs:(int64_t)ageMs __attribute__((swift_name("init(sourceId:epoch:metric:value:kind:ageMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t ageMs __attribute__((swift_name("ageMs")));
@property (readonly) int64_t epoch __attribute__((swift_name("epoch")));
@property (readonly) SensorCoreMeasurementKind *kind __attribute__((swift_name("kind")));
@property (readonly) SensorCoreMetricType *metric __attribute__((swift_name("metric")));
@property (readonly) NSString *sourceId __attribute__((swift_name("sourceId")));
@property (readonly) double value __attribute__((swift_name("value")));
@end


/**
 * Chooses ONE source for each metric, at the level of the metric (not of the workout): a session can take its heart rate
 * from a chest strap and its cadence from a footpod at the same time. Values are never averaged or summed.
 *
 *  - A source is a candidate for a metric while it is connected, its value is fresh ([MetricResolverConfig.staleAfterMs]) and
 *    it has recovered (see the config). A value of 0 is a measurement like any other.
 *  - Choice: the source the user prefers ([setPreferred]) when it is a candidate, else the candidate of the best RANK for the
 *    metric ([SourcePolicy]: a heart rate strap before a machine's heart rate, a power meter's cadence before a cadence sensor's),
 *    else, among equals, the one already chosen (so two equally good sources do not alternate), else the one that connected first.
 *    A better ranked source that becomes healthy takes over once; it never alternates, because a rank does not change.
 *  - A source is `(sourceId, epoch)`: the epoch grows with every new connection to the device. A reading or a connection event
 *    of an older epoch is dropped, and a newer epoch forgets everything the source had (counters of a reset sensor are never
 *    compared with the old ones).
 * All times come from one monotonic clock. Not thread-safe (the native engine calls it under its own lock/queue).
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MetricResolver")))
@interface SensorCoreMetricResolver : SensorCoreBase
- (instancetype)initWithConfig:(SensorCoreMetricResolverConfig *)config __attribute__((swift_name("init(config:)"))) __attribute__((objc_designated_initializer));

/** The latest value of every metric of every CONNECTED device (any age: [DeviceMetricValue.ageMs] tells), nothing is chosen. */
- (NSArray<SensorCoreDeviceMetricValue *> *)deviceValuesNowMs:(int64_t)nowMs __attribute__((swift_name("deviceValues(nowMs:)")));

/** Forgets a device altogether (the user removed it). */
- (void)forgetSourceId:(NSString *)sourceId __attribute__((swift_name("forget(sourceId:)")));

/** The host connected to (or lost) a device. Returns false when the event is of an epoch older than the current one. */
- (BOOL)onConnectionSourceId:(NSString *)sourceId epoch:(int64_t)epoch connected:(BOOL)connected __attribute__((swift_name("onConnection(sourceId:epoch:connected:)")));

/** Takes a reading of a connected source of the current epoch; false when it was dropped. */
- (BOOL)onReadingSourceId:(NSString *)sourceId epoch:(int64_t)epoch reading:(SensorCoreSensorReading *)reading atMs:(int64_t)atMs __attribute__((swift_name("onReading(sourceId:epoch:reading:atMs:)")));
- (void)reset __attribute__((swift_name("reset()")));

/** The chosen value of every metric that has a candidate, at [nowMs]. */
- (NSArray<SensorCoreResolvedMetric *> *)resolveNowMs:(int64_t)nowMs __attribute__((swift_name("resolve(nowMs:)")));

/** What the device can do (decided from the services it really exposes); it decides its rank for each metric. */
- (void)setCapabilitiesSourceId:(NSString *)sourceId capabilities:(NSSet<SensorCoreCapability *> *)capabilities __attribute__((swift_name("setCapabilities(sourceId:capabilities:)")));

/** The user's choice for [metric] (null clears it). It only applies while that source is a candidate. */
- (void)setPreferredMetric:(SensorCoreMetricType *)metric sourceId:(NSString * _Nullable)sourceId __attribute__((swift_name("setPreferred(metric:sourceId:)")));
@end


/** Starting values, not measured. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MetricResolverConfig")))
@interface SensorCoreMetricResolverConfig : SensorCoreBase
- (instancetype)initWithStaleAfterMs:(int64_t)staleAfterMs recoveryMinSamples:(int32_t)recoveryMinSamples recoveryMinMs:(int64_t)recoveryMinMs __attribute__((swift_name("init(staleAfterMs:recoveryMinSamples:recoveryMinMs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SensorCoreMetricResolverConfigCompanion *companion __attribute__((swift_name("companion")));

/** ...spread over at least this long, before it is a candidate again. */
@property (readonly) int64_t recoveryMinMs __attribute__((swift_name("recoveryMinMs")));

/** After a (re)connect or a stale spell a source needs this many valid values... */
@property (readonly) int32_t recoveryMinSamples __attribute__((swift_name("recoveryMinSamples")));

/** A source with no value of a metric for this long is stale for that metric. */
@property (readonly) int64_t staleAfterMs __attribute__((swift_name("staleAfterMs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MetricResolverConfig.Companion")))
@interface SensorCoreMetricResolverConfigCompanion : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreMetricResolverConfigCompanion *shared __attribute__((swift_name("shared")));
- (SensorCoreMetricResolverConfig *)standard __attribute__((swift_name("standard()")));
@end


/** The chosen value of one metric. [ageMs] is how old it is on the receiving phone's monotonic clock. */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ResolvedMetric")))
@interface SensorCoreResolvedMetric : SensorCoreBase
- (instancetype)initWithMetric:(SensorCoreMetricType *)metric value:(double)value sourceId:(NSString *)sourceId kind:(SensorCoreMeasurementKind *)kind ageMs:(int64_t)ageMs __attribute__((swift_name("init(metric:value:sourceId:kind:ageMs:)"))) __attribute__((objc_designated_initializer));
@property (readonly) int64_t ageMs __attribute__((swift_name("ageMs")));
@property (readonly) SensorCoreMeasurementKind *kind __attribute__((swift_name("kind")));
@property (readonly) SensorCoreMetricType *metric __attribute__((swift_name("metric")));
@property (readonly) NSString *sourceId __attribute__((swift_name("sourceId")));
@property (readonly) double value __attribute__((swift_name("value")));
@end


/**
 * What a native BLE layer holds: it forwards every connection event and every notification or read (the characteristic and its
 * bytes) and asks for the resolved metrics and the details of each device. Decoding (through [ProtocolRegistry]), validation,
 * epochs, freshness and the choice of source are all here, so Android and iOS behave the same and the Flutter side never sees a
 * byte.
 *
 * Per connection of a device the decoders start empty (the counters of a new connection are never compared with the old
 * ones). A characteristic the registry does not know is ignored. Not thread-safe.
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorHub")))
@interface SensorCoreSensorHub : SensorCoreBase
- (instancetype)initWithConfig:(SensorCoreMetricResolverConfig *)config __attribute__((swift_name("init(config:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SensorCoreSensorHubCompanion *companion __attribute__((swift_name("companion")));
- (SensorCoreDeviceDetails *)detailsSourceId:(NSString *)sourceId __attribute__((swift_name("details(sourceId:)")));

/** The latest value of each metric of EACH connected device, nothing chosen (for a consumer that needs a specific device). */
- (NSArray<SensorCoreDeviceMetricValue *> *)deviceValuesNowMs:(int64_t)nowMs __attribute__((swift_name("deviceValues(nowMs:)")));
- (void)forgetSourceId:(NSString *)sourceId __attribute__((swift_name("forget(sourceId:)")));
- (BOOL)onConnectionSourceId:(NSString *)sourceId epoch:(int64_t)epoch connected:(BOOL)connected __attribute__((swift_name("onConnection(sourceId:epoch:connected:)")));

/** One notification or read. Returns how many events were taken (0 for an unknown, malformed or stale-epoch packet). */
- (int32_t)onPacketSourceId:(NSString *)sourceId epoch:(int64_t)epoch characteristic:(NSString *)characteristic bytes:(SensorCoreKotlinByteArray *)bytes nowMs:(int64_t)nowMs __attribute__((swift_name("onPacket(sourceId:epoch:characteristic:bytes:nowMs:)")));
- (void)reset __attribute__((swift_name("reset()")));
- (NSArray<SensorCoreResolvedMetric *> *)resolveNowMs:(int64_t)nowMs __attribute__((swift_name("resolve(nowMs:)")));

/** What the device exposes (from its services); it decides its rank for each metric. */
- (void)setCapabilitiesSourceId:(NSString *)sourceId capabilities:(NSArray<SensorCoreCapability *> *)capabilities __attribute__((swift_name("setCapabilities(sourceId:capabilities:)")));
- (void)setPreferredMetric:(SensorCoreMetricType *)metric sourceId:(NSString * _Nullable)sourceId __attribute__((swift_name("setPreferred(metric:sourceId:)")));

/** The wheel circumference in metres of a cycling wheel sensor (null clears it): without it a wheel gives only revolutions. */
- (void)setWheelCircumferenceSourceId:(NSString *)sourceId metres:(SensorCoreDouble * _Nullable)metres __attribute__((swift_name("setWheelCircumference(sourceId:metres:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SensorHub.Companion")))
@interface SensorCoreSensorHubCompanion : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreSensorHubCompanion *shared __attribute__((swift_name("shared")));

/** A hub with the starting values (Swift cannot use Kotlin default arguments). */
- (SensorCoreSensorHub *)standard __attribute__((swift_name("standard()")));
@end


/**
 * The default preference between sources of one metric, from what each device really is. LOWER is better. The user's own choice
 * (`setPreferred`) always wins over it. Starting values chosen by reasoning, not measured.
 *
 *  - Heart rate: a heart rate sensor before a machine that also reports one.
 *  - Running speed, cadence, stride: a running footpod before a machine.
 *  - Cycling cadence: a power meter before a cadence sensor before a trainer. Cycling speed: a wheel sensor before a trainer.
 *  - Power: a power meter before a trainer or a rower.
 *  - Everything else: no preference (the source chosen first stays).
 */
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SourcePolicy")))
@interface SensorCoreSourcePolicy : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));

/**
 * The default preference between sources of one metric, from what each device really is. LOWER is better. The user's own choice
 * (`setPreferred`) always wins over it. Starting values chosen by reasoning, not measured.
 *
 *  - Heart rate: a heart rate sensor before a machine that also reports one.
 *  - Running speed, cadence, stride: a running footpod before a machine.
 *  - Cycling cadence: a power meter before a cadence sensor before a trainer. Cycling speed: a wheel sensor before a trainer.
 *  - Power: a power meter before a trainer or a rower.
 *  - Everything else: no preference (the source chosen first stays).
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)sourcePolicy __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreSourcePolicy *shared __attribute__((swift_name("shared")));
- (int32_t)rankMetric:(SensorCoreMetricType *)metric capabilities:(NSSet<SensorCoreCapability *> *)capabilities __attribute__((swift_name("rank(metric:capabilities:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface SensorCoreKotlinEnumCompanion : SensorCoreBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SensorCoreKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface SensorCoreKotlinArray<T> : SensorCoreBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(SensorCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<SensorCoreKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinByteArray")))
@interface SensorCoreKotlinByteArray : SensorCoreBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(SensorCoreByte *(^)(SensorCoreInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (int8_t)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (SensorCoreKotlinByteIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(int8_t)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("KotlinIterator")))
@protocol SensorCoreKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

__attribute__((swift_name("KotlinByteIterator")))
@interface SensorCoreKotlinByteIterator : SensorCoreBase <SensorCoreKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (SensorCoreByte *)next __attribute__((swift_name("next()")));
- (int8_t)nextByte __attribute__((swift_name("nextByte()")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
