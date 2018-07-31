//  TCMNATPMPPortMapper.h
//  Encapsulates libnatpmp, listens for router changes
//

#import "TCMPortMapper.h"

#import "natpmp.h"

extern NSString * const TCMNATPMPPortMapperDidFailNotification;
extern NSString * const TCMNATPMPPortMapperDidGetExternalIPAddressNotification;
extern NSString * const TCMNATPMPPortMapperDidBeginWorkingNotification;
extern NSString * const TCMNATPMPPortMapperDidEndWorkingNotification  ;
extern NSString * const TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification;

typedef enum {
    TCMExternalIPThreadID = 0,
    TCMUpdatingMappingThreadID = 1,
} TCMPortMappingThreadID;

@interface TCMNATPMPPortMapper : NSObject {
    NSLock *natPMPThreadIsRunningLock;
    int IPAddressThreadShouldQuitAndRestart;
    BOOL UpdatePortMappingsThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldRestart;
    TCMPortMappingThreadID runningThreadID;
    NSTimer *_updateTimer;
    NSTimeInterval _updateInterval;
    NSString *_lastExternalIPSenderAddress;
    NSString *_lastBroadcastedExternalIP;
    CFSocketRef _externalAddressChangeListeningSocket;
}

- (void)refresh;
- (void)stop;
- (void)updatePortMappings;
- (void)stopBlocking;

- (void)ensureListeningToExternalIPAddressChanges;
- (void)stopListeningToExternalIPAddressChanges;

@end
