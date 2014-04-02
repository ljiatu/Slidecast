//
//  NotesViewController.h
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWCNotesViewController : UIViewController <UITextViewDelegate, UIGestureRecognizerDelegate>

@property NSString * docTitle;
@property NSInteger numberOfPages;

- (void)setDocTitle:(NSString *)title;
- (IBAction)prevAction:(id)sender;
- (IBAction)nextAction:(id)sender;

@end
