//
//  PWCUtilities.h
//  Slidecast
//
//  Created by Jiatu Liu on 3/27/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWCUtilities : NSObject

+ (NSString *)presentationTitleAtURL:(NSURL *)URL;
+ (NSString *)presentationTitleForDocumentName:(NSString *)documentName;

@end
