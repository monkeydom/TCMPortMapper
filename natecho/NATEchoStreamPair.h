//  NATEchoStreamPair.h
//  NATEcho
//
//  Created by dom on 15.07.2020.

#import <Foundation/Foundation.h>

@protocol NATEchoStreamPairDelegate;

@interface NATEchoStreamPair : NSObject
@property (nonatomic, weak) id <NATEchoStreamPairDelegate> delegate;

- (instancetype)initWithAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;

- (void)open;
- (void)close;
@end

@protocol NATEchoStreamPairDelegate <NSObject>
@optional
- (void)echoStreamPairDidEnd:(NATEchoStreamPair *)pair;
@end
