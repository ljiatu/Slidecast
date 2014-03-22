//
//  NotesViewController.h
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWCNotesViewController : UIViewController

@property NSString * docTitle;
@property int pageNum;

- (void) setDocTitle:(NSString *)title;
- (IBAction)prevAction:(id)sender;
- (IBAction)nextAction:(id)sender;

@end
