//
//  MainViewController.h
//  A440
//
//  Created by Dave Dribin on 4/22/10.
//  Copyright 2010 Bit Maki, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol A440Player;


@interface MainViewController : UIViewController
{
    id<A440Player> _player;
}

- (IBAction)startStop:(id)sender;


@end
