//
//  PWCChromecastDeviceController.m
//  Slidecast
//
//  Created by Jiatu Liu on 3/31/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCChromecastDeviceController.h"

#import <Googlecast/Googlecast.h>

/**
 * The delegate to ChromecastDeviceController. Allows responsding to device and
 * media states and reflecting that in the UI.
 */
@protocol PWCChromecastControllerDelegate <NSObject>

@optional

/**
 * Called when chromecast devices are discoverd on the network.
 */
- (void)didDiscoverDeviceOnNetwork;

/**
 * Called when connection to the device was established.
 *
 * @param device The device to which the connection was established.
 */
- (void)didConnectToDevice:(GCKDevice*)device;

/**
 * Called when connection to the device was closed.
 */
- (void)didDisconnect;

/**
 * Called when the playback state of media on the device changes.
 */
- (void)didReceiveMediaStateChange;

/**
 * Called to display the modal device view controller from the cast icon.
 */
- (void)shouldDisplayModalDeviceController;

/**
 * Called to display the remote media playback view controller.
 */
- (void)shouldPresentPlaybackController;

@end

@implementation PWCChromecastDeviceController

@end
