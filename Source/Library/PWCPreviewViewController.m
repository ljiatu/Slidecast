//
//  PWCPreviewController.m
//  Slidecast
//
//  Created by ljiatu on 3/15/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCPreviewViewController.h"

#import "CPDFDocumentViewController.h"
#import "CPDFDocument.h"
#import "CPDFPage.h"

@interface PWCPreviewViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *presentationTitle;
@property (weak, nonatomic) IBOutlet UIImageView *presentationPreview;
@property (weak, nonatomic) IBOutlet UILabel *numberSlides;
@property (weak, nonatomic) IBOutlet UISwitch *timeSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *displayInfoSwitch;

@end

@implementation PWCPreviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // initialize the document
    self.document = [[CPDFDocument alloc] initWithURL:self.documentURL];
    
    // set background color
    self.view.backgroundColor = [UIColor whiteColor];
    
    // set title
    NSString *title = self.document.title;
    if ([title rangeOfString:@"."].location != NSNotFound) {
        // if title contains the suffix ".pdf" or ".ppt"
        self.presentationTitle.title = [[title componentsSeparatedByString:@"."] objectAtIndex:0];
    } else {
        self.presentationTitle.title = title;
    }
    
    // display preview of the presentation
    CPDFPage *firstPage = [self.document pageForPageNumber:1];
    UIImage *firstPageImage = [firstPage imageWithSize:CGSizeMake(280, 220) scale:[UIScreen mainScreen].scale];
    self.presentationPreview.image = firstPageImage;
    self.presentationPreview.contentMode = UIViewContentModeScaleAspectFit;
    
    // display number of pages
    self.numberSlides.text = [@(self.document.numberOfPages) stringValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewSegue"]) {
        // pass the document document view controller
        CPDFDocumentViewController *destination = segue.destinationViewController;
        destination.document = self.document;
    }
}

@end
