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
#import "PWCAppDelegate.h"
#import "PWCPreviewViewController.h"
#import "PWCUtilities.h"

@interface CLibraryViewController ()

@property (weak, nonatomic) PWCChromecastDeviceController *chromecastController;

@end

@implementation CLibraryViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidOpenURL:) name:@"applicationDidOpenURL" object:NULL];
    
    // refresh the list of presentations
    [self scanDirectories];
    [self.tableView reloadData];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // display an Edit button in the navigation bar for this view controller.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // store a reference to the chromecast controller
    PWCAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    _chromecastController = delegate.chromecastController;
    
    // display cast icon in the right nav bar button, if we have devices
    if (self.chromecastController.deviceScanner.devices.count > 0) {
        self.navigationItem.rightBarButtonItem = self.chromecastController.chromecastBarButton;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // assign ourselves as delegate ONLY in viewWillAppear of a view controller
    self.chromecastController.delegate = self;
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
{}

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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        // locate the cell and presentation folder
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *folderPath = [documentsPath stringByAppendingFormat:@"/%@",
                                [PWCUtilities presentationTitleForDocumentName:cell.textLabel.text]];
        NSError *error = nil;
        
        // delete the entire folder
        BOOL deleteResult = [fileManager removeItemAtPath:folderPath error:&error];
        if (!deleteResult) {
            NSLog(@"%@", error);
            return;
        }

        // delete the specific cell in table view
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // reload the data
        [self scanDirectories];
        [tableView endUpdates];
    }
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)inSection
{
    return(@"Please select a presentation");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"previewSegue"]) {
        // pass the document URL to preview controller
        UINavigationController *navigationController = segue.destinationViewController;
        PWCPreviewViewController *destination = (PWCPreviewViewController *)navigationController.visibleViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSURL *theURL = (self.URLs)[indexPath.row];
        destination.documentURL = theURL;
    }
}

- (void)scanDirectories
{
    _URLs = [[NSMutableArray alloc] init];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *inboxURL = [documentsURL URLByAppendingPathComponent:@"Inbox"];
    NSError *error = nil;
    id errorHandler = ^(NSURL *url, NSError *error) { NSLog(@"ERROR: %@", error); return(YES); };
    
    // first move all documents waiting in the Documents/Inbox folder to the Documents folder
    if ([fileManager fileExistsAtPath:inboxURL.path])
    {
        for (NSURL *URL in [fileManager tx_enumeratorAtURL:inboxURL includingPropertiesForKeys:NULL options:0 errorHandler:errorHandler])
        {
            // first create a dedicated folder for the presentation
            NSString *folderName = [NSString stringWithFormat:@"/%@", [PWCUtilities presentationTitleAtURL:URL]];
            NSURL *folderURL = [documentsURL URLByAppendingPathComponent:folderName];
            BOOL result = [fileManager createDirectoryAtURL:folderURL withIntermediateDirectories:NO
                           attributes:nil error:&error];
            if (!result) {
                NSLog(@"%@", error);
            }
            // now move the presentation
            NSURL *destinationURL = [folderURL URLByAppendingPathComponent:[URL lastPathComponent]];
            BOOL moveResult = [fileManager moveItemAtURL:URL toURL:destinationURL error:&error];
            NSLog(@"MOVING: %@ %d %@", URL, moveResult, error);
        }
    }
    
    // then add URLs of all documents in the Documents folder into the array of URLs
    for (NSURL *URL in [fileManager tx_enumeratorAtURL:documentsURL includingPropertiesForKeys:NULL options:0 errorHandler:errorHandler]) {
        [self.URLs addObject:URL];
    }
    
    // finally filter the array and sort it
    [self.URLs filterUsingPredicate:[NSPredicate predicateWithFormat:@"lastPathComponent LIKE '*.pdf'"]];
    
    [self.URLs filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ([fileManager fileExistsAtPath:[evaluatedObject path]]);
    }]];
    
    [self.URLs sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return([[obj1 lastPathComponent] compare:[obj2 lastPathComponent]]);
    }];
}

- (void)applicationDidOpenURL:(NSNotification *)inNotification
{
    [self scanDirectories];
    [self.tableView reloadData];
}

#pragma mark - PWCChromecastControllerDelegate

- (void)didDiscoverDeviceOnNetwork
{
    // display the chromecast button on the top right corner
    self.navigationItem.rightBarButtonItem = self.chromecastController.chromecastBarButton;
}

- (void)shouldDisplayModalDeviceController
{
    [self performSegueWithIdentifier:@"devicesSegue" sender:self];
}

@end
