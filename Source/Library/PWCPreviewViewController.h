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

@property (strong, nonatomic) NSURL *documentURL;
@property (strong, nonatomic) CPDFDocument *document;

// for save/cancel notes to go back to preview
- (IBAction)unwindToPreview:(UIStoryboardSegue *)segue;

@end
