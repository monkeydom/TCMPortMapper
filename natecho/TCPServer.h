#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

extern NSString * const TCPServerErrorDomain;

@protocol TCPServerDelegate;

typedef enum {
    kTCPServerCouldNotBindToIPv4Address = 1,
    kTCPServerCouldNotBindToIPv6Address = 2,
    kTCPServerNoSocketsAvailable = 3,
} TCPServerErrorCode;

@interface TCPServer : NSObject {
@private
    CFSocketRef ipv4socket;
    CFSocketRef ipv6socket;
    NSNetService *netService;
}

@property (nonatomic, weak) id <TCPServerDelegate> delegate;
@property (nonatomic, copy) NSString *domain;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic) uint16_t port;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
// called when a new connection comes in; by default, informs the delegate

@end

@protocol TCPServerDelegate <NSObject>
- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
// if the delegate implements this method, it is called when a new  
// connection comes in; a subclass may, of course, change that behavior
@end

