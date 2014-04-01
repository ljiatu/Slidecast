//
//  PWCJpegManager.m
//  Slidecast
//
//  Created by Elliot Soloway on 4/1/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCJpegManager.h"
#import "PWCUtilities.h"
#import "CPDFDocument.h"

@interface PWCJpegManager()

@property NSString * documentsPath;

@end

@implementation PWCJpegManager

- (id) init
{
  
  _documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                        NSUserDomainMask,
                                                        YES) lastObject];
  return self;
}

- (BOOL) makeJpegFromPdfTitle:(NSString *) pdfTitle andURL:(NSURL *) URL
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  CPDFDocument * document = [[CPDFDocument alloc] initWithURL:URL];
  
  NSString *folderName = [PWCUtilities presentationTitleAtURL:URL];
  NSString *folderPath = [self.documentsPath stringByAppendingFormat:@"/%@", folderName];
  
  if ([fileManager fileExistsAtPath:folderPath])
  {
    // modify the folder name to aovid name collision
    [PWCUtilities adjustFolderName:&folderName andPath:&folderPath];
  }
  
  NSError *error = nil;
  BOOL result = [fileManager createDirectoryAtPath:folderPath
                       withIntermediateDirectories:NO
                                        attributes:nil
                                             error:&error];
  if (!result)
  {
    NSLog(@"%@", error);
    return result;
  }
  
  // test if the images have been generated
  if ([fileManager fileExistsAtPath:[folderPath stringByAppendingFormat:@"/1.jpeg"]])
  {
    // if exists, do nothing
    return YES;
  }
  else
  {
    // otherwise, generate the images
    NSError *error = nil;
    // create a jpeg file for each page of the pdf file
    for (int i = 1; i <= self.document.numberOfPages; ++i)
    {
      NSString *jpegPath = [NSString stringWithFormat:@"%@/%d.jpeg", imageDirectoryPath, i];
      // most likely we have to change the size of the images
      UIImage *image = [[self.document pageForPageNumber:i] imageWithSize:CGSizeMake(280, 220) scale:[UIScreen mainScreen].scale];
      if (![UIImageJPEGRepresentation(image, 1.0) writeToFile:jpegPath atomically:YES])
      {
        // if fail for one of the images, delete the whole directory
        if (![manager removeItemAtPath:imageDirectoryPath error:&error])
        {
          NSLog(@"%@", error);
        }
        return NO;
      }
    }
    
    return YES;
  }
  
  return YES;
}

- (NSString *) getJpegWithTitle:(NSString *) title andPage:(int) page
{
  //write function
  return @"placeholder";
}

@end
