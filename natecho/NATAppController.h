//  NATAppController.h
//

@import Cocoa;
#import "TCPServer.h"

@interface NATAppController : NSObject {
    IBOutlet NSTextField *O_portTextField;
    IBOutlet NSButton    *O_startStopButton;
    IBOutlet NSImageView *O_serverStatusImageView;
    IBOutlet NSTextField *O_serverStatusTextField;

    IBOutlet NSProgressIndicator *O_publicIndicator;
    IBOutlet NSImageView *O_publicStatusImageView;
    IBOutlet NSTextField *O_publicStatusTextField;
    
    TCPServer *I_server;
}

@property (nonatomic, strong) IBOutlet NSTextField *localIPv6TextField;
@property (nonatomic, strong) IBOutlet NSTextField *localIPv4TextField;

- (IBAction)startStop:(id)aSender;
- (void)start;
- (void)stop;
@end
