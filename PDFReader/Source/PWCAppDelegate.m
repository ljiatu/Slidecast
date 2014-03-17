//
//  PWCAppDelegate.m
//
//  Created by Jonathan Wight on 02/19/11.
//  Modified by Jiatu Liu to be used in Slidecast.
//  Copyright 2012 Jonathan Wight. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of Jonathan Wight.

#import "PWCAppDelegate.h"
#import "CPDFDocument.h"
#import "CPDFPage.h"

@implementation PWCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url isFileURL])
    {
        NSString *theDocumentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        
        NSURL *theDestinationURL = [[NSURL fileURLWithPath:theDocumentsPath] URLByAppendingPathComponent:[url lastPathComponent]];
        
        NSError *theError = NULL;
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL theResult = [manager moveItemAtURL:url toURL:theDestinationURL error:&theError];
        if (theResult == YES)
        {
            NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionary];
            if (theDestinationURL != NULL)
            {
                theUserInfo[@"URL"] = theDestinationURL;
            }
            if (sourceApplication != NULL)
            {
                theUserInfo[@"sourceApplication"] = sourceApplication;
            }
            if (annotation != NULL)
            {
                theUserInfo[@"annotation"] = annotation;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidOpenURL" object:application userInfo:theUserInfo];
            
            CPDFDocument *document = [[CPDFDocument alloc] initWithURL:theDestinationURL];
            NSString *folderName = [NSString stringWithFormat:@"/%@", document.title];
            
            // create new folder
            NSString *newFolderName = [theDocumentsPath stringByAppendingString:folderName];
            [manager createDirectoryAtPath:newFolderName withIntermediateDirectories:NO attributes:nil error:&theError];
            
            // create a jpeg file for each page of the pdf file
            for (int i = 0; i < document.numberOfPages; ++i) {
                NSString *jpegPath = [NSString stringWithFormat:@"%@/%d.jpg", newFolderName, i];
                [UIImageJPEGRepresentation([[document pageForPageNumber:i] image], 1.0) writeToFile:jpegPath atomically:YES];
            }
        }
        
        return theResult;
    }
    return NO;
}

@end
