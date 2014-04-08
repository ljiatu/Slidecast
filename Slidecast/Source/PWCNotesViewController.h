//
//  NotesViewController.h
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWCNotesViewController : UIViewController <UIPageViewControllerDelegate,
                                                      UIPageViewControllerDataSource>

@property NSString * docTitle;
@property NSInteger numberOfPages;

@end
