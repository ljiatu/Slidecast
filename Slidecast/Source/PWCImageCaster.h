//
//  PWCImageCaster.h
//  Slidecast
//
//  Created by Jiatu Liu on 3/25/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleCast/GoogleCast.h>

@interface PWCImageCaster : NSObject

@property(nonatomic, strong) GCKDeviceScanner* deviceScanner;
@property(nonatomic, strong) GCKDeviceManager* deviceManager;
@property(nonatomic, readonly) GCKMediaInformation* mediaInformation;

@end
