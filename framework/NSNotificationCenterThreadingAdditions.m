#import "NSNotificationCenterThreadingAdditions.h"
#import <pthread.h>

@implementation NSNotificationCenter (NSNotificationCenterThreadingAdditions)

- (void)postNotificationOnMainThread:(NSNotification *)notification {
    if (pthread_main_np()) {
        return [self postNotification:notification];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postNotification:notification];
        });
    }
}

- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object {
    [self postNotificationOnMainThread:[NSNotification notificationWithName:name object:object]];
}

@end
