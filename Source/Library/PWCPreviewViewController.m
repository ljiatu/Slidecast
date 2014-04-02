//
//  PWCPreviewController.m
//  Slidecast
//
//  Created by ljiatu on 3/15/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCPreviewViewController.h"

#import <Googlecast/Googlecast.h>
#import "CPDFDocumentViewController.h"
#import "CPDFDocument.h"
#import "CPDFPage.h"
#import "PWCAppDelegate.h"
#import "PWCNotesViewController.h"

@interface PWCPreviewViewController ()

@property (weak, nonatomic) PWCChromecastDeviceController *chromecastController;

@property (weak, nonatomic) IBOutlet UINavigationItem *presentationTitle;
@property (weak, nonatomic) IBOutlet UIImageView *presentationPreview;
@property (weak, nonatomic) IBOutlet UILabel *numberSlides;

@end

@implementation PWCPreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // store a reference to the chromecast controller
    PWCAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    _chromecastController = delegate.chromecastController;
    
    // initialize the document
    self.document = [[CPDFDocument alloc] initWithURL:self.documentURL];
    
    // set background color
    self.view.backgroundColor = [UIColor whiteColor];
    
    // set title
    self.presentationTitle.title = self.document.title;
    
    // display preview of the presentation
    CPDFPage *firstPage = [self.document pageForPageNumber:1];
    UIImage *firstPageImage = [firstPage imageWithSize:CGSizeMake(200, 157) scale:[UIScreen mainScreen].scale];
    self.presentationPreview.image = firstPageImage;
    self.presentationPreview.contentMode = UIViewContentModeScaleAspectFit;
    
    // display number of pages
    self.numberSlides.text = [@(self.document.numberOfPages) stringValue];
    
    // create images for each slide if not created yet
    [self createImagesForSlides];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // assign ourselves as delegate ONLY in viewWillAppear of a view controller.
    self.chromecastController.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewSegue"]) {
        // pass the document to the document view controller
        CPDFDocumentViewController *destination = segue.destinationViewController;
        destination.document = self.document;
        
        // pass the device manager and the media control channel to the document view controller
        //destination.deviceManager = self.deviceManager;
        //destination.mediaControlChannel = self.mediaControlChannel;
    } else if ([segue.identifier isEqualToString:@"notesSegue"]) {
        PWCNotesViewController * dest = segue.destinationViewController;
        dest.docTitle = self.document.title;
        dest.numberOfPages = self.document.numberOfPages;
    }
}

- (BOOL)createImagesForSlides
{
    NSFileManager *manager = [NSFileManager defaultManager];
    // get the path of the directory of images
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *imageDirectoryPath = [documentsPath stringByAppendingFormat:@"/%@", self.document.title];
    
    // test if the images have been generated
    if ([manager fileExistsAtPath:[imageDirectoryPath stringByAppendingFormat:@"/1.jpeg"]]) {
        // if exists, do nothing
        return YES;
    } else {
        // otherwise, generate the images
        NSError *error = nil;
        // create a jpeg file for each page of the pdf file
        for (int i = 1; i <= self.document.numberOfPages; ++i) {
            NSString *jpegPath = [NSString stringWithFormat:@"%@/%d.jpeg", imageDirectoryPath, i];
            // most likely we have to change the size of the images
            UIImage *image = [[self.document pageForPageNumber:i] imageWithSize:CGSizeMake(280, 220) scale:[UIScreen mainScreen].scale];
            if (![UIImageJPEGRepresentation(image, 1.0) writeToFile:jpegPath atomically:YES]) {
                // if fail for one of the images, delete the whole directory
                if (![manager removeItemAtPath:imageDirectoryPath error:&error]) {
                    NSLog(@"%@", error);
                }
                return NO;
            }
        }
        
        return YES;
    }
}

- (IBAction)unwindToPreview:(UIStoryboardSegue *)segue
{}

@end
