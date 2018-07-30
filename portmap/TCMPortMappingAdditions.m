#import "TCMPortMappingAdditions.h"

@implementation TCMPortMapping (TCMPortMappingAdditions)

+ (TCMPortMapping *)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithLocalPort:[[aDictionary objectForKey:@"privatePort"] intValue] desiredExternalPort:[[aDictionary objectForKey:@"desiredPublicPort"] intValue] transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:[aDictionary objectForKey:@"userInfo"]];
    [mapping setTransportProtocol:[[aDictionary objectForKey:@"transportProtocol"] intValue]];
    return mapping;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
             @"userInfo": [self userInfo],
             @"privatePort" : @(_localPort) ,
             @"desiredPublicPort" : @(_desiredExternalPort),
             @"transportProtocol" : @(_transportProtocol),
             };
}

@end
