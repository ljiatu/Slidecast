//
//  PWCDeviceTableViewController.m
//  Slidecast
//
//  Created by Jiatu Liu on 4/1/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCDeviceTableViewController.h"

#import "PWCAppDelegate.h"
#import "PWCChromecastDeviceController.h"

@interface PWCDeviceTableViewController ()

@end

@implementation PWCDeviceTableViewController

- (PWCChromecastDeviceController *)castDeviceController
{
    PWCAppDelegate *delegate = (PWCAppDelegate *)[UIApplication sharedApplication].delegate;
    return delegate.chromecastController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title to be white
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // force the navigation bar to be shown
    self.navigationController.navigationBar.alpha = 1.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!self.castDeviceController.isConnected) {
        self.title = @"Connect to";
        return self.castDeviceController.deviceScanner.devices.count;
    } else {
        self.title =
        [NSString stringWithFormat:@"Connected to %@", self.castDeviceController.deviceName];
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const CellIdForDeviceName = @"deviceName";
    static NSString *const CellIdForReadyStatus = @"readyStatus";
    static NSString *const CellIdForDisconnectButton = @"disconnectButton";
    static NSString *const CellIdForCastingStatus = @"castingStatus";
    
    UITableViewCell *cell;
    if (!self.castDeviceController.isConnected) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDeviceName forIndexPath:indexPath];
        
        // Configure the cell.
        GCKDevice *device = [self.castDeviceController.deviceScanner.devices objectAtIndex:indexPath.row];
        cell.textLabel.text = device.friendlyName;
        cell.detailTextLabel.text = device.modelName;
    } else /*if (!self.castDeviceController.isPlayingMedia) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForReadyStatus
                                                   forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDisconnectButton
                                                   forIndexPath:indexPath];
        }
    } else */{
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForCastingStatus
                                                   forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDisconnectButton
                                                   forIndexPath:indexPath];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.castDeviceController.isConnected) {
        if (indexPath.row < self.castDeviceController.deviceScanner.devices.count) {
            GCKDevice *device =
            [self.castDeviceController.deviceScanner.devices objectAtIndex:indexPath.row];
            NSLog(@"Selecting device:%@", device.friendlyName);
            [self.castDeviceController connectToDevice:device];
        }
    }
    
    // Dismiss the view.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Accesory button tapped");
}

- (IBAction)disconnectDevice:(id)sender
{
    [self.castDeviceController disconnectFromDevice];
    
    // Dismiss the view.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
