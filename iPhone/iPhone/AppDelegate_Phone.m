//

#import "AppDelegate_Phone.h"
#import "MainViewController.h"

@implementation AppDelegate_Phone

@synthesize window = _window;
@synthesize mainViewController = _mainViewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
	
    _mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_Phone"
                                                               bundle:[NSBundle mainBundle]];
    
    UIView * view = [_mainViewController view];
    [_window addSubview:view];
	
    [_window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc
{
    [_mainViewController release];
    [_window release];
    [super dealloc];
}

@end
