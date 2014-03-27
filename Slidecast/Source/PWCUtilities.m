//
//  PWCUtilities.m
//  Slidecast
//
//  Created by Jiatu Liu on 3/27/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCUtilities.h"

@implementation PWCUtilities

+ (NSString *)presentationTitleAtURL:(NSURL *)URL
{
    NSString *documentName = [URL lastPathComponent];
    return [self presentationTitleForDocumentName:documentName];
}

+ (NSString *)presentationTitleForDocumentName:(NSString *)documentName
{
    if ([documentName rangeOfString:@"."].location != NSNotFound) {
        // if title contains the suffix ".pdf" or ".ppt", get rid of the suffix
        return [[documentName componentsSeparatedByString:@"."] objectAtIndex:0];
    } else {
        return documentName;
    }
}

@end
