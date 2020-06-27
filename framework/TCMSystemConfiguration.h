//  TCMSystemConfiguration.h
//  TCMPortMapper
//

@import Foundation;

@class TCMSystemConfiguration;

NS_ASSUME_NONNULL_BEGIN
typedef void (^TCMSystemConfigurationDidChangeCallback)(TCMSystemConfiguration *config, NSArray<NSString *> *changedKeys);

@interface TCMSystemConfiguration : NSObject
+ (instancetype)sharedConfiguration;

- (id)observeConfigurationKeys:(NSArray<NSString *> *)keys observationBlock:(TCMSystemConfigurationDidChangeCallback)callbackBlock;
- (void)removeConfigurationKeyObservation:(id)observation;

@end
NS_ASSUME_NONNULL_END
