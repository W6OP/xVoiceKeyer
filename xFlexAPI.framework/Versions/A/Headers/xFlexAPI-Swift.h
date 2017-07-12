// Generated by Apple Swift version 4.0 (swiftlang-900.0.45.6 clang-900.0.26)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_attribute(external_source_symbol)
# define SWIFT_STRINGIFY(str) #str
# define SWIFT_MODULE_NAMESPACE_PUSH(module_name) _Pragma(SWIFT_STRINGIFY(clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in=module_name, generated_declaration))), apply_to=any(function, enum, objc_interface, objc_category, objc_protocol))))
# define SWIFT_MODULE_NAMESPACE_POP _Pragma("clang attribute pop")
#else
# define SWIFT_MODULE_NAMESPACE_PUSH(module_name)
# define SWIFT_MODULE_NAMESPACE_POP
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if __has_attribute(noreturn)
# define SWIFT_NORETURN __attribute__((noreturn))
#else
# define SWIFT_NORETURN
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if defined(__has_attribute) && __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR __attribute__((enum_extensibility(open)))
# else
#  define SWIFT_ENUM_ATTR
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_ATTR SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if __has_feature(attribute_diagnose_if_objc)
# define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
#else
# define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
#endif
#if __has_feature(modules)
@import ObjectiveC;
@import Foundation;
@import CoreGraphics;
#endif

#import <xFlexAPI/xFlexAPI.h>

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"

SWIFT_MODULE_NAMESPACE_PUSH("xFlexAPI")

SWIFT_CLASS("_TtC8xFlexAPI11AudioStream")
@interface AudioStream : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end

@class Slice;

@interface AudioStream (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) NSInteger rxGain;
@property (nonatomic) NSInteger daxChannel;
@property (nonatomic) NSInteger daxClients;
@property (nonatomic, readonly) BOOL inUse;
@property (nonatomic, copy) NSString * _Nonnull ip;
@property (nonatomic) NSInteger port;
@property (nonatomic, strong) Slice * _Nullable slice;
@end


SWIFT_CLASS("_TtC8xFlexAPI3Cwx")
@interface Cwx : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Cwx (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) NSInteger delay;
@property (nonatomic) BOOL qskEnabled;
@property (nonatomic) NSInteger speed;
@end


SWIFT_CLASS("_TtC8xFlexAPI9Equalizer")
@interface Equalizer : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Equalizer (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) BOOL eqEnabled;
@property (nonatomic) NSInteger level63Hz;
@property (nonatomic) NSInteger level125Hz;
@property (nonatomic) NSInteger level250Hz;
@property (nonatomic) NSInteger level500Hz;
@property (nonatomic) NSInteger level1000Hz;
@property (nonatomic) NSInteger level2000Hz;
@property (nonatomic) NSInteger level4000Hz;
@property (nonatomic) NSInteger level8000Hz;
@end


SWIFT_CLASS("_TtC8xFlexAPI8IqStream")
@interface IqStream : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface IqStream (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic, readonly) NSInteger available;
@property (nonatomic, readonly) NSInteger capacity;
@property (nonatomic) NSInteger daxIqChannel;
@property (nonatomic, copy) NSString * _Nonnull ip;
@property (nonatomic) NSInteger port;
@property (nonatomic, copy) NSString * _Nullable pan;
@property (nonatomic) NSInteger rate;
@property (nonatomic) BOOL streaming;
@end


SWIFT_CLASS("_TtC8xFlexAPI6Memory")
@interface Memory : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Memory (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) NSInteger digitalLowerOffset;
@property (nonatomic) NSInteger digitalUpperOffset;
@property (nonatomic) NSInteger filterHigh;
@property (nonatomic) NSInteger filterLow;
@property (nonatomic) NSInteger frequency;
@property (nonatomic, copy) NSString * _Nonnull group;
@property (nonatomic, copy) NSString * _Nonnull mode;
@property (nonatomic, copy) NSString * _Nonnull name;
@property (nonatomic) NSInteger offset;
@property (nonatomic, copy) NSString * _Nonnull offsetDirection;
@property (nonatomic, copy) NSString * _Nonnull owner;
@property (nonatomic) NSInteger rfPower;
@property (nonatomic) NSInteger rttyMark;
@property (nonatomic) NSInteger rttyShift;
@property (nonatomic) BOOL squelchEnabled;
@property (nonatomic) NSInteger squelchLevel;
@property (nonatomic) NSInteger step;
@property (nonatomic, copy) NSString * _Nonnull toneMode;
@property (nonatomic) NSInteger toneValue;
@end


SWIFT_CLASS("_TtC8xFlexAPI14MicAudioStream")
@interface MicAudioStream : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface MicAudioStream (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic, readonly) BOOL inUse;
@property (nonatomic, copy) NSString * _Nonnull ip;
@property (nonatomic) NSInteger port;
@property (nonatomic) NSInteger micGain;
@end




SWIFT_CLASS("_TtC8xFlexAPI4Opus")
@interface Opus : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Opus (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) BOOL remoteRxOn;
@property (nonatomic) BOOL remoteTxOn;
@property (nonatomic) BOOL rxStreamStopped;
@end


SWIFT_CLASS("_TtC8xFlexAPI10Panadapter")
@interface Panadapter : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Panadapter (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) NSInteger average;
@property (nonatomic, copy) NSString * _Nonnull band;
@property (nonatomic) NSInteger bandwidth;
@property (nonatomic) NSInteger center;
@property (nonatomic) NSInteger daxIqChannel;
@property (nonatomic) NSInteger daxIqRate;
@property (nonatomic) NSInteger fps;
@property (nonatomic) BOOL loopAEnabled;
@property (nonatomic) BOOL loopBEnabled;
@property (nonatomic) CGFloat maxDbm;
@property (nonatomic) CGFloat minDbm;
@property (nonatomic) CGSize panDimensions;
@property (nonatomic) NSInteger rfGain;
@property (nonatomic, copy) NSString * _Nonnull rxAnt;
@property (nonatomic) BOOL weightedAverageEnabled;
@property (nonatomic) BOOL wnbEnabled;
@property (nonatomic) NSInteger wnbLevel;
@property (nonatomic, copy) NSArray<NSString *> * _Nonnull antList;
@property (nonatomic) BOOL autoCenterEnabled;
@property (nonatomic, readonly) NSInteger available;
@property (nonatomic, readonly) NSInteger capacity;
@property (nonatomic, readonly) NSInteger maxBw;
@property (nonatomic, readonly) NSInteger minBw;
@property (nonatomic, copy) NSString * _Nonnull preamp;
@property (nonatomic) NSInteger rfGainHigh;
@property (nonatomic) NSInteger rfGainLow;
@property (nonatomic) NSInteger rfGainStep;
@property (nonatomic, copy) NSString * _Nonnull rfGainValues;
@property (nonatomic, readonly, copy) NSString * _Nonnull waterfallId;
@property (nonatomic) BOOL wide;
@property (nonatomic) BOOL wnbUpdating;
@property (nonatomic, copy) NSString * _Nonnull xvtrLabel;
@end


SWIFT_CLASS("_TtC8xFlexAPI5Radio")
@interface Radio : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull radioVersion;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Radio (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) BOOL accTxEnabled;
@property (nonatomic) NSInteger accTxDelay;
@property (nonatomic) BOOL accTxReqEnabled;
@property (nonatomic) BOOL accTxReqPolarity;
@property (nonatomic) BOOL apfEnabled;
@property (nonatomic) NSInteger apfQFactor;
@property (nonatomic) NSInteger apfGain;
@property (nonatomic) BOOL atuEnabled;
@property (nonatomic) BOOL atuMemoriesEnabled;
@property (nonatomic) BOOL bandPersistenceEnabled;
@property (nonatomic) BOOL binauralRxEnabled;
@property (nonatomic) NSInteger calFreq;
@property (nonatomic, copy) NSString * _Nonnull callsign;
@property (nonatomic) NSInteger carrierLevel;
@property (nonatomic) BOOL companderEnabled;
@property (nonatomic) NSInteger companderLevel;
@property (nonatomic, copy) NSString * _Nonnull currentGlobalProfile;
@property (nonatomic, copy) NSString * _Nonnull currentMicProfile;
@property (nonatomic, copy) NSString * _Nonnull currentTxProfile;
@property (nonatomic) BOOL cwAutoSpaceEnabled;
@property (nonatomic) BOOL cwBreakInEnabled;
@property (nonatomic) NSInteger cwBreakInDelay;
@property (nonatomic) BOOL cwIambicEnabled;
@property (nonatomic) NSInteger cwIambicMode;
@property (nonatomic) BOOL cwlEnabled;
@property (nonatomic) NSInteger cwPitch;
@property (nonatomic) BOOL cwSidetoneEnabled;
@property (nonatomic) BOOL cwSwapPaddles;
@property (nonatomic) BOOL cwSyncCwxEnabled;
@property (nonatomic) NSInteger cwWeight;
@property (nonatomic) NSInteger cwSpeed;
@property (nonatomic) BOOL daxEnabled;
@property (nonatomic) BOOL enforcePrivateIpEnabled;
@property (nonatomic) NSInteger filterCwAutoLevel;
@property (nonatomic) NSInteger filterVoiceAutoLevel;
@property (nonatomic) NSInteger filterCwLevel;
@property (nonatomic) NSInteger filterDigitalLevel;
@property (nonatomic) NSInteger filterVoiceLevel;
@property (nonatomic) NSInteger freqErrorPpb;
@property (nonatomic) BOOL fullDuplexEnabled;
@property (nonatomic) NSInteger headphoneGain;
@property (nonatomic) BOOL headphoneMute;
@property (nonatomic) BOOL hwAlcEnabled;
@property (nonatomic) BOOL inhibit;
@property (nonatomic) NSInteger lineoutGain;
@property (nonatomic) BOOL lineoutMute;
@property (nonatomic) NSInteger maxPowerLevel;
@property (nonatomic) BOOL metInRxEnabled;
@property (nonatomic) BOOL micBiasEnabled;
@property (nonatomic) BOOL micBoostEnabled;
@property (nonatomic) NSInteger micLevel;
@property (nonatomic, copy) NSString * _Nonnull micSelection;
@property (nonatomic) BOOL monAvailable;
@property (nonatomic) NSInteger monGainCw;
@property (nonatomic) NSInteger monGainSb;
@property (nonatomic, copy) NSString * _Nonnull nickname;
@property (nonatomic, copy) NSString * _Nonnull radioScreenSaver;
@property (nonatomic) BOOL rcaTxReqEnabled;
@property (nonatomic) BOOL rcaTxReqPolarity;
@property (nonatomic) BOOL remoteOnEnabled;
@property (nonatomic) NSInteger rfPower;
@property (nonatomic) NSInteger rttyMark;
@property (nonatomic) BOOL snapTuneEnabled;
@property (nonatomic) BOOL speechProcessorEnabled;
@property (nonatomic) NSInteger speechProcessorLevel;
@property (nonatomic) BOOL ssbPeakControlEnabled;
@property (nonatomic, copy) NSString * _Nonnull staticGateway;
@property (nonatomic, copy) NSString * _Nonnull staticIp;
@property (nonatomic, copy) NSString * _Nonnull staticNetmask;
@property (nonatomic) NSInteger timeout;
@property (nonatomic) BOOL tnfEnabled;
@property (nonatomic) BOOL tune;
@property (nonatomic) NSInteger tunePower;
@property (nonatomic) BOOL txEnabled;
@property (nonatomic) NSInteger txDelay;
@property (nonatomic) NSInteger txFilterHigh;
@property (nonatomic) NSInteger txFilterLow;
@property (nonatomic) BOOL txInWaterfallEnabled;
@property (nonatomic) BOOL tx1Enabled;
@property (nonatomic) NSInteger tx1Delay;
@property (nonatomic) BOOL tx2Enabled;
@property (nonatomic) NSInteger tx2Delay;
@property (nonatomic) BOOL tx3Enabled;
@property (nonatomic) NSInteger tx3Delay;
@property (nonatomic) BOOL voxEnabled;
@property (nonatomic) NSInteger voxDelay;
@property (nonatomic) NSInteger voxLevel;
@property (nonatomic, readonly) BOOL atuPresent;
@property (nonatomic, copy) NSString * _Nonnull atuStatus;
@property (nonatomic) BOOL atuUsingMemories;
@property (nonatomic, readonly) NSInteger availablePanadapters;
@property (nonatomic, readonly) NSInteger availableSlices;
@property (nonatomic, copy) NSString * _Nonnull chassisSerial;
@property (nonatomic, readonly) NSInteger daxIqAvailable;
@property (nonatomic, readonly) NSInteger daxIqCapacity;
@property (nonatomic) NSInteger filterDigitalAutoLevel;
@property (nonatomic, readonly, copy) NSString * _Nonnull fpgaMbVersion;
@property (nonatomic) NSInteger frequency;
@property (nonatomic, copy) NSString * _Nonnull gateway;
@property (nonatomic, copy) NSString * _Nonnull gpsAltitude;
@property (nonatomic) double gpsFrequencyError;
@property (nonatomic, copy) NSString * _Nonnull gpsStatus;
@property (nonatomic, copy) NSString * _Nonnull gpsGrid;
@property (nonatomic, copy) NSString * _Nonnull gpsLatitude;
@property (nonatomic, copy) NSString * _Nonnull gpsLongitude;
@property (nonatomic, readonly) BOOL gpsPresent;
@property (nonatomic, copy) NSString * _Nonnull gpsSpeed;
@property (nonatomic, copy) NSString * _Nonnull gpsTime;
@property (nonatomic) double gpsTrack;
@property (nonatomic) BOOL gpsTracked;
@property (nonatomic) BOOL gpsVisible;
@property (nonatomic, copy) NSString * _Nonnull ipAddress;
@property (nonatomic, copy) NSString * _Nonnull location;
@property (nonatomic, copy) NSString * _Nonnull macAddress;
@property (nonatomic) BOOL micAccEnabled;
@property (nonatomic) NSInteger monPanCw;
@property (nonatomic) NSInteger monPanSb;
@property (nonatomic, copy) NSString * _Nonnull netmask;
@property (nonatomic, readonly) NSInteger numberOfScus;
@property (nonatomic, readonly) NSInteger numberOfSlices;
@property (nonatomic, readonly) NSInteger numberOfTx;
@property (nonatomic, readonly, copy) NSString * _Nonnull psocMbPa100Version;
@property (nonatomic, readonly, copy) NSString * _Nonnull psocMbtrxVersion;
@property (nonatomic, copy) NSString * _Nonnull radioModel;
@property (nonatomic, copy) NSString * _Nonnull radioOptions;
@property (nonatomic) BOOL rawIqEnabled;
@property (nonatomic, copy) NSString * _Nonnull reason;
@property (nonatomic, copy) NSString * _Nonnull region;
@property (nonatomic) BOOL sbMonitorEnabled;
@property (nonatomic, readonly, copy) NSString * _Nonnull smartSdrMB;
@property (nonatomic, readonly, copy) NSString * _Nonnull softwareVersion;
@property (nonatomic, copy) NSString * _Nonnull source;
@property (nonatomic) BOOL startOffset;
@property (nonatomic, copy) NSString * _Nonnull state;
@property (nonatomic) BOOL txFilterChanges;
@property (nonatomic) BOOL txRfPowerChanges;
@property (nonatomic, copy) NSString * _Nonnull waveformList;
@end

@class GCDAsyncUdpSocket;

SWIFT_CLASS("_TtC8xFlexAPI12RadioFactory")
@interface RadioFactory : NSObject <GCDAsyncUdpSocketDelegate>
/// The Socket received data
/// \param sock the GCDAsyncUdpSocket
///
/// \param data the Data received
///
/// \param address the Address of the sender
///
/// \param filterContext the FilterContext
///
- (void)udpSocket:(GCDAsyncUdpSocket * _Nonnull)sock didReceiveData:(NSData * _Nonnull)data fromAddress:(NSData * _Nonnull)address withFilterContext:(id _Nullable)filterContext;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


SWIFT_CLASS("_TtC8xFlexAPI5Slice")
@interface Slice : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Slice (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) BOOL active;
@property (nonatomic, copy) NSString * _Nonnull agcMode;
@property (nonatomic) NSInteger agcOffLevel;
@property (nonatomic) NSInteger agcThreshold;
@property (nonatomic) BOOL anfEnabled;
@property (nonatomic) NSInteger anfLevel;
@property (nonatomic) BOOL apfEnabled;
@property (nonatomic) NSInteger apfLevel;
@property (nonatomic) NSInteger audioGain;
@property (nonatomic) BOOL audioMute;
@property (nonatomic) BOOL autoPanEnabled;
@property (nonatomic) NSInteger daxChannel;
@property (nonatomic) BOOL dfmPreDeEmphasisEnabled;
@property (nonatomic) NSInteger digitalLowerOffset;
@property (nonatomic) NSInteger digitalUpperOffset;
@property (nonatomic) BOOL diversityEnabled;
@property (nonatomic) NSInteger filterHigh;
@property (nonatomic) NSInteger filterLow;
@property (nonatomic) NSInteger fmDeviation;
@property (nonatomic) float fmRepeaterOffset;
@property (nonatomic) BOOL fmToneBurstEnabled;
@property (nonatomic) float fmToneFreq;
@property (nonatomic, copy) NSString * _Nonnull fmToneMode;
@property (nonatomic) NSInteger frequency;
@property (nonatomic) BOOL locked;
@property (nonatomic) BOOL loopAEnabled;
@property (nonatomic) BOOL loopBEnabled;
@property (nonatomic, copy) NSString * _Nonnull mode;
@property (nonatomic) BOOL nbEnabled;
@property (nonatomic) NSInteger nbLevel;
@property (nonatomic) BOOL nrEnabled;
@property (nonatomic) NSInteger nrLevel;
@property (nonatomic) BOOL playbackEnabled;
@property (nonatomic) BOOL recordEnabled;
@property (nonatomic, copy) NSString * _Nonnull repeaterOffsetDirection;
@property (nonatomic) NSInteger rfGain;
@property (nonatomic) BOOL ritEnabled;
@property (nonatomic) NSInteger ritOffset;
@property (nonatomic) NSInteger rttyMark;
@property (nonatomic) NSInteger rttyShift;
@property (nonatomic, copy) NSString * _Nonnull rxAnt;
@property (nonatomic) NSInteger step;
@property (nonatomic, copy) NSString * _Nonnull stepList;
@property (nonatomic) BOOL squelchEnabled;
@property (nonatomic) NSInteger squelchLevel;
@property (nonatomic, copy) NSString * _Nonnull txAnt;
@property (nonatomic) BOOL txEnabled;
@property (nonatomic) float txOffsetFreq;
@property (nonatomic) BOOL wnbEnabled;
@property (nonatomic) NSInteger wnbLevel;
@property (nonatomic) BOOL xitEnabled;
@property (nonatomic) NSInteger xitOffset;
@property (nonatomic) NSInteger audioPan;
@property (nonatomic) NSInteger daxClients;
@property (nonatomic) BOOL daxTxEnabled;
@property (nonatomic) BOOL diversityChild;
@property (nonatomic) NSInteger diversityIndex;
@property (nonatomic) BOOL diversityParent;
@property (nonatomic, readonly) BOOL inUse;
@property (nonatomic, copy) NSArray<NSString *> * _Nonnull modeList;
@property (nonatomic) NSInteger owner;
@property (nonatomic, copy) NSString * _Nonnull panadapterId;
@property (nonatomic) BOOL postDemodBypassEnabled;
@property (nonatomic) NSInteger postDemodHigh;
@property (nonatomic) NSInteger postDemodLow;
@property (nonatomic) BOOL qskEnabled;
@property (nonatomic) float recordLength;
@property (nonatomic, copy) NSArray<NSString *> * _Nonnull rxAntList;
@property (nonatomic) BOOL wide;
@end

@class GCDAsyncSocket;

SWIFT_CLASS("_TtC8xFlexAPI10TcpManager")
@interface TcpManager : NSObject <GCDAsyncSocketDelegate>
/// Called when the TCP/IP connection has been disconnected
/// \param sock the disconnected socket
///
/// \param err the error
///
- (void)socketDidDisconnect:(GCDAsyncSocket * _Nonnull)sock withError:(NSError * _Nullable)err;
/// Called after the TCP/IP connection has been established
/// \param sock the socket
///
/// \param host the host
///
/// \param port the port
///
- (void)socket:(GCDAsyncSocket * _Nonnull)sock didConnectToHost:(NSString * _Nonnull)host port:(uint16_t)port;
/// Called when data has been read from the TCP/IP connection
/// \param sock the socket data was received on
///
/// \param data the Data
///
/// \param tag the Tag associated with this receipt
///
- (void)socket:(GCDAsyncSocket * _Nonnull)sock didReadData:(NSData * _Nonnull)data withTag:(NSInteger)tag;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


SWIFT_CLASS("_TtC8xFlexAPI3Tnf")
@interface Tnf : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Tnf (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) NSInteger depth;
@property (nonatomic) NSInteger frequency;
@property (nonatomic) BOOL permanent;
@property (nonatomic) NSInteger width;
@end


SWIFT_CLASS("_TtC8xFlexAPI13TxAudioStream")
@interface TxAudioStream : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface TxAudioStream (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) BOOL transmit;
@property (nonatomic, readonly) BOOL inUse;
@property (nonatomic, copy) NSString * _Nonnull ip;
@property (nonatomic) NSInteger port;
@property (nonatomic) NSInteger txGain;
@end


SWIFT_CLASS("_TtC8xFlexAPI10UdpManager")
@interface UdpManager : NSObject <GCDAsyncUdpSocketDelegate>
/// Called when data has been read from the UDP connection
/// \param sock the receiving socket
///
/// \param data the data received
///
/// \param address the Host address
///
/// \param filterContext a filter context (if any)
///
- (void)udpSocket:(GCDAsyncUdpSocket * _Nonnull)sock didReceiveData:(NSData * _Nonnull)data fromAddress:(NSData * _Nonnull)address withFilterContext:(id _Nullable)filterContext;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


SWIFT_CLASS("_TtC8xFlexAPI8UsbCable")
@interface UsbCable : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC8xFlexAPI9Waterfall")
@interface Waterfall : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Waterfall (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) BOOL autoBlackEnabled;
@property (nonatomic) NSInteger blackLevel;
@property (nonatomic) NSInteger colorGain;
@property (nonatomic) NSInteger gradientIndex;
@property (nonatomic) NSInteger lineDuration;
@property (nonatomic, readonly) uint32_t autoBlackLevel;
@property (nonatomic, readonly, copy) NSString * _Nonnull panadapterId;
@end


SWIFT_CLASS("_TtC8xFlexAPI4Xvtr")
@interface Xvtr : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface Xvtr (SWIFT_EXTENSION(xFlexAPI))
@property (nonatomic) NSInteger ifFrequency;
@property (nonatomic) NSInteger loError;
@property (nonatomic, copy) NSString * _Nonnull name;
@property (nonatomic) NSInteger maxPower;
@property (nonatomic) NSInteger order;
@property (nonatomic) BOOL preferred;
@property (nonatomic) NSInteger rfFrequency;
@property (nonatomic) NSInteger rxGain;
@property (nonatomic) BOOL rxOnly;
@property (nonatomic, readonly) BOOL inUse;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly) NSInteger twoMeterInt;
@end

SWIFT_MODULE_NAMESPACE_POP
#pragma clang diagnostic pop