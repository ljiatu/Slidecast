//
//  PWCChromecastDeviceController.h
//  Slidecast
//
//  Created by Jiatu Liu on 3/31/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GoogleCast/GoogleCast.h>

/**
 * The delegate to PWCChromecastDeviceController. Allows responsding to device and
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
- (void)didConnectToDevice:(GCKDevice *)device;

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

@end

@interface PWCChromecastDeviceController : NSObject <GCKDeviceScannerListener,
                                                     GCKDeviceManagerDelegate,
                                                     GCKMediaControlChannelDelegate>

/** The device scanner used to detect devices on the network. */
@property (nonatomic, strong) GCKDeviceScanner *deviceScanner;

/** The device manager used to manage conencted chromecast device. */
@property (nonatomic, strong) GCKDeviceManager *deviceManager;

/** Get the friendly name of the device. */
@property (readonly, getter=getDeviceName) NSString *deviceName;

/** The media player state of the media on the device. */
@property (nonatomic, readonly) GCKMediaPlayerState playerState;

/** The media information of the loaded media on the device. */
@property (nonatomic, readonly) GCKMediaInformation *mediaInformation;

/** The UIBarButtonItem denoting the chromecast device. */
@property (nonatomic, readonly) UIBarButtonItem *chromecastBarButton;

/** The delegate attached to this controller. */
@property (nonatomic, weak) id<PWCChromecastControllerDelegate> delegate;

/** Update the toolbar representing the playback state of media on the device. */
//- (void)updateToolbarForViewController:(UIViewController *)viewController;

/** Perform a device scan to discover devices on the network. */
- (void)performScan:(BOOL)start;

/** Connect to a specific Chromecast device. */
- (void)connectToDevice:(GCKDevice *)device;

/** Disconnect from a Chromecast device. */
- (void)disconnectFromDevice;

/** Load a media on the device. */
- (BOOL)loadMedia:(NSString *)imageWebPath;

/** Returns true if connected to a Chromecast device. */
- (BOOL)isConnected;

/** Returns true if media is loaded on the device. */
- (BOOL)isPlayingMedia;

/** Request an update of media playback stats from the Chromecast device. */
- (void)updateStatsFromDevice;

/** Stops the media playing on the Chromecast device. */
- (void)stopCastMedia;

@end
