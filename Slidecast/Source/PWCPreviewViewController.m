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
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *setTimerButton;

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
    
    // disable interactive view controller dismissal
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    // display cast icon in the right navigation bar button
    self.navigationItem.rightBarButtonItem = self.chromecastController.chromecastBarButton;
    
    self.datePicker.datePickerMode = UIDatePickerModeCountDownTimer;
    // put the date picker outside of the view first
    [self.datePicker setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,
                                         self.datePicker.frame.size.height)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // change the title of the back button item
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    // force the navigation bar to be shown
    self.navigationController.navigationBar.alpha = 1.0;
    
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

- (IBAction)setTimer:(id)sender
{
    [self.view addSubview:self.datePicker];
    [UIView animateWithDuration:1.0 animations:^{
        [self.datePicker setFrame:CGRectMake(0, self.view.frame.size.height - self.datePicker.frame.size.height,
                                             self.datePicker.frame.size.width, self.datePicker.frame.size.height)];
    }];
}

#pragma mark - Chromecast Controller Delegate Methods

- (void)shouldDisplayModalDeviceController
{
    [self performSegueWithIdentifier:@"devicesSegue" sender:self];
}

@end
