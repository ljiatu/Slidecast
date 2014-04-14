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

@interface PWCPreviewViewController : UIViewController <PWCChromecastControllerDelegate, UIPickerViewDelegate>

@property (nonatomic) NSURL *documentURL;
@property (nonatomic) CPDFDocument *document;

@end
