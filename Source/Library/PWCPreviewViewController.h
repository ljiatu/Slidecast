//
//  PWCPreviewController.h
//  Slidecast
//
//  Created by ljiatu on 3/15/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFDocument;

@interface PWCPreviewViewController : UIViewController

@property (strong, nonatomic) NSURL *documentURL;
@property (strong, nonatomic) CPDFDocument *document;

@end
