//

#import "AppDelegate_Pad.h"
#import "MainViewController.h"

@implementation AppDelegate_Pad

@synthesize window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
	
    _mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_Pad"
                                                               bundle:[NSBundle mainBundle]];
    
    UIView * view = [_mainViewController view];
    [window addSubview:view];
	
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc
{
    [_mainViewController release];
    [window release];
    [super dealloc];
}


@end
