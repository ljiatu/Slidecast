//
//  PWCAppDelegate.m
//  Slidecast
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

#import "PWCUtilities.h"

@implementation PWCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)URL sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([URL isFileURL])
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *folderName = [PWCUtilities presentationTitleAtURL:URL];
        NSString *folderPath = [documentsPath stringByAppendingFormat:@"/%@", folderName];
        
        if ([fileManager fileExistsAtPath:folderPath]) {
            // modify the folder name to aovid name collision
            [PWCUtilities adjustFolderName:&folderName andPath:&folderPath];
        }
        
        // create a folder to hold the document
        NSError *error = nil;
        BOOL result = [fileManager createDirectoryAtPath:folderPath
                             withIntermediateDirectories:NO
                                              attributes:nil
                                                   error:&error];
        if (!result) {
            NSLog(@"%@", error);
            return result;
        }
        
        // move the document to the folder
        NSURL *destinationURL = [[NSURL fileURLWithPath:documentsPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.pdf", folderName, folderName]];
        result = [fileManager moveItemAtURL:URL toURL:destinationURL error:&error];
        if (result)
        {
            NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionary];
            if (destinationURL != NULL)
            {
                theUserInfo[@"URL"] = destinationURL;
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
        } else {
            NSLog(@"%@", error);
        }
        
        return result;
    }

    return NO;
}

@end
