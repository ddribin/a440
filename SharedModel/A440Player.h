//

#import <Foundation/Foundation.h>


@protocol A440Player <NSObject>

- (BOOL)play:(NSError **)error;
- (BOOL)stop:(NSError **)error;

@end
