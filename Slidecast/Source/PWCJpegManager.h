//
//  PWCJpegManager.h
//  Slidecast
//
//  Created by Mohammad Asgari on 4/1/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWCJpegManager : NSObject

- (id) init;
- (BOOL) makeJpegFromPdfTitle:(NSString *) pdfTitle andURL:(NSURL *) URL;
- (NSString *) getJpegPathWithTitle:(NSString *) title andPage:(int) page;

@end
