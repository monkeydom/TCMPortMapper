#import "TCPServer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

NSString * const TCPServerErrorDomain = @"TCPServerErrorDomain";

@implementation TCPServer

- (instancetype)init {
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
    // if the delegate implements the delegate method, call it  
    if ([_delegate respondsToSelector:@selector(TCPServer:didReceiveConnectionFromAddress:inputStream:outputStream:)]) {
        [_delegate TCPServer:self didReceiveConnectionFromAddress:addr inputStream:istr outputStream:ostr];
    }
}

// This function is called by CFSocket when a new connection comes in.
// We gather some data here, and convert the function call to a method
// invocation on TCPServer.
static void TCPServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    TCPServer *server = (__bridge TCPServer *)info;
    if (kCFSocketAcceptCallBack == type) { 
        // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        uint8_t name[SOCK_MAXADDRLEN];
        socklen_t namelen = sizeof(name);
        NSData *peer = nil;
        if (0 == getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen)) {
            peer = [NSData dataWithBytes:name length:namelen];
        }
        CFReadStreamRef readStream = NULL;
	CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            [server handleNewConnectionFromAddress:peer inputStream:(__bridge NSInputStream *)readStream outputStream:(__bridge NSOutputStream *)writeStream];
        } else {
            // on any failure, need to destroy the CFSocketNativeHandle 
            // since we are not going to use it any more
            close(nativeSocketHandle);
        }
        if (readStream) CFRelease(readStream);
        if (writeStream) CFRelease(writeStream);
    }
}

- (BOOL)start:(NSError **)error {
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&TCPServerAcceptCallBack, &socketCtxt);
    ipv6socket = CFSocketCreate(kCFAllocatorDefault, PF_INET6, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&TCPServerAcceptCallBack, &socketCtxt);

    if (NULL == ipv4socket || NULL == ipv6socket) {
        if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerNoSocketsAvailable userInfo:nil];
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }

    int yes = 1;
    setsockopt(CFSocketGetNative(ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
    setsockopt(CFSocketGetNative(ipv6socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
    
    // set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(_port);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];

    if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, (CFDataRef)address4)) {
        if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv4Address userInfo:nil];
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
    
    if (0 == _port) {
        // now that the binding was successful, we get the port number 
        // -- we will need it for the v6 endpoint and for the NSNetService
        NSData *addr = CFBridgingRelease(CFSocketCopyAddress(ipv4socket));
        memcpy(&addr4, [addr bytes], [addr length]);
        _port = ntohs(addr4.sin_port);
    }

    // set up the IPv6 endpoint
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(_port);
    addr6.sin6_addr = in6addr_any;
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];

    if (kCFSocketSuccess != CFSocketSetAddress(ipv6socket, (CFDataRef)address6)) {
        if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv6Address userInfo:nil];
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }

    // set up the run loop sources for the sockets
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4socket, 0);
    CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
    CFRelease(source4);

    CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv6socket, 0);
    CFRunLoopAddSource(cfrl, source6, kCFRunLoopCommonModes);
    CFRelease(source6);

    // we can only publish the service if we have a type to publish with
    if (nil != _type) {
        NSString *publishingDomain = _domain ?: @"";
        NSString *publishingName = nil;
        if (nil != _name) {
            publishingName = _name;
        } else {
            NSString * thisHostName = [[NSProcessInfo processInfo] hostName];
            if ([thisHostName hasSuffix:@".local"]) {
                publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
            }
        }
        netService = [[NSNetService alloc] initWithDomain:publishingDomain type:_type name:publishingName port:_port];
        [netService publish];
    }

    return YES;
}

- (BOOL)stop {
    [netService stop];
    netService = nil;
    if (ipv4socket) {
        CFSocketInvalidate(ipv4socket);
        CFRelease(ipv4socket);
        ipv4socket = NULL;
    }
    if (ipv6socket) {
        CFSocketInvalidate(ipv6socket);
        CFRelease(ipv6socket);
        ipv6socket = NULL;
    }
    return YES;
}

@end

