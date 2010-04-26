//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol A440Player;


@interface MainViewController : UIViewController
    <UIPickerViewDataSource, UIPickerViewDelegate, AVAudioSessionDelegate>
{
    id<A440Player> _player;
    UIPickerView * _playerTypePicker;
    BOOL _playOnEndInterruption;
}

@property (nonatomic, retain) IBOutlet UIPickerView * playerTypePicker;

- (IBAction)playStop:(id)sender;

@end
