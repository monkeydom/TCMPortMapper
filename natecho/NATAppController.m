#import "NATAppController.h"
#import <TCMPortMapper/TCMPortMapper.h>
#import "NATEchoStreamPair.h"

@interface NATAppController () <NATEchoStreamPairDelegate>
@property (nonatomic, strong) NSMutableArray<NATEchoStreamPair *> *activeEchoStreams;
@end

@implementation NATAppController

- (void)portMapperDidStartWork:(NSNotification *)aNotification {
    NSLog(@"%s",__FUNCTION__);
    [O_publicIndicator startAnimation:self];
    [O_publicStatusImageView setHidden:YES];
    [O_publicStatusTextField setStringValue:NSLocalizedString(@"Checking port status...",@"Status of port mapping while trying")];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
    NSLog(@"%s",__FUNCTION__);
    [O_publicIndicator stopAnimation:self];
    
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    // since we only have one mapping this is fine
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        [O_publicStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [O_publicStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"telnet %@ %d",@"Public echo server availability string"), [pm externalIPAddress],[mapping externalPort]]];
    } else {
        [O_publicStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
        [O_publicStatusTextField setStringValue:NSLocalizedString(@"No public mapping.",@"Connection Browser Display when not reachable")];
    }
    [O_publicStatusImageView setHidden:NO];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidStartWork:) name:TCMPortMapperDidStartWorkNotification object:pm];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:pm];
    // this is if this code goes elswhere where we may have already started searching for a mapping
    if ([pm isAtWork]) {
        [self portMapperDidStartWork:nil];
    } else {
        [self portMapperDidFinishWork:nil];
    }
    
    self.activeEchoStreams = [NSMutableArray new];
    
    I_server = [TCPServer new];
    [I_server setType:@"_echo._tcp."];
    [I_server setName:@"NATEcho"];
    [I_server setDelegate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [I_server stop];
    [[self.activeEchoStreams copy] makeObjectsPerformSelector:@selector(close)];
    // this is needed so we don't leave stale mappings on quit in case of upnp
    [[TCMPortMapper sharedInstance] stopBlocking];
}

- (void)start {
    int port = [O_portTextField intValue];
    [I_server setPort:port];
    NSError *error = nil;
    if ([I_server start:&error]) {
        [O_serverStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [O_serverStatusTextField setStringValue:@"Running"];
        
        TCMPortMapper *pm = [TCMPortMapper sharedInstance];
        
        [self.localIPv4TextField setStringValue:[NSString stringWithFormat:@"telnet %@ %d",pm.localIPAddress,port]];
        [self.localIPv6TextField setStringValue:[NSString stringWithFormat:@"telnet %@ %d",pm.securedIPv6Address,port]];
        
        // because the port is an option we need to add a new port mapping each time
        // and remove it afterwards. if it was fixed we could add the port mapping in preparation
        // and just start or stop the port mapper
        [pm addPortMapping:[TCMPortMapping portMappingWithLocalPort:port desiredExternalPort:port transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:nil]];
        [pm start];
    } else {
        NSLog(@"%s %@",__FUNCTION__,error);
    }
}

- (void)stop {
    [I_server stop];
    [O_serverStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    [O_serverStatusTextField setStringValue:@"Stopped"];
    
    NSString *notRunning = @"Not running";
    self.localIPv6TextField.stringValue = notRunning;
    self.localIPv4TextField.stringValue = notRunning;
    
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    // we know that we just added one port mapping so let us remove it
    [pm removePortMapping:[[pm portMappings] anyObject]];
    // stop also stops the current mappings, but it stores the mappings
    // so you could start again and get the same mappings
    [pm stop];
    
}

- (IBAction)startStop:(id)aSender {
    if ([O_portTextField isEnabled]) {
        [O_portTextField setEnabled:NO];
        [O_startStopButton setTitle:@"Stop"];
        [self start];
    } else {
        [O_portTextField setEnabled:YES];
        [O_startStopButton setTitle:@"Start"];
        [self stop];
    }
}

// the code below is bad unfinished network code which barely suffices for the echo example, but leaks and does other weird stuff

- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
    NATEchoStreamPair *pair = [[NATEchoStreamPair alloc] initWithAddress:addr inputStream:istr outputStream:ostr];
    pair.delegate = self;
    [self.activeEchoStreams addObject:pair];
    [pair open];
}


- (void)echoStreamPairDidEnd:(NATEchoStreamPair *)pair {
    [self.activeEchoStreams removeObject:pair];
}
@end