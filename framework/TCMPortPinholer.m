//  TCMPortPinholer.m
//  TCMPortMapper
//

#import "TCMPortPinholer.h"

#include "miniwget.h"
#include "miniupnpc.h"
#include "upnpcommands.h"
#include "upnperrors.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>
#import "NSNotificationCenterThreadingAdditions.h"


NSString * const TCMPortPinholerDidFailNotification = @"TCMPortPinholerDidFailNotification";
NSString * const TCMPortPinholerDidBeginWorkingNotification = @"TCMPortPinholerDidBeginWorkingNotification";
NSString * const TCMPortPinholerDidEndWorkingNotification = @"TCMPortPinholerDidendWorkingNotification";

static const char *_UPNP_PinholeCStringForProtocol(TCMPortMappingTransportProtocol protocol) {
    return (protocol==TCMPortMappingTransportProtocolUDP) ? "17" : "6";
    // See macros IPPROTO_UDP and IPPROTO_TCP
}


@interface TCMPortPinholer () {
    NSLock *_threadIsRunningLock;
    BOOL _refreshThreadShouldQuit;

    struct UPNPUrls _urls;
    struct IGDdatas _igddata;
}
@end

@implementation TCMPortPinholer

- (instancetype)init {
    self = [super init];
    if (self) {
        _threadIsRunningLock = [NSLock new];
        if ([_threadIsRunningLock respondsToSelector:@selector(setName:)])
            [_threadIsRunningLock performSelector:@selector(setName:) withObject:@"TCMPortPinholer-ThreadRunningLock"];
    }
    return self;
}

- (void)refresh {
    if ([_threadIsRunningLock tryLock]) {
        _refreshThreadShouldQuit=NO;
        [NSThread detachNewThreadSelector:@selector(refreshInThread) toTarget:self withObject:nil];
        [_threadIsRunningLock unlock];
    }
}

- (void)refreshInThread {
    [_threadIsRunningLock lock];
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMPortPinholerDidBeginWorkingNotification object:self];
        
        struct UPNPDev *devlist = 0;
        // IPv4
        // 15 "192.168.167.199"
        // IPv6
        // 39 "ABCD:ABCD:ABCD:ABCD:ABCD:ABCD:ABCD:ABCD"
        // 45 "ABCD:ABCD:ABCD:ABCD:ABCD:ABCD:192.168.158.190"
        // 35 "fe80::ec5a:d7ff:fe00:e197%enp0s51f6"
#define IPV6_MAX_STRING_LENGTH 46
        
        char lanaddr[IPV6_MAX_STRING_LENGTH];   /* my ip address on the LAN */
        char externalIPAddress[IPV6_MAX_STRING_LENGTH];
        BOOL didFail=NO;
        NSString *errorString = nil;
        int error;
        
        if (( devlist = upnpDiscover(2000, NULL, NULL, UPNP_LOCAL_PORT_ANY, 1, 2, &error) )) {
            if (devlist) {
                
                // let us check all of the devices for reachability
                BOOL foundIGDevice = NO;
                struct UPNPDev *device;
#ifdef DEBUG
                NSLog(@"List of IPv6 UPNP devices found on the network :\n");
#endif
                NSMutableArray *URLsToTry = [NSMutableArray array];
                NSMutableSet *triedURLSet = [NSMutableSet set];
                for(device = devlist; device && !foundIGDevice; device = device->pNext) {
                    NSURL *descURL = [NSURL URLWithString:[NSString stringWithUTF8String:device->descURL]];
                    SCNetworkConnectionFlags status;
                    SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithName(NULL, [[descURL host] UTF8String]);
                    if (target) {
                        Boolean success = SCNetworkReachabilityGetFlags(target, &status);
                        CFRelease(target);
#ifndef NDEBUG
                        NSLog(@"UPnP: %@ %c%c%c%c%c%c%c host:%s st:%s",
                              success ? @"YES" : @" NO",
                              (status & kSCNetworkFlagsTransientConnection)  ? 't' : '-',
                              (status & kSCNetworkFlagsReachable)            ? 'r' : '-',
                              (status & kSCNetworkFlagsConnectionRequired)   ? 'c' : '-',
                              (status & kSCNetworkFlagsConnectionAutomatic)  ? 'C' : '-',
                              (status & kSCNetworkFlagsInterventionRequired) ? 'i' : '-',
                              (status & kSCNetworkFlagsIsLocalAddress)       ? 'l' : '-',
                              (status & kSCNetworkFlagsIsDirect)             ? 'd' : '-',
                              device->descURL,
                              device->st
                              );
#endif
                        // only connect to directly reachable hosts which we haven't tried yet (if you are multihoming then you get all of the announcement twice
                        if (success && (status & kSCNetworkFlagsIsDirect)) {
                            if (![triedURLSet containsObject:descURL]) {
                                [triedURLSet addObject:descURL];
                                if ([[descURL host] isEqualToString:[[TCMPortMapper sharedInstance] routerIPAddress]]) {
                                    [URLsToTry insertObject:descURL atIndex:0];
                                } else {
                                    [URLsToTry addObject:descURL];
                                }
                            }
                        }
                    }
                }
                
                NSEnumerator *URLEnumerator = [URLsToTry objectEnumerator];
                NSURL *descURL = nil;
                while ((descURL = [URLEnumerator nextObject])) {
#ifndef NDEBUG
                    NSLog(@"UPnP: trying URL:%@",descURL);
#endif
                    // freeing the url still seems like a good idea - why isn't it?
                    if (_urls.controlURL) FreeUPNPUrls(&_urls);
                    
                    // get the new control URLs - this call mallocs the control URLs
                    if (UPNP_GetIGDFromUrl([[descURL absoluteString] UTF8String],&_urls,&_igddata,lanaddr,sizeof(lanaddr))) {
                        NSLog(@"%s Successfully got the IGD urls",__FUNCTION__);

                    } else {
                        NSLog(@"%s No IPv6 IGD for URL:%@",__FUNCTION__,descURL);
                    }
                }
                if (!foundIGDevice) {
                    didFail = YES;
                    errorString = @"No IPv6 IGD found on the network!";
                }
            } else {
                didFail = YES;
                errorString = @"No IPv6 IGD found on the network!";
            }
            freeUPNPDevlist(devlist); devlist = 0;
        } else {
            didFail = YES;
            errorString = @"No IPv6 IGD found on the network!";
        }
        [_threadIsRunningLock unlock];
        if (_refreshThreadShouldQuit) {
#ifdef DEBUG
            NSLog(@"%s thread quit prematurely",__FUNCTION__);
#endif
            [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
        } else {
            if (didFail) {
#ifdef DEBUG
                NSLog(@"%s didFailWithError: %@",__FUNCTION__, errorString);
#endif
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMPortPinholerDidFailNotification object:self]];
            } else {
                [self performSelectorOnMainThread:@selector(updatePortMappings) withObject:nil waitUntilDone:0];
            }
        }
        // the delaying bridges the small time gap between this thread and the update thread
        [self performSelectorOnMainThread:@selector(postDelayedDidEndWorkingNotification) withObject:nil waitUntilDone:NO];
    }
}


- (void)postDidEndWorkingNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortPinholerDidEndWorkingNotification object:self];
}

- (void)postDelayedDidEndWorkingNotification {
    [self performSelector:@selector(postDidEndWorkingNotification) withObject:nil afterDelay:0.5];
}

@end
