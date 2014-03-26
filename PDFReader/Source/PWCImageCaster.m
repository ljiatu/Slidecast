//
//  PWCImageCaster.m
//  Slidecast
//
//  Created by Jiatu Liu on 3/25/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCImageCaster.h"

#import "CLibraryViewController.h"

static NSString *const kReceiverAppID = @"2CFA780B";

@interface PWCImageCaster ()

@property UIImage *btnImage;
@property UIImage *btnImageSelected;

@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property GCKMediaControlChannel *mediaControlChannel;

@property CLibraryViewController *libraryViewController;

@end

@implementation PWCImageCaster

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // initialize device scanner
    self.deviceScanner = [[GCKDeviceScanner alloc] init];
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
}

@end
