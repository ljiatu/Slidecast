//
//  CLibraryViewController.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 05/31/11.
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

#import "CLibraryViewController.h"

#import "CPDFDocumentViewController.h"
#import "CPDFDocument.h"
#import "NSFileManager_BugFixExtensions.h"
#import "PWCPreviewViewController.h"

static NSString *const kReceiverAppID = @"2CFA780B";

@interface CLibraryViewController ()

@property UIImage *btnImage;
@property UIImage *btnImageSelected;

@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property GCKMediaControlChannel *mediaControlChannel;

@end

@implementation CLibraryViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (id)init
{
    if (self = [super init]) {
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidOpenURL:) name:@"applicationDidOpenURL" object:NULL];
    
    // refresh the list of presentations
    [self scanDirectories];
    [self.tableView reloadData];
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _btnImage = [UIImage imageNamed:@"icon-cast-identified.png"];
    _btnImageSelected = [UIImage imageNamed:@"icon-cast-connected.png"];
    _chromecastButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    // set up chromecast button
    [self.chromecastButton addTarget:self
                          action:@selector(chooseDevice:)
                forControlEvents:UIControlEventTouchDown];
    self.chromecastButton.frame = CGRectMake(0, 0, self.btnImage.size.width, self.btnImage.size.height);
    [self.chromecastButton setImage:nil forState:UIControlStateNormal];
    self.chromecastButton.hidden = YES;
    
    // add cast button to navigation bar
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithCustomView:self.chromecastButton];
    
    // initialize device scanner
    self.deviceScanner = [[GCKDeviceScanner alloc] init];
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    /*NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:self.cacheDirectoryPath error:&error];
    for (NSString *file in files) {
        if ([file rangeOfString:@".jpeg"].location == NSNotFound) {
            // don't remove something without .jpeg in it
            continue;
        }
        if (![fileManager removeItemAtPath:[self.cacheDirectoryPath stringByAppendingFormat:@"/%@", file] error:&error]) {
            NSLog(@"%@", error);
        }
    }*/
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.URLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *theCell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    NSURL *theURL = (self.URLs)[indexPath.row];
    NSString *theTitle = [theURL lastPathComponent];
    theCell.textLabel.text = theTitle;
    return theCell;
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)inSection
{
    return(@"Please select a presentation");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // pass the document URL to preview controller
    UINavigationController *navigationController = segue.destinationViewController;
    PWCPreviewViewController *destination = (PWCPreviewViewController *)navigationController.visibleViewController;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSURL *theURL = (self.URLs)[indexPath.row];
    destination.documentURL = theURL;
    
    // set the device manager and the media controller for the destination view controller
    destination.deviceManager = self.deviceManager;
    destination.mediaControlChannel = self.mediaControlChannel;
}

- (void)scanDirectories
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    
    NSURL *theDocumentsURL = [[theFileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *theInboxURL = [theDocumentsURL URLByAppendingPathComponent:@"Inbox"];
    NSError *theError = NULL;
    NSEnumerator *theEnumerator = NULL;
    id theErrorHandler = ^(NSURL *url, NSError *error) { NSLog(@"ERROR: %@", error); return(YES); };
    
    if ([theFileManager fileExistsAtPath:theInboxURL.path])
    {
        for (NSURL *theURL in [theFileManager tx_enumeratorAtURL:theInboxURL includingPropertiesForKeys:NULL options:0 errorHandler:theErrorHandler])
        {
            NSURL *theDestinationURL = [theDocumentsURL URLByAppendingPathComponent:[theURL lastPathComponent]];
            BOOL theResult = [theFileManager moveItemAtURL:theURL toURL:theDestinationURL error:&theError];
            NSLog(@"MOVING: %@ %d %@", theURL, theResult, theError);
        }
    }
    
    NSArray *theAllURLs = @[];
    NSArray *theURLs = NULL;
    
    NSURL *theBundleURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Samples"];
    theBundleURL = [theBundleURL URLByStandardizingPath];
    theEnumerator = [theFileManager tx_enumeratorAtURL:theBundleURL includingPropertiesForKeys:NULL options:0 errorHandler:theErrorHandler];
    theURLs = [theEnumerator allObjects];
    theAllURLs = [theAllURLs arrayByAddingObjectsFromArray:theURLs];
    
    theEnumerator = [theFileManager tx_enumeratorAtURL:theDocumentsURL includingPropertiesForKeys:NULL options:0 errorHandler:theErrorHandler];
    theURLs = [theEnumerator allObjects];
    theAllURLs = [theAllURLs arrayByAddingObjectsFromArray:theURLs];
    
    
    theAllURLs = [theAllURLs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"lastPathComponent LIKE '*.pdf'"]];
    
    theAllURLs = [theAllURLs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ([[NSFileManager defaultManager] fileExistsAtPath:[evaluatedObject path]]);
    }]];
    
    theAllURLs = [theAllURLs sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return([[obj1 lastPathComponent] compare:[obj2 lastPathComponent]]);
    }];
    
    self.URLs = theAllURLs;
}

- (void)applicationDidOpenURL:(NSNotification *)inNotification
{
    [self scanDirectories];
    [self.tableView reloadData];
}

#pragma mark chromecast
- (void)chooseDevice:(id)sender
{
    // choose device
    if (self.selectedDevice == nil) {
        // device Selection List
        UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to Device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];
        
        for (GCKDevice *device in self.deviceScanner.devices) {
            [sheet addButtonWithTitle:device.friendlyName];
        }
        
        [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
        
        [sheet showInView:self.chromecastButton];
    } else {
        // Already connected information
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"Casting to %@", nil),
                         self.selectedDevice.friendlyName];
        NSString *mediaTitle = [self.mediaInformation.metadata stringForKey:kGCKMetadataKeyTitle];
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        sheet.title = str;
        sheet.delegate = self;
        if (mediaTitle != nil) {
            [sheet addButtonWithTitle:mediaTitle];
        }
        [sheet addButtonWithTitle:@"Disconnect"];
        [sheet addButtonWithTitle:@"Cancel"];
        sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
        sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);
        
        [sheet showInView:self.chromecastButton];
    }
}

- (BOOL)isConnected
{
    return self.deviceManager.isConnected;
}

- (void)connectToDevice
{
    if (self.selectedDevice == nil)
        return;
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.deviceManager =
    [[GCKDeviceManager alloc] initWithDevice:self.selectedDevice
                           clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
    self.deviceManager.delegate = self;
    [self.deviceManager connect];
}

- (void)deviceDisconnected
{
    self.deviceManager = nil;
    self.selectedDevice = nil;
    NSLog(@"Device disconnected");
}

- (void)updateButtonStates
{
    if (self.deviceScanner.devices.count == 0) {
        // Hide the cast button
        [self.chromecastButton setImage:_btnImage forState:UIControlStateNormal];
        self.chromecastButton.hidden = YES;
    } else {
        if (self.deviceManager && self.deviceManager.isConnected) {
            // Enabled state for cast button
            [self.chromecastButton setImage:self.btnImageSelected forState:UIControlStateNormal];
            [self.chromecastButton setTintColor:[UIColor blueColor]];
            self.chromecastButton.hidden = NO;
        } else {
            // Disabled state for cast button
            [self.chromecastButton setImage:self.btnImage forState:UIControlStateNormal];
            [self.chromecastButton setTintColor:[UIColor grayColor]];
            self.chromecastButton.hidden = NO;
        }
    }
    
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device
{
    NSLog(@"device found!! %@", device.friendlyName);
    [self updateButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device
{
    [self updateButtonStates];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.selectedDevice == nil) {
        if (buttonIndex < self.deviceScanner.devices.count) {
            self.selectedDevice = self.deviceScanner.devices[buttonIndex];
            NSLog(@"Selecting device:%@", self.selectedDevice.friendlyName);
            [self connectToDevice];
        }
    } else {
        if (buttonIndex == 0) {
            // disconnect button
            NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
            // New way of doing things: We're not going to stop the applicaton. We're just going
            // to leave it.
            [self.deviceManager leaveApplication];
            // If you want to force application to stop, uncomment below
            //[self.deviceManager stopApplicationWithSessionID:self.applicationMetadata.sessionID];
            [self.deviceManager disconnect];
            
            [self deviceDisconnected];
            [self updateButtonStates];
        } else if (buttonIndex == 0) {
            // Join the existing session.
            
        }
    }
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager
{
    NSLog(@"connected!!");
    
    [self updateButtonStates];
    
    // launch application after getting connectted
    [self.deviceManager launchApplication:kReceiverAppID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata sessionID:(NSString *)sessionID launchedApplication:(BOOL)launchedApplication
{
    NSLog(@"application has launched %hhd", launchedApplication);
    
    // add media channel here
    self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
    self.mediaControlChannel.delegate = self;
    [self.deviceManager addChannel:self.mediaControlChannel];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectToApplicationWithError:(NSError *)error {
    [self showError:error];
    
    [self deviceDisconnected];
    [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectWithError:(GCKError *)error
{
    [self showError:error];
    
    [self deviceDisconnected];
    [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didDisconnectWithError:(GCKError *)error
{
    NSLog(@"Received notification that device disconnected");
    
    if (error != nil) {
        [self showError:error];
    }
    
    [self deviceDisconnected];
    [self updateButtonStates];
    
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata
{
    self.applicationMetadata = applicationMetadata;
    
    NSLog(@"Received device status: %@", applicationMetadata);
}

#pragma mark - misc
- (void)showError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                    message:NSLocalizedString(error.description, nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

@end
