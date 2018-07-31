#import "TCMPortMappingAdditions.h"

@implementation TCMPortMapping (TCMPortMappingAdditions)

+ (TCMPortMapping *)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithLocalPort:[[aDictionary objectForKey:@"privatePort"] intValue] desiredExternalPort:[[aDictionary objectForKey:@"desiredPublicPort"] intValue] transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:[(NSDictionary *)[aDictionary objectForKey:@"userInfo"] mutableCopy]];
    [mapping setTransportProtocol:[[aDictionary objectForKey:@"transportProtocol"] intValue]];
    return mapping;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
             @"userInfo": [self userInfo],
             @"privatePort" : @(self.localPort) ,
             @"desiredPublicPort" : @(self.desiredExternalPort),
             @"transportProtocol" : @(self.transportProtocol),
             };
}

@end
