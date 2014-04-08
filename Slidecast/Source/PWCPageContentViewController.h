//
//  PWCPageContentViewController.h
//  Slidecast
//
//  Created by Jiatu Liu on 4/7/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PWCNotes;

@interface PWCPageContentViewController : UIViewController <UITextViewDelegate>

@property NSUInteger index;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (void)dismissKeyboard;

@end
