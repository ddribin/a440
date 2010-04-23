//

#import <UIKit/UIKit.h>

@class  MainViewController;

@interface AppDelegate_Phone : NSObject <UIApplicationDelegate>
{
    UIWindow * _window;
    MainViewController * _mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow * window;
@property (nonatomic, retain) MainViewController * mainViewController;

@end

