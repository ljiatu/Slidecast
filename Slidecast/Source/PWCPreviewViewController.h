//
//  PWCPreviewController.h
//  Slidecast
//
//  Created by ljiatu on 3/15/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PWCChromecastDeviceController.h"

@class CPDFDocument;

@interface PWCPreviewViewController : UIViewController <PWCChromecastControllerDelegate>

@property (nonatomic) NSURL *documentURL;
@property (nonatomic) CPDFDocument *document;
@property (nonatomic) BOOL timerOn;
@property (nonatomic) NSTimeInterval countDownDuration;

@end
