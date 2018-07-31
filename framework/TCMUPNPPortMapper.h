//  TCMUPNPPortMapper.h
//  Encapsulates miniupnp framework
//

#import "TCMPortMapper.h"
#import "TCMNATPMPPortMapper.h"
#include "miniwget.h"
#include "miniupnpc.h"
#include "upnpcommands.h"
#include "upnperrors.h"

extern NSString * const TCMUPNPPortMapperDidFailNotification;
extern NSString * const TCMUPNPPortMapperDidGetExternalIPAddressNotification;
extern NSString * const TCMUPNPPortMapperDidBeginWorkingNotification;
extern NSString * const TCMUPNPPortMapperDidEndWorkingNotification;

@interface TCMUPNPPortMapper : NSObject {
    NSLock *_threadIsRunningLock;
    BOOL refreshThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldRestart;
    TCMPortMappingThreadID runningThreadID;
    struct UPNPUrls _urls;
    struct IGDdatas _igddata;
}

@property (atomic, strong) NSArray *latestUPNPPortMappingsList;

- (void)refresh;
- (void)updatePortMappings;
- (void)stop;
- (void)stopBlocking;
- (NSArray *)latestUPNPPortMappingsList;

@end
