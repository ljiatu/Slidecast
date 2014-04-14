//
//  PWCTimerSettingsViewController.m
//  Slidecast
//
//  Created by Jiatu Liu on 4/14/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCTimerSettingsViewController.h"

#import "PWCPreviewViewController.h"

@interface PWCTimerSettingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *timerSwitch;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end

@implementation PWCTimerSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // adjust the switch state
    self.timerSwitch.on = self.timerIsInitiallyOn;
    
    // set up date picker
    self.durationLabel.hidden = !self.timerIsInitiallyOn;
    self.datePicker.hidden = !self.timerIsInitiallyOn;
    self.datePicker.countDownDuration = self.countDownDuration;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)switchValueChanged:(UISwitch *)timerSwitch
{
    if (self.timerSwitch.on) {
        [UIView animateWithDuration:1.0 animations:^{
            self.durationLabel.hidden = NO;
            self.datePicker.hidden = NO;
        }];
    } else {
        [UIView animateWithDuration:1.0 animations:^{
            self.durationLabel.hidden = YES;
            self.datePicker.hidden = YES;
        }];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"timerUnwindSegue"]) {
        PWCPreviewViewController *destination = (PWCPreviewViewController *)segue.destinationViewController;
        destination.timerOn = self.timerSwitch.on;
        if (self.timerSwitch.on) {
            destination.countDownDuration = self.datePicker.countDownDuration;
        }
    }
}

@end
