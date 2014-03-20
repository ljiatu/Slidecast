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

@interface PWCPreviewViewController : UIViewController

@property (strong, nonatomic) NSURL *documentURL;
@property (strong, nonatomic) CPDFDocument *document;

@property GCKDeviceManager *deviceManager;
@property GCKMediaControlChannel *mediaControlChannel;

@end
