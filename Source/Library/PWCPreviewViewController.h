//
//  PWCPreviewController.h
//  Slidecast
//
//  Created by ljiatu on 3/15/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFDocument;
@class GCKMediaControlChannel;
@class GCKDeviceManager;
@class HTTPServer;

@interface PWCPreviewViewController : UIViewController

@property (strong, nonatomic) NSURL *documentURL;
@property (strong, nonatomic) CPDFDocument *document;

@property GCKDeviceManager *deviceManager;
@property GCKMediaControlChannel *mediaControlChannel;
@property HTTPServer *httpServer;

// for save/cancel notes to go back to preview
- (IBAction)unwindToPreview:(UIStoryboardSegue *)segue;

@end
