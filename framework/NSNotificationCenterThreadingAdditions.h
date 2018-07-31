//  NSNotificationCenterThreadingAdditions
//  Enable NSNotification being sent from threads
//

@import Cocoa;

@interface NSNotificationCenter (NSNotificationCenterThreadingAdditions)
- (void)postNotificationOnMainThread:(NSNotification *)aNotification;
- (void)postNotificationOnMainThreadWithName:(NSString *)aName object:(id)anObject;
@end
