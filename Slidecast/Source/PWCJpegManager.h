//
//  PWCJpegManager.h
//  Slidecast
//
//  Created by Elliot Soloway on 4/1/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWCJpegManager : NSObject

- (id) init;
- (void) makeJpegWithPdfTitle:(NSString *) pdfTitle;
- (NSString *) getJpegWithPdfTitle:(NSString *) pdfTitle andPage:(int) page;

@end
