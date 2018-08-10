//  TCMSystemConfiguration.m
//  TCMPortMapper
//

#import "TCMSystemConfiguration.h"
@import SystemConfiguration;

#import <pthread.h>

@interface TCMSystemConfigurationObservation : NSObject
@property (nonatomic, strong) TCMSystemConfigurationDidChangeCallback callback;
@property (nonatomic, strong) NSArray<NSString *> *observedKeys;
@property (nonatomic, strong) NSArray<NSString *> *observedRegexes;
@end
@implementation TCMSystemConfigurationObservation
+ (instancetype)observationWithKeys:(NSArray<NSString *> *)keys regexes:(NSArray<NSString *> *)regexes callback:(TCMSystemConfigurationDidChangeCallback)callback {
    TCMSystemConfigurationObservation *result = [self.class new];
    result.observedKeys = keys ?: @[];
    result.observedRegexes = regexes ?: @[];
    result.callback = callback;
    return result;
}
@end

@interface TCMSystemConfiguration ()
@property (nonatomic) SCDynamicStoreRef dynamicStore;
@property (nonatomic) CFRunLoopSourceRef runLoopSource;

@property (nonatomic, strong) NSMutableArray<TCMSystemConfigurationObservation *> *activeObservations;
@end

static void _dynamicStoreNotificationCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

@implementation TCMSystemConfiguration

+ (instancetype)sharedConfiguration {
    static TCMSystemConfiguration *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (pthread_main_np()) {
            sharedInstance = [TCMSystemConfiguration new];
        } else {
            NSAssert(false, @"+[TCMSystemConfiguration sharedConfiguration] may not be called for the first time on a non main thread.");
        }
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        SCDynamicStoreContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
        
        _dynamicStore = SCDynamicStoreCreate(NULL,
                                             (CFStringRef)[[NSBundle mainBundle] bundleIdentifier],
                                             _dynamicStoreNotificationCallback,
                                             &context
                                             );
        _runLoopSource = SCDynamicStoreCreateRunLoopSource(NULL, _dynamicStore, 0);
        CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], _runLoopSource, kCFRunLoopCommonModes);
        CFRelease(_runLoopSource);
        
        // just observe it all for now
        SCDynamicStoreSetNotificationKeys(_dynamicStore, nil, (__bridge CFArrayRef)@[@".*"]);
        
        _activeObservations = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    CFRunLoopSourceInvalidate(_runLoopSource);
    CFRelease(_dynamicStore);
}

- (void)handleChangedKeys:(NSArray *)changedKeys {
    NSLog(@"%s %@",__FUNCTION__, changedKeys);
    for (TCMSystemConfigurationObservation *observation in _activeObservations) {
        for (NSString *key in observation.observedKeys) {
            if ([changedKeys containsObject:key]) {
                observation.callback(self, changedKeys);
            }
        }
    }
}

static void _dynamicStoreNotificationCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
    TCMSystemConfiguration *systemConfiguration = (__bridge id)info;
    [systemConfiguration handleChangedKeys:(__bridge NSArray *)changedKeys];
}

- (id)observeConfigurationKeys:(NSArray<NSString *> *)keys observationBlock:(TCMSystemConfigurationDidChangeCallback)callbackBlock {
    __auto_type observation = [TCMSystemConfigurationObservation observationWithKeys:keys regexes:nil callback:callbackBlock];
    [_activeObservations addObject:observation];
    [self updateObservationConfiguration];
    return observation;
}

- (void)removeConfigurationKeyObservation:(id)observation {
    [_activeObservations removeObject:observation];
    [self updateObservationConfiguration];
}

- (void)updateObservationConfiguration {
    NSMutableArray *keys = [NSMutableArray new];
    NSMutableArray *regexes = [NSMutableArray new];
    for (TCMSystemConfigurationObservation *observation in _activeObservations) {
        [keys addObjectsFromArray:observation.observedKeys];
        [regexes addObjectsFromArray:observation.observedRegexes];
    }
    BOOL success = SCDynamicStoreSetNotificationKeys(_dynamicStore, (__bridge CFArrayRef)keys, (__bridge CFArrayRef)regexes);
    if (!success) {
        NSLog(@"%s could not update the SCDynamicStoreObservation for %@ and %@",__FUNCTION__, keys, regexes);
    };
}

@end

