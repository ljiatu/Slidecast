//
//  iOS-PDF-ReaderViewController.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 02/19/11.
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
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "CPDFDocument.h"
#import "CPDFPageViewController.h"
#import "CPDFPage.h"
#import "CPDFPageView.h"
#import "CContentScrollView.h"
#import "Geometry.h"
#import "CPreviewCollectionViewCell.h"
#import "PWCUtilities.h"
#import "HTTPServer.h"

@interface CPDFDocumentViewController () <CPDFDocumentDelegate, UIPageViewControllerDelegate,
                                          UIPageViewControllerDataSource, UIGestureRecognizerDelegate,
                                          CPDFPageViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource,
                                          UICollectionViewDelegate>

@property (readwrite, nonatomic, strong) UIPageViewController *pageViewController;
@property (readwrite, nonatomic, strong) IBOutlet CContentScrollView *scrollView;
@property (readwrite, nonatomic, strong) IBOutlet UICollectionView *previewCollectionView;
@property (readwrite, nonatomic, assign) BOOL chromeHidden;
@property (readwrite, nonatomic, strong) NSCache *renderedPageCache;
@property (readwrite, nonatomic, strong) UIImage *pagePlaceholderImage;
@property (readonly, nonatomic, strong) NSArray *pages;
@property (strong, nonatomic) NSTimer * timer;
@property (strong, nonatomic) NSDate * date;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property PWCUtilities * notes;
@property NSString *imageDirectoryPath;
@property NSString *ipAddress;

- (void)hideChrome;
- (void)toggleChrome;
- (BOOL)canDoubleSpreadForOrientation:(UIInterfaceOrientation)inOrientation;
- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation;
- (CPDFPageViewController *)pageViewControllerWithPage:(CPDFPage *)inPage;

@end

@implementation CPDFDocumentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != NULL)
    {
        _document.delegate = self;
        _renderedPageCache = [[NSCache alloc] init];
        _renderedPageCache.countLimit = 8;
    }
    return(self);
}

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

#pragma mark -
- (void)updateTimer
{
    // Create date from the elapsed time
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:self.date];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    // Create a date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    // Format the elapsed time and set it to the label
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    self.timeLabel.text = timeString;
}

- (void)action:(id)sender
{
    if([self.segmentedControl selectedSegmentIndex] == 0)
    {
        self.scrollView.hidden = NO;
        self.previewCollectionView.hidden = NO;
        self.noteText.hidden = YES;
    }
    if([self.segmentedControl selectedSegmentIndex] == 1)
    {
        self.scrollView.hidden = YES;
        self.previewCollectionView.hidden = YES;
        self.noteText.hidden = NO;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // #########################################################################
    
    UIPageViewControllerSpineLocation theSpineLocation;
    if ([self canDoubleSpreadForOrientation:self.interfaceOrientation] == YES)
    {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
    }
    else
    {
        theSpineLocation = UIPageViewControllerSpineLocationMin;
    }
    
    // #########################################################################
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                  target:self
                                                selector:@selector(updateTimer)
                                                userInfo:nil
                                                 repeats:YES];
    self.date = [NSDate date];
    
    NSDictionary *theOptions = @{ UIPageViewControllerOptionSpineLocationKey: [NSNumber numberWithInt:theSpineLocation] };
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:theOptions];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    NSRange theRange = { .location = 1, .length = 1 };
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
    {
        theRange = (NSRange){ .location = 0, .length = 2 };
    }
    NSArray *theViewControllers = [self pageViewControllersForRange:theRange];
    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
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
    
    UITapGestureRecognizer *theSingleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:theSingleTapGestureRecognizer];
    
    UITapGestureRecognizer *theDoubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    theDoubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:theDoubleTapGestureRecognizer];
    
    [theSingleTapGestureRecognizer requireGestureRecognizerToFail:theDoubleTapGestureRecognizer];
    
    // set the image directory path
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.imageDirectoryPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@", self.document.title]];
    
    // get the ip address of the phone
    self.ipAddress = [self getIPAddress];
    NSLog(@"%@", self.ipAddress);
    
    // set server's document root directory to be the image directory
    [self.httpServer setDocumentRoot:self.imageDirectoryPath];
    
    // set up notes
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    CPDFPageViewController *theFirstViewController = theViewControllers[0];
    self.notes = [[PWCUtilities alloc] initNotesWithFilename:theFirstViewController.page.document.title
                                 path:path
                              numberOfPages:theFirstViewController.page.document.numberOfPages];
    [self.segmentedControl addTarget:self action:@selector(action:) forControlEvents:UIControlEventValueChanged];
    
    // update title and cast the image of the first page
    [self updateTitleAndCastImage];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(hideChrome) withObject:NULL afterDelay:0.5];
}

- (NSString *)getIPAddress {
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
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr -> ifa_addr) -> sin_addr)];
                    
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

- (void)hideChrome
{
    if (self.chromeHidden == NO)
    {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.navigationController.navigationBar.alpha = 0.0;
            self.previewCollectionView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.chromeHidden = YES;
        }];
    }
}

- (void)toggleChrome
{
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        self.navigationController.navigationBar.alpha = (1.0 - !self.chromeHidden);
        self.previewCollectionView.alpha = (1.0 - !self.chromeHidden);
    } completion:^(BOOL finished) {
        self.chromeHidden = !self.chromeHidden;
    }];
}

- (void)updateTitleAndCastImage
{
    NSArray *theViewControllers = self.pageViewController.viewControllers;
    if (theViewControllers.count == 1) {
        CPDFPageViewController *theFirstViewController = theViewControllers[0];
        NSInteger pageNumber = theFirstViewController.page.pageNumber;
        self.title = [NSString stringWithFormat:@"Page %d", pageNumber];
        // load notes for that page
        [self.noteText setText:[self.notes getNoteAtIndex:(pageNumber - 1)]];
        // cast image of the page
        [self castImageOfPageNumber:pageNumber];
        } else if (theViewControllers.count == 2) {
        CPDFPageViewController *theFirstViewController = theViewControllers[0];
        CPDFPageViewController *theSecondViewController = theViewControllers[1];
        self.title = [NSString stringWithFormat:@"Pages %d-%d", theFirstViewController.page.pageNumber, theSecondViewController.page.pageNumber];
    }
}

- (void)castImageOfPageNumber:(NSInteger)pageNumber
{
    // send images to the device if connected
    if (self.deviceManager && self.deviceManager.isConnected) {
        // search for the image
        NSString *imageName = [NSString stringWithFormat:@"/%d.jpeg", pageNumber];
        NSString *imagePath = [self.imageDirectoryPath stringByAppendingString:imageName];
        NSString *imageWebPath = [NSString stringWithFormat:@"%@%@", self.ipAddress, imagePath];
        
        // load the data
        GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
        GCKMediaInformation *mediaInformation =
        [[GCKMediaInformation alloc] initWithContentID:imageWebPath
                                            streamType:GCKMediaStreamTypeNone
                                           contentType:@"image/jpeg"
                                              metadata:metadata
                                        streamDuration:0
                                            customData:nil];
        
        // cast the image
        [self.mediaControlChannel loadMedia:mediaInformation];
    }
}

- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation
{
    CGRect theBounds = self.view.bounds;
    CGRect theFrame;
    CGRect theMediaBox = [self.document pageForPageNumber:1].mediaBox;
    if ([self canDoubleSpreadForOrientation:inOrientation] == YES) {
        theMediaBox.size.width *= 2;
        theFrame = ScaleAndAlignRectToRect(theMediaBox, theBounds, ImageScaling_Proportionally, ImageAlignment_Center);
    } else {
        theFrame = ScaleAndAlignRectToRect(theMediaBox, theBounds, ImageScaling_Proportionally, ImageAlignment_Center);
    }
    
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

- (NSArray *)pageViewControllersForRange:(NSRange)inRange
{
    NSMutableArray *thePages = [NSMutableArray array];
    for (NSUInteger N = inRange.location; N != inRange.location + inRange.length; ++N)
    {
        //thealch3m1st: if you do this on the last page of a document with an even number of pages it causes the assertion to fail because the last document is not a valid document (number of pages + 1)
        NSUInteger pageNumber = N > self.document.numberOfPages ? 0 : N;
        CPDFPage *thePage = pageNumber > 0 ? [self.document pageForPageNumber:pageNumber] : NULL;
        [thePages addObject:[self pageViewControllerWithPage:thePage]];
    }
    return(thePages);
}

- (BOOL)canDoubleSpreadForOrientation:(UIInterfaceOrientation)inOrientation
{
    if (UIInterfaceOrientationIsPortrait(inOrientation) || self.document.numberOfPages == 1)
    {
        return NO;
    } else {
        return YES;
    }
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
    
    NSRange theRange = { .location = inPage.pageNumber, .length = 1 };
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
    {
        theRange.length = 2;
    }
    NSArray *theViewControllers = [self pageViewControllersForRange:theRange];
    
    UIPageViewControllerNavigationDirection theDirection = inPage.pageNumber > theCurrentPageViewController.pageNumber ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    [self.pageViewController setViewControllers:theViewControllers direction:theDirection animated:YES completion:NULL];
    [self updateTitleAndCastImage];
    
    [self populateCache];
    
    return(YES);
}

- (void)tap:(UITapGestureRecognizer *)inRecognizer
{
    [self toggleChrome];
}

- (void)doubleTap:(UITapGestureRecognizer *)inRecognizer
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

- (IBAction)gotoPage:(id)sender
{
    //    NSUInteger thePageNumber = [self.previewBar.selectedPreviewIndexes firstIndex] + 1;
    //    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    //        {
    //        thePageNumber = thePageNumber / 2 * 2;
    //        }
    //
    //    NSUInteger theLength = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 1 : ( thePageNumber < self.document.numberOfPages ? 2 : 1 );
    //    self.previewBar.selectedPreviewIndexes = [NSIndexSet indexSetWithIndexesInRange:(NSRange){ .location = thePageNumber - 1, .length = theLength }];
    //
    //    [self openPage:[self.document pageForPageNumber:thePageNumber]];
}

- (void)populateCache
{
    //    NSLog(@"POPULATING CACHE")
    
    CPDFPage *theStartPage = (self.pages)[0] != [NSNull null] ? (self.pages)[0] : NULL;
    CPDFPage *theLastPage = [self.pages lastObject] != [NSNull null] ? [self.pages lastObject] : NULL;
    
    NSInteger theStartPageNumber = [theStartPage pageNumber];
    NSInteger theLastPageNumber = [theLastPage pageNumber];
    
    NSInteger pageSpanToLoad = 1;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        pageSpanToLoad = 2;
    }
    
    theStartPageNumber = MAX(theStartPageNumber - pageSpanToLoad, 0);
    theLastPageNumber = MIN(theLastPageNumber + pageSpanToLoad, self.document.numberOfPages);
    
    //    NSLog(@"(Potentially) Fetching: %d - %d", theStartPageNumber, theLastPageNumber);
    
    UIView *thePageView = [(self.pageViewController.viewControllers)[0] pageView];
    if (thePageView == NULL)
    {
        NSLog(@"WARNING: No page view.");
        return;
    }
    CGRect theBounds = thePageView.bounds;
    
    for (NSInteger thePageNumber = theStartPageNumber; thePageNumber <= theLastPageNumber; ++thePageNumber)
    {
        NSString *theKey = [NSString stringWithFormat:@"%d[%d,%d]", thePageNumber, (int)theBounds.size.width, (int)theBounds.size.height];
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

#pragma mark -

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
        //thealch3m1st: if we are in two page mode and the document has an even number of pages if it would just return NULL it woudln't flip to that last page so we have to return a an empty page for the (number of pages + 1)th page.
        if(self.document.numberOfPages % 2 == 0 &&
           theNextPageNumber == self.document.numberOfPages + 1 &&
           self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
            return [self pageViewControllerWithPage:NULL];
        return(NULL);
    }
    
    CPDFPage *thePage = theNextPageNumber > 0 ? [self.document pageForPageNumber:theNextPageNumber] : NULL;
    theViewController = [self pageViewControllerWithPage:thePage];
    
    return(theViewController);
}

#pragma mark -

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed;
{
    [self updateTitleAndCastImage];
    [self populateCache];
    [self hideChrome];
    
    CPDFPageViewController *theFirstViewController = (self.pageViewController.viewControllers)[0];
    if (theFirstViewController.page)
    {
        NSArray *thePageNumbers = [self.pageViewController.viewControllers valueForKey:@"pageNumber"];
        NSMutableIndexSet *theIndexSet = [NSMutableIndexSet indexSet];
        for (NSNumber *thePageNumber in thePageNumbers)
        {
            int N = [thePageNumber integerValue] - 1;
            if (N != 0)
            {
                [theIndexSet addIndex:N];
            }
        }
        //        self.previewBar.selectedPreviewIndexes = theIndexSet;
        [theIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.previewCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }];
    }
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    UIPageViewControllerSpineLocation theSpineLocation;
    NSArray *theViewControllers = NULL;
    
	if (UIInterfaceOrientationIsPortrait(orientation) || self.document.numberOfPages == 1)
    {
		theSpineLocation = UIPageViewControllerSpineLocationMin;
        self.pageViewController.doubleSided = NO;
        
        CPDFPageViewController *theCurrentViewController = (self.pageViewController.viewControllers)[0];
        if (theCurrentViewController.page == NULL)
        {
            theViewControllers = [self pageViewControllersForRange:(NSRange){ 1, 1 }];
        }
        else
        {
            theViewControllers = [self pageViewControllersForRange:(NSRange){ theCurrentViewController.page.pageNumber, 1 }];
        }
    }
    else
    {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
        self.pageViewController.doubleSided = YES;
        
        CPDFPageViewController *theCurrentViewController = (self.pageViewController.viewControllers)[0];
        NSUInteger theCurrentPageNumber = theCurrentViewController.page.pageNumber;
        
        theCurrentPageNumber = theCurrentPageNumber / 2 * 2;
        
        theViewControllers = [self pageViewControllersForRange:(NSRange){ theCurrentPageNumber, 2 }];
    }
    
    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    return(theSpineLocation);
}

#pragma mark -

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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CPDFPage *thePage = [self.document pageForPageNumber:indexPath.item + 1];
    [self openPage:thePage];
}

#pragma mark -

- (void)PDFDocument:(CPDFDocument *)inDocument didUpdateThumbnailForPage:(CPDFPage *)inPage
{
    [self.previewCollectionView reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:inPage.pageNumber - 1 inSection:0] ]];
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


@end
