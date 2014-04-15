//
//  PWCChromecastDeviceController.m
//  Slidecast
//
//  Created by Jiatu Liu on 3/31/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCChromecastDeviceController.h"

static NSString *const kReceiverAppID = @"2CFA780B";

@interface PWCChromecastDeviceController ()

@property (nonatomic) UIImage *btnImage;
@property (nonatomic) UIImage *btnImageConnected;

@property (nonatomic) GCKMediaControlChannel *mediaControlChannel;
@property (nonatomic) GCKApplicationMetadata *applicationMetadata;
@property (nonatomic) GCKDevice *selectedDevice;

@end

@implementation PWCChromecastDeviceController

- (id)init
{
    self = [super init];
    if (self) {
        // Initialize device scanner
        self.deviceScanner = [[GCKDeviceScanner alloc] init];
        
        // Initialize UI controls for navigation bar and tool bar.
        [self initControls];
    }
    
    return self;
}

- (BOOL)isConnected
{
    return self.deviceManager.isConnected;
}

- (BOOL)isPlayingMedia
{
    return self.deviceManager.isConnected && self.mediaControlChannel &&
    self.mediaControlChannel.mediaStatus && (self.playerState == GCKMediaPlayerStatePlaying ||
                                             self.playerState == GCKMediaPlayerStatePaused ||
                                             self.playerState == GCKMediaPlayerStateBuffering);
}

- (void)performScan:(BOOL)start
{
    if (start) {
        [self.deviceScanner addListener:self];
        [self.deviceScanner startScan];
    } else {
        [self.deviceScanner stopScan];
        [self.deviceScanner removeListener:self];
    }
}

- (void)connectToDevice:(GCKDevice *)device
{
    NSLog(@"Device address: %@:%d", device.ipAddress, (unsigned int) device.servicePort);
    self.selectedDevice = device;
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *appIdentifier = [info objectForKey:@"CFBundleIdentifier"];
    self.deviceManager =
    [[GCKDeviceManager alloc] initWithDevice:self.selectedDevice clientPackageName:appIdentifier];
    self.deviceManager.delegate = self;
    [self.deviceManager connect];
    
    // Start animating the cast connect images.
    UIButton *chromecastButton = (UIButton *)self.chromecastBarButton.customView;
    chromecastButton.tintColor = [UIColor whiteColor];
    chromecastButton.imageView.animationImages =
    @[ [UIImage imageNamed:@"cast_on0.png"], [UIImage imageNamed:@"cast_on1.png"],
       [UIImage imageNamed:@"cast_on2.png"], [UIImage imageNamed:@"cast_on1.png"] ];
    chromecastButton.imageView.animationDuration = 2;
    [chromecastButton.imageView startAnimating];
}

- (void)disconnectFromDevice
{
    NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
    // New way of doing things: We're not going to stop the applicaton. We're just going
    // to leave it.
    [self.deviceManager leaveApplication];
    // If you want to force application to stop, uncomment below
    //[self.deviceManager stopApplication];
    [self.deviceManager disconnect];
}

- (void)updateStatsFromDevice
{
    if (self.isConnected && self.mediaControlChannel && self.mediaControlChannel.mediaStatus) {
        _playerState = self.mediaControlChannel.mediaStatus.playerState;
        _mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;
    }
}

- (void)stopCastMedia
{
    if (self.isConnected && self.mediaControlChannel && self.mediaControlChannel.mediaStatus) {
        NSLog(@"Telling cast media control channel to stop");
        [self.mediaControlChannel stop];
    }
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager
{
    NSLog(@"connected!!");
    
    [self.deviceManager launchApplication:kReceiverAppID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication
{
    
    NSLog(@"application has launched");
    self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
    self.mediaControlChannel.delegate = self;
    [self.deviceManager addChannel:self.mediaControlChannel];
    [self.mediaControlChannel requestStatus];
    
    self.applicationMetadata = applicationMetadata;
    [self updateCastIconButtonStates];
    
    if ([self.delegate respondsToSelector:@selector(didConnectToDevice:)]) {
        [self.delegate didConnectToDevice:self.selectedDevice];
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectToApplicationWithError:(NSError *)error
{
    [self showError:error];
    
    [self deviceDisconnected];
    [self updateCastIconButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectWithError:(GCKError *)error
{
    [self showError:error];
    
    [self deviceDisconnected];
    [self updateCastIconButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(GCKError *)error
{
    NSLog(@"Received notification that device disconnected");
    
    if (error != nil) {
        [self showError:error];
    }
    
    [self deviceDisconnected];
    [self updateCastIconButtonStates];
}

- (void)deviceDisconnected
{
    self.mediaControlChannel = nil;
    self.deviceManager = nil;
    self.selectedDevice = nil;
    
    if ([self.delegate respondsToSelector:@selector(didDisconnect)]) {
        [self.delegate didDisconnect];
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata
{
    self.applicationMetadata = applicationMetadata;
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device
{
    NSLog(@"device found!! %@", device.friendlyName);
    [self updateCastIconButtonStates];
    if ([self.delegate respondsToSelector:@selector(didDiscoverDeviceOnNetwork)]) {
        [self.delegate didDiscoverDeviceOnNetwork];
    }
}

- (void)deviceDidGoOffline:(GCKDevice *)device
{
    [self updateCastIconButtonStates];
}

#pragma - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
didCompleteLoadWithSessionID:(NSInteger)sessionID
{
    _mediaControlChannel = mediaControlChannel;
}

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel
{
    [self updateStatsFromDevice];
    NSLog(@"Media control channel status changed");
    _mediaControlChannel = mediaControlChannel;
    if ([self.delegate respondsToSelector:@selector(didReceiveMediaStateChange)])
    {
        [self.delegate didReceiveMediaStateChange];
    }
}

- (void)mediaControlChannelDidUpdateMetadata:(GCKMediaControlChannel *)mediaControlChannel
{
    NSLog(@"Media control channel metadata changed");
    _mediaControlChannel = mediaControlChannel;
    [self updateStatsFromDevice];
    
    if ([self.delegate respondsToSelector:@selector(didReceiveMediaStateChange)]) {
        [self.delegate didReceiveMediaStateChange];
    }
}

- (BOOL)loadMedia:(NSString *)imageWebPath
{
    if (!self.deviceManager || !self.deviceManager.isConnected) {
        return NO;
    }
    
    GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
    
    GCKMediaInformation *mediaInformation =
    [[GCKMediaInformation alloc] initWithContentID:imageWebPath
                                        streamType:GCKMediaStreamTypeNone
                                       contentType:@"image/jpeg"
                                          metadata:metadata
                                    streamDuration:0
                                        customData:nil];
    [self.mediaControlChannel loadMedia:mediaInformation];
    
    return YES;
}

#pragma mark - implementation

- (void)showError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                    message:NSLocalizedString(error.description, nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

- (NSString *)getDeviceName
{
    if (self.selectedDevice == nil)
        return @"";
    return self.selectedDevice.friendlyName;
}

- (void)initControls
{
    // Create chromecast bar button.
    _btnImage = [UIImage imageNamed:@"cast_off.png"];
    _btnImageConnected = [UIImage imageNamed:@"cast_on.png"];
    
    UIButton *chromecastButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [chromecastButton addTarget:self
                         action:@selector(chooseDevice:)
               forControlEvents:UIControlEventTouchDown];
    chromecastButton.frame = CGRectMake(0, 0, self.btnImage.size.width, self.btnImage.size.height);
    [chromecastButton setImage:self.btnImage forState:UIControlStateNormal];
    chromecastButton.hidden = YES;
    
    _chromecastBarButton = [[UIBarButtonItem alloc] initWithCustomView:chromecastButton];
}

- (void)chooseDevice:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(shouldDisplayModalDeviceController)]) {
        [_delegate shouldDisplayModalDeviceController];
    }
}

- (void)updateCastIconButtonStates
{
    // Hide the button if there are no devices found.
    UIButton *chromecastButton = (UIButton *)self.chromecastBarButton.customView;
    if (self.deviceScanner.devices.count == 0) {
        chromecastButton.hidden = YES;
    } else {
        chromecastButton.hidden = NO;
        if (self.deviceManager && self.deviceManager.isConnected) {
            [chromecastButton.imageView stopAnimating];
            [chromecastButton setImage:self.btnImageConnected forState:UIControlStateNormal];
        } else {
            [chromecastButton setImage:self.btnImage forState:UIControlStateNormal];
        }
    }
}

@end
