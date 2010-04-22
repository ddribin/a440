//

#import "A440AppDelegate.h"
#import "A440AudioQueue.h"
#import "A440AUGraph.h"

@interface A440AppDelegate ()
- (void)start;
- (void)stop;
- (BOOL)presentError:(NSError *)error;
@end

Class sRowToClass[2];

@implementation A440AppDelegate

@synthesize window = _window;
@synthesize startStopButton = _startStopButton;
@synthesize playerTypeMatrix = _playerTypeMatrix;

+ (void)initialize
{
    if (self != [A440AppDelegate class]) {
        return;
    }
    
    sRowToClass[0] = [A440AudioQueue class];
    sRowToClass[1] = [A440AUGraph class];
}

- (void)dealloc
{
    [_player release];
    [super dealloc];
}

- (IBAction)startStop:(id)sender;
{
    if (_player == nil) {
        [self start];
    } else {
        [self stop];
    }
}

- (void)start;
{
    NSUInteger row = [_playerTypeMatrix selectedRow];
    Class playerClass = sRowToClass[row];
    _player = [[playerClass alloc] init];
    NSLog(@"Player: %@", _player);
    
    NSError * error = nil;
    if (![_player start:&error]) {
        [self presentError:error];
        [_player release];
        _player = nil;
        return;
    }
    
    [_startStopButton setTitle:@"Stop"];
    [_playerTypeMatrix setEnabled:NO];
}

- (void)stop;
{
    NSError * error = nil;
    if (![_player stop:&error]) {
        [self presentError:error];
        return;
    }
    
    [_player release];
    _player = nil;
    [_startStopButton setTitle:@"Start"];
    [_playerTypeMatrix setEnabled:YES];
}

- (BOOL)presentError:(NSError *)error;
{
    NSLog(@"error: %@ %@", error, [error userInfo]);
    [NSApp presentError:error];
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return YES;
}

@end
