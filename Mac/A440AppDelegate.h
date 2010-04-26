//

#import <Cocoa/Cocoa.h>

@protocol A440Player;


@interface A440AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow * _window;
    NSButton * _startStopButton;
    NSMatrix * _playerTypeMatrix;
    id<A440Player> _player;
}

@property (assign) IBOutlet NSWindow * window;
@property (assign) IBOutlet NSButton * startStopButton;
@property (assign) IBOutlet NSMatrix * playerTypeMatrix;

- (IBAction)playStop:(id)sender;

@end
