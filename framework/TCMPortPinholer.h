//  TCMPortPinholer.h
//  TCMPortMapper
//

#import "TCMPortMapper.h"

extern NSString * const TCMPortPinholerDidFailNotification;
extern NSString * const TCMPortPinholerDidBeginWorkingNotification;
extern NSString * const TCMPortPinholerDidEndWorkingNotification;

@interface TCMPortPinholer : NSObject

- (void)refresh;

@end
