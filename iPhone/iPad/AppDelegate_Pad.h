//

#import <UIKit/UIKit.h>

@class  MainViewController;

@interface AppDelegate_Pad : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController * _mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

