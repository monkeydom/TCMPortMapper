//  NATEchoStreamPair.m
//  NATEcho
//
//  Created by dom on 15.07.2020.

#import "NATEchoStreamPair.h"

@interface NATEchoStreamPair () <NSStreamDelegate>
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSData *address;
@property (nonatomic, strong) NSMutableData *bufferedData;
@end

@implementation NATEchoStreamPair

- (instancetype)initWithAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
    self = [super init];
    if (self) {
        self.address = addr;
        self.inputStream = istr;
        self.outputStream = ostr;
    }
    return self;
}

- (void)open {
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
    _bufferedData = [NSMutableData new];
    [_outputStream open];
    [_inputStream open];
}

- (void)close {
    _inputStream.delegate = nil;
    [_inputStream close];
    _outputStream.delegate = nil;
    [_outputStream close];
    if ([_delegate respondsToSelector:@selector(echoStreamPairDidEnd:)]) {
        [_delegate echoStreamPairDidEnd:self];
    }
}


- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
    if (stream == _inputStream) {
        switch (event) {
            case NSStreamEventHasBytesAvailable:
                if (_inputStream.hasBytesAvailable) {
                    unsigned char buffer[4097];
                    int length = [_inputStream read:buffer maxLength:4096];
                    if (length) {
                        [_bufferedData appendBytes:buffer length:length];
                    }
                    if (_bufferedData.length) {
                        NSLog(@"%s, has buffer:\n%@",__FUNCTION__,
                              [[NSString alloc] initWithData:_bufferedData encoding:NSISOLatin2StringEncoding]);
                    }
                    
                    [self tryToSendBuffer];
                }
                break;
            case NSStreamEventEndEncountered:
                if (_bufferedData.length == 0) {
                    [self close];
                }
                break;
            default:
                break;
        }
    } else if (stream == _outputStream) {
        switch(event) {
            case NSStreamEventHasSpaceAvailable:
                [self tryToSendBuffer];
                break;
            case NSStreamEventEndEncountered:
                [self close];
                break;
            default:
                break;
        }
    }
}

- (void)tryToSendBuffer {
    if (_bufferedData.length > 0) {
        if (_outputStream.hasSpaceAvailable) {
            NSInteger lengthSent = [_outputStream write:_bufferedData.bytes maxLength:_bufferedData.length];
            if (lengthSent < 0) {
                [self close];
            } else {
                // truncate
                _bufferedData = [[_bufferedData subdataWithRange:NSMakeRange(lengthSent, _bufferedData.length - lengthSent)] mutableCopy];
            }
        }
    }
}

@end
