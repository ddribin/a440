//
//  MainViewController.m
//  A440
//
//  Created by Dave Dribin on 4/22/10.
//  Copyright 2010 Bit Maki, Inc. All rights reserved.
//

#import "MainViewController.h"
#import "A440Player.h"
#import "A440AudioQueue.h"
#import "A440AUGraph.h"

@interface MainViewController ()
- (void)start;
- (void)stop;
@end

@implementation MainViewController

#if 0
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self == nil) {
        return nil;
    }
    
    return self;
}
#endif

- (void)dealloc
{
    [_player release];
    [super dealloc];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)startStop:(id)sender;
{
    UISwitch * playerSwitch = sender;
    if (playerSwitch.on) {
        [self start];
    } else {
        [self stop];
    }
}

- (void)start;
{
    Class playerClass = [A440AudioQueue class];
    _player = [[playerClass alloc] init];
    NSLog(@"Player: %@", _player);
    
    NSError * error = nil;
    if (![_player start:&error]) {
        // [self presentError:error];
        [_player release];
        _player = nil;
        return;
    }
}

- (void)stop;
{
    NSError * error = nil;
    if (![_player stop:&error]) {
        // [self presentError:error];
        return;
    }
    
    [_player release];
    _player = nil;
}

@end
