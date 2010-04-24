//

#import <Foundation/Foundation.h>


@protocol A440Player <NSObject>

- (BOOL)start:(NSError **)error;
- (BOOL)stop:(NSError **)error;

@end
