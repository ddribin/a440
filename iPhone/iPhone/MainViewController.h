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
