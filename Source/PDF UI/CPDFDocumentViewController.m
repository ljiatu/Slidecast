//
//  CPDFDocumentViewController.m
//  Slidecast
//
//  Created by Jonathan Wight on 02/19/11.
//  Modified by Jiatu Liu to be used in Slidecast.
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

#import "CPDFDocumentViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <GoogleCast/GoogleCast.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

#import "CContentScrollView.h"
#import "CPDFDocument.h"
#import "CPDFPageViewController.h"
#import "CPDFPage.h"
#import "CPDFPageView.h"
#import "CPreviewCollectionViewCell.h"
#import "Geometry.h"
#import "PWCAppDelegate.h"
#import "PWCFileServer.h"
#import "PWCNotes.h"

@interface CPDFDocumentViewController () <CPDFDocumentDelegate, UIPageViewControllerDelegate,
                                          UIPageViewControllerDataSource, UIGestureRecognizerDelegate,
                                          CPDFPageViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource,
                                          UICollectionViewDelegate>

@property (weak, nonatomic) PWCChromecastDeviceController *chromecastController;

@property (readwrite, nonatomic, strong) UIPageViewController *pageViewController;
@property (readwrite, nonatomic, strong) CContentScrollView *scrollView;
@property (readwrite, nonatomic, strong) IBOutlet UICollectionView *previewCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *singleTapRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapRecognizer;

@property (readwrite, nonatomic, assign) BOOL navigationBarHidden;
@property (readwrite, nonatomic, strong) NSCache *renderedPageCache;
@property (readwrite, nonatomic, strong) UIImage *pagePlaceholderImage;
@property (readonly, nonatomic, strong) NSArray *pages;
@property (strong, nonatomic) NSTimer * timer;
@property (strong, nonatomic) NSDate * date;
@property (nonatomic) PWCNotes * notes;
@property (nonatomic) NSString *ipAddress;
@property (nonatomic) UInt16 port;

@end

@implementation CPDFDocumentViewController

#pragma mark -

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (_backgroundView != backgroundView)
    {
        [_backgroundView removeFromSuperview];
        
        _backgroundView = backgroundView;
        [self.view insertSubview:_backgroundView atIndex:0];
    }
}

- (void)updateTimer
{
    // Create date from the elapsed time
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:self.date];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    // Create a date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    // Format the elapsed time and set it to the label
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    self.timeLabel.text = timeString;
}

- (void)action:(id)sender
{
    if([self.segmentedControl selectedSegmentIndex] == 0)
    {
        self.previewCollectionView.hidden = NO;
        self.noteText.hidden = YES;
    } else if([self.segmentedControl selectedSegmentIndex] == 1)
    {
        self.previewCollectionView.hidden = YES;
        self.noteText.hidden = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the document delegate and set up cache
    _document.delegate = self;
    _renderedPageCache = [[NSCache alloc] init];
    _renderedPageCache.countLimit = 8;
    
    // store a reference to the chromecast controller
    PWCAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    _chromecastController = delegate.chromecastController;
    
    // set up the timer
    self.date = [NSDate date];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                  target:self
                                                selector:@selector(updateTimer)
                                                userInfo:nil
                                                 repeats:YES];
    
    // set up page view controller
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    NSArray *theViewControllers = [self pageViewControllerForPageNumber:1];
    [self.pageViewController setViewControllers:theViewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    [self addChildViewController:self.pageViewController];
    
    // #########################################################################
    
    self.scrollView = [[CContentScrollView alloc] initWithFrame:self.pageViewController.view.bounds];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.contentView = self.pageViewController.view;
    self.scrollView.maximumZoomScale = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 8.0 : 4.0;
    self.scrollView.delegate = self;
    [self.scrollView addSubview:self.scrollView.contentView];
    [self.view insertSubview:self.scrollView atIndex:0];
    
    NSDictionary *theViews = @{
                               @"scrollView": self.scrollView,
                               @"pageView": self.scrollView,
                               };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[scrollView]-0-|" options:0 metrics:NULL views:theViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[scrollView]-0-|" options:0 metrics:NULL views:theViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[pageView]-0-|" options:0 metrics:NULL views:theViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[pageView]-0-|" options:0 metrics:NULL views:theViews]];
    
    // #########################################################################
    
    self.previewCollectionView.dataSource = self;
    self.previewCollectionView.delegate = self;
    
    [self.singleTapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    
    // add a border for text view
    [[self.noteText layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[self.noteText layer] setBorderWidth:1];
    
    // get the ip address and port of the device
    self.ipAddress = [self getIPAddress];
    self.port = [delegate.server listeningPort];
    
    // set up notes
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    CPDFPageViewController *theFirstViewController = theViewControllers[0];
    self.notes = [[PWCNotes alloc] initNotesWithFilename:theFirstViewController.page.document.title
                                 path:path
                              numberOfPages:theFirstViewController.page.document.numberOfPages];
    [self.segmentedControl addTarget:self action:@selector(action:) forControlEvents:UIControlEventValueChanged];
    
    // update title and cast the image of the first page
    [self updateTitleAndCastImage];
    
    // display cast icon in the right navigation bar button
    self.navigationItem.rightBarButtonItem = self.chromecastController.chromecastBarButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self resizePageViewControllerForOrientation:self.interfaceOrientation];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self populateCache];
        [self.document startGeneratingThumbnails];
    });
    
    // assign ourselves as delegate ONLY in viewWillAppear of a view controller.
    self.chromecastController.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performSelector:@selector(hideNavigationBar) withObject:NULL afterDelay:0.5];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.chromecastController stopCastMedia];
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr -> ifa_addr -> sa_family == AF_INET) {
                // check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr -> ifa_name] isEqualToString:@"en0"]) {
                    // get NSString from C String
                    address = [NSString
                               stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr -> ifa_addr) -> sin_addr)];
                }
            }
            temp_addr = temp_addr -> ifa_next;
        }
    }
    // free memory
    freeifaddrs(interfaces);
    return address;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self resizePageViewControllerForOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateTitleAndCastImage];
    [self.renderedPageCache removeAllObjects];
    [self populateCache];
}

- (void)hideNavigationBar
{
    if (self.navigationBarHidden == NO)
    {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.navigationController.navigationBar.alpha = 0.0;
            self.previewCollectionView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.navigationBarHidden = YES;
        }];
        //[self.navigationController setNavigationBarHidden:YES animated:YES];
        //self.navigationBarHidden = YES;
    }
}

- (void)toggleNavigationBar
{
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        self.navigationController.navigationBar.alpha = (1.0 - !self.navigationBarHidden);
        self.previewCollectionView.alpha = (1.0 - !self.navigationBarHidden);
    } completion:^(BOOL finished) {
        self.navigationBarHidden = !self.navigationBarHidden;
    }];
    
    //[self.navigationController setNavigationBarHidden:!self.navigationBarHidden animated:YES];
    //self.navigationBarHidden = !self.navigationBarHidden;
}

- (void)updateTitleAndCastImage
{
    NSArray *theViewControllers = self.pageViewController.viewControllers;
    CPDFPageViewController *theFirstViewController = theViewControllers[0];
    NSInteger pageNumber = theFirstViewController.page.pageNumber;
    self.title = [NSString stringWithFormat:@"Page %ld", (long)pageNumber];
    // load notes for that page
    [self.noteText setText:[self.notes getNoteAtIndex:(pageNumber - 1)]];
    // cast image of the page
    [self.chromecastController loadMedia:[self imageWebPathOfPageNumber:pageNumber]];
}

- (NSString *)imageWebPathOfPageNumber:(NSInteger)pageNumber
{
    // search for the image
    NSString *imageName = [NSString stringWithFormat:@"%ld.jpeg", (long)pageNumber];
    NSString *imageWebPath = [NSString stringWithFormat:@"http://%@:%d/%@/%@",
                              self.ipAddress, self.port, self.document.title, imageName];
    
    return imageWebPath;
}

- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation
{
    CGRect theBounds = self.view.bounds;
    CGRect theFrame;
    CGRect theMediaBox = [self.document pageForPageNumber:1].mediaBox;
    /*if ([self canDoubleSpreadForOrientation:inOrientation] == YES) {
        theMediaBox.size.width *= 2;
    } else {
        theFrame = ScaleAndAlignRectToRect(theMediaBox, theBounds, ImageScaling_Proportionally, ImageAlignment_Center);
    }*/
    theFrame = ScaleAndAlignRectToRect(theMediaBox, theBounds, ImageScaling_Proportionally, ImageAlignment_Center);
    theFrame = CGRectIntegral(theFrame);
    
    self.pageViewController.view.frame = theFrame;
    
    // Show fancy shadow if PageViewController view is smaller than parent view
    if (CGRectContainsRect(self.view.frame, self.pageViewController.view.frame) && CGRectEqualToRect(self.view.frame, self.pageViewController.view.frame) == NO)
    {
        CALayer *theLayer = self.pageViewController.view.layer;
        theLayer.shadowPath = [[UIBezierPath bezierPathWithRect:self.pageViewController.view.bounds] CGPath];
        theLayer.shadowRadius = 10.0f;
        theLayer.shadowColor = [[UIColor blackColor] CGColor];
        theLayer.shadowOpacity = 0.75f;
        theLayer.shadowOffset = CGSizeZero;
    }
    else
    {
        self.pageViewController.view.layer.shadowOpacity = 0.0f;
    }
}

#pragma mark -

- (NSArray *)pageViewControllerForPageNumber:(NSInteger)pageNumber
{
    CPDFPage *page;
    if (pageNumber <= self.document.numberOfPages) {
        page = [self.document pageForPageNumber:pageNumber];
    }
    return @[[self pageViewControllerWithPage:page]];
}

- (CPDFPageViewController *)pageViewControllerWithPage:(CPDFPage *)inPage
{
    CPDFPageViewController *thePageViewController = [[CPDFPageViewController alloc] initWithPage:inPage];
    thePageViewController.pagePlaceholderImage = self.pagePlaceholderImage;
    // Force load the view.
    [thePageViewController view];
    thePageViewController.pageView.delegate = self;
    thePageViewController.pageView.renderedPageCache = self.renderedPageCache;
    return(thePageViewController);
}

- (NSArray *)pages
{
    return([self.pageViewController.viewControllers valueForKey:@"page"]);
}

#pragma mark -

- (BOOL)openPage:(CPDFPage *)inPage
{
    CPDFPageViewController *theCurrentPageViewController = (self.pageViewController.viewControllers)[0];
    if (inPage == theCurrentPageViewController.page)
    {
        return(YES);
    }
    
    NSArray *theViewControllers = [self pageViewControllerForPageNumber:inPage.pageNumber];
    
    UIPageViewControllerNavigationDirection theDirection = inPage.pageNumber > theCurrentPageViewController.pageNumber ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    [self.pageViewController setViewControllers:theViewControllers direction:theDirection animated:NO completion:NULL];
    [self updateTitleAndCastImage];
    
    [self populateCache];
    
    return(YES);
}

- (IBAction)tap:(UITapGestureRecognizer *)inRecognizer
{
    [self toggleNavigationBar];
}

- (IBAction)doubleTap:(UITapGestureRecognizer *)inRecognizer
{
    if (self.scrollView.zoomScale != 1.0)
    {
        [self.scrollView setZoomScale:1.0 animated:YES];
    }
    else
    {
        [self.scrollView setZoomScale:[UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2.6 : 1.66 animated:YES];
    }
}

- (void)populateCache
{
    CPDFPage *theStartPage = (self.pages)[0] != [NSNull null]? (self.pages)[0] : nil;
    CPDFPage *theLastPage = [self.pages lastObject] != [NSNull null]? [self.pages lastObject] : nil;
    
    NSInteger theStartPageNumber = [theStartPage pageNumber];
    NSInteger theLastPageNumber = [theLastPage pageNumber];
    
    // get the images for the previous, current, and next page
    NSInteger pageSpanToLoad = 1;
    theStartPageNumber = MAX(theStartPageNumber - pageSpanToLoad, 1);
    theLastPageNumber = MIN(theLastPageNumber + pageSpanToLoad, self.document.numberOfPages);
        
    UIView *thePageView = [(self.pageViewController.viewControllers)[0] pageView];
    if (thePageView == NULL)
    {
        NSLog(@"WARNING: No page view.");
        return;
    }
    CGRect theBounds = thePageView.bounds;
    
    for (NSInteger thePageNumber = theStartPageNumber; thePageNumber <= theLastPageNumber; ++thePageNumber)
    {
        NSString *theKey = [NSString stringWithFormat:@"%ld[%d,%d]", (long)thePageNumber, (int)theBounds.size.width, (int)theBounds.size.height];
        if ([self.renderedPageCache objectForKey:theKey] == NULL)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                UIImage *theImage = [[self.document pageForPageNumber:thePageNumber] imageWithSize:theBounds.size scale:[UIScreen mainScreen].scale];
                if (theImage != NULL)
                {
                    [self.renderedPageCache setObject:theImage forKey:theKey];
                }
            });
        }
    }
}

#pragma mark - Page View Controller Data Source Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    CPDFPageViewController *theViewController = (CPDFPageViewController *)viewController;
    
    NSUInteger theNextPageNumber = theViewController.page.pageNumber - 1;
    if (theNextPageNumber > self.document.numberOfPages)
    {
        return(NULL);
    }
    
    if (theNextPageNumber == 0 && UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        return(NULL);
    }
    
    CPDFPage *thePage = theNextPageNumber > 0 ? [self.document pageForPageNumber:theNextPageNumber] : NULL;
    theViewController = [self pageViewControllerWithPage:thePage];
    
    return(theViewController);
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    CPDFPageViewController *theViewController = (CPDFPageViewController *)viewController;
    
    NSUInteger theNextPageNumber = theViewController.page.pageNumber + 1;
    if (theNextPageNumber > self.document.numberOfPages)
    {
        return nil;
    }
    
    CPDFPage *thePage = theNextPageNumber > 0 ? [self.document pageForPageNumber:theNextPageNumber] : NULL;
    theViewController = [self pageViewControllerWithPage:thePage];
    
    return theViewController;
}

#pragma mark - Page View Controller Delegate Methods

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed;
{
    [self updateTitleAndCastImage];
    [self populateCache];
    [self hideNavigationBar];
    
    CPDFPageViewController *theFirstViewController = (self.pageViewController.viewControllers)[0];
    if (theFirstViewController.page)
    {
        NSArray *thePageNumbers = [self.pageViewController.viewControllers valueForKey:@"pageNumber"];
        NSMutableIndexSet *theIndexSet = [NSMutableIndexSet indexSet];
        for (NSNumber *thePageNumber in thePageNumbers)
        {
            NSInteger N = [thePageNumber integerValue] - 1;
            if (N != 0)
            {
                [theIndexSet addIndex:N];
            }
        }
        [theIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.previewCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }];
    }
}

#pragma mark - Collection View Data Source Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return(self.document.numberOfPages);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    CPreviewCollectionViewCell *theCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CELL" forIndexPath:indexPath];
    UIImage *theImage = [self.document pageForPageNumber:indexPath.item + 1].thumbnail;
    theCell.imageView.image = theImage;
    return(theCell);
}

#pragma mark - Collection View Delegate Method

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CPDFPage *thePage = [self.document pageForPageNumber:indexPath.item + 1];
    [self openPage:thePage];
}

#pragma mark - Document Delegate Method

- (void)PDFDocument:(CPDFDocument *)inDocument didUpdateThumbnailForPage:(CPDFPage *)inPage
{
    [self.previewCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:inPage.pageNumber - 1 inSection:0]]];
}

#pragma mark -

- (BOOL)PDFPageView:(CPDFPageView *)inPageView openPage:(CPDFPage *)inPage fromRect:(CGRect)inFrame
{
    [self openPage:inPage];
    return(YES);
}

#pragma mark -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;     // return a view that will be scaled. if delegate returns nil, nothing happens
{
    return(self.pageViewController.view);
}

#pragma mark - Chromecast Controller Delegate Methods

- (void)shouldDisplayModalDeviceController
{
    [self performSegueWithIdentifier:@"devicesSegue" sender:self];
}

@end
