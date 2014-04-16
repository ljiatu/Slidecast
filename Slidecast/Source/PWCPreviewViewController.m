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
#import "PWCConstants.h"
#import "PWCNotesViewController.h"
#import "PWCTimerSettingsViewController.h"

@interface PWCPreviewViewController ()

@property (weak, nonatomic) PWCChromecastDeviceController *chromecastController;

@property (weak, nonatomic) IBOutlet UINavigationItem *presentationTitle;
@property (weak, nonatomic) IBOutlet UIImageView *presentationPreview;
@property (weak, nonatomic) IBOutlet UILabel *numberSlides;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation PWCPreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title to be white
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    // store a reference to the chromecast controller
    PWCAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    _chromecastController = delegate.chromecastController;
    
    // initialize the document
    self.document = [[CPDFDocument alloc] initWithURL:self.documentURL];
    
    // set background picture
    self.view.layer.contents = (id)[UIImage imageNamed:@"background.jpg"].CGImage;
    
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // change the title of the back button item
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    // force the navigation bar to be shown
    self.navigationController.navigationBar.alpha = 1.0;

    // display the total time
    if (self.countDownDuration == 0) {
        self.timeLabel.text = @"--:--:--";
    } else {
        NSInteger hours = self.countDownDuration / 3600;
        NSInteger minutes = (self.countDownDuration - hours * 3600) / 60;
        NSInteger seconds = self.countDownDuration - hours * 3600 - minutes * 60;
        self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
    }
    
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
        destination.timerOn = self.timerOn;
        destination.countDownDuration = self.countDownDuration;
    } else if ([segue.identifier isEqualToString:@"notesSegue"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PWCNotesViewController *destination = (PWCNotesViewController *)navigationController.visibleViewController;
        destination.documentTitle = self.document.title;
        destination.numberOfPages = self.document.numberOfPages;
    } else if ([segue.identifier isEqualToString:@"timerSegue"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PWCTimerSettingsViewController *timerController = (PWCTimerSettingsViewController *)navigationController.visibleViewController;
        timerController.timerIsInitiallyOn = self.timerOn;
        timerController.countDownDuration = self.countDownDuration;
    }
}

- (BOOL)createImagesForSlides
{
    NSFileManager *manager = [NSFileManager defaultManager];
    // get the path of the directory of images
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *imageDirectoryPath = [documentsPath stringByAppendingFormat:@"/%@", self.document.title];
    
    // test if the images have been generated
    if ([manager fileExistsAtPath:[imageDirectoryPath stringByAppendingString:@"/1.jpeg"]]) {
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

#pragma mark - Chromecast Controller Delegate Methods

- (void)shouldDisplayModalDeviceController
{
    [self performSegueWithIdentifier:@"devicesSegue" sender:self];
}

@end
