//
//  NotesViewController.h
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWCNotesViewController : UIViewController

@property NSString * docTitle;
@property int numberOfPages;

- (void)setDocTitle:(NSString *)title;
- (IBAction)prevAction:(id)sender;
- (IBAction)nextAction:(id)sender;

@end
