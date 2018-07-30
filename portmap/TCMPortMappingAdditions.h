//  TCMPortMappingAdditions.h
//

@import Cocoa;
#import <TCMPortMapper/TCMPortMapper.h>

@interface TCMPortMapping (TCMPortMappingAdditions)
+ (TCMPortMapping *)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary;
@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;
@end
