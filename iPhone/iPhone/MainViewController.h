//
//  MainViewController.h
//  A440
//
//  Created by Dave Dribin on 4/22/10.
//  Copyright 2010 Bit Maki, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol A440Player;


@interface MainViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
{
    id<A440Player> _player;
    UIPickerView * _playerTypePicker;
}

@property (nonatomic, retain) IBOutlet UIPickerView * playerTypePicker;

- (IBAction)startStop:(id)sender;

@end
