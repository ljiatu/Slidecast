//
//  NotesViewController.m
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCNotesViewController.h"

#import "PWCPageContentViewController.h"
#import "PWCNotes.h"

@interface PWCNotesViewController ()

@property (nonatomic) PWCNotes *notes;
@property (nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) NSString *imageDirectoryPath;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *pageTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end

@implementation PWCNotesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title to be white
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _imageDirectoryPath = [path stringByAppendingFormat:@"/%@", self.documentTitle];
    _notes = [[PWCNotes alloc] initNotesWithFilename:self.documentTitle path:path numberOfPages:self.numberOfPages];
    
    // if there is only one slide, disable the next button
    if (self.numberOfPages <= 1) {
        self.nextButton.enabled = NO;
    }
    
    // initialize page view controller
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    // set up the initial scene of the page view controller
    [self setUpPageViewControllerAtIndex:0 direction:UIPageViewControllerNavigationDirectionForward];
    
    // adjust the size of the page view controller, -44 to show the buttons at the bottom
    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 44);
    
    // display the content of the page view controller
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Page View Controller Data Source Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PWCPageContentViewController *)viewController).index;
    if (index == 0 || index == NSNotFound) {
        return nil;
    }
    return [self viewControllerAtIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PWCPageContentViewController *)viewController).index;
    if (index == self.numberOfPages - 1 || index == NSNotFound) {
        return nil;
    }
    return [self viewControllerAtIndex:index + 1];
}

- (PWCPageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    PWCPageContentViewController *viewController =
    [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];
    viewController.index = index;
    return viewController;
}

# pragma mark - Page View Controller Delegate Methods

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    PWCPageContentViewController *viewController = [pendingViewControllers lastObject];
    NSUInteger index = viewController.index;
    // display notes in the text view
    NSString *text = [self.notes getNoteAtIndex:index];
    [viewController.textView setText:text];
    
    // get the corresponding slide
    NSString *imagePath = [self.imageDirectoryPath stringByAppendingFormat:@"/%d.jpeg", index + 1];
    [viewController.slideView setImage:[UIImage imageWithContentsOfFile:imagePath]];
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    PWCPageContentViewController *viewController = [self.pageViewController.viewControllers lastObject];
    NSUInteger index = viewController.index;
    // update title
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %ld", (long)(index + 1)]];
    
    // disable/enable buttons accordingly
    if (index == 1) {
        // if we're transitioning into the second page
        self.previousButton.enabled = YES;
    } else if (index == 0) {
        // if we're transitioning into the first page
        self.previousButton.enabled = NO;
    }
    
    if (index == self.numberOfPages - 1) {
        // if we're trnasitioning into the last page
        self.nextButton.enabled = NO;
    } else if (index == self.numberOfPages - 2) {
        // if we're transitioning into the second last page
        self.nextButton.enabled = YES;
    }
    
    // save notes in the previous view controller
    viewController = [previousViewControllers lastObject];
    index = viewController.index;
    [self.notes addAndSaveNote:viewController.textView.text atIndex:index];
}

- (IBAction)addAndSaveNotes:(id)sender
{
    PWCPageContentViewController *viewController = [self.pageViewController.viewControllers lastObject];
    [self.notes addAndSaveNote:viewController.textView.text atIndex:viewController.index];
    [viewController dismissKeyboard];
}

- (IBAction)prevAction:(id)sender
{
    PWCPageContentViewController *viewController = [self.pageViewController.viewControllers lastObject];
    NSUInteger index = viewController.index;
    
    if (index == 1) {
        // disable previous button if this is the first page
        self.previousButton.enabled = NO;
    }
    if (index == self.numberOfPages - 1) {
        // enable the next button if this is second to last page
        self.nextButton.enabled = YES;
    }
    
    [self.notes addAndSaveNote:viewController.textView.text atIndex:index];
    [self setUpPageViewControllerAtIndex:index - 1 direction:UIPageViewControllerNavigationDirectionReverse];
}

- (IBAction)nextAction:(id)sender
{
    PWCPageContentViewController *viewController = [self.pageViewController.viewControllers lastObject];
    NSUInteger index = viewController.index;
    
    if (index == 0) {
        // enable the previous button if this is the second page
        self.previousButton.enabled = YES;
    }
    if (index == self.numberOfPages - 2) {
        // disable the next button if this is the last page
        self.nextButton.enabled = NO;
    }
    
    [self.notes addAndSaveNote:viewController.textView.text atIndex:index];
    [self setUpPageViewControllerAtIndex:index + 1 direction:UIPageViewControllerNavigationDirectionForward];
}

- (void)setUpPageViewControllerAtIndex:(NSUInteger)index direction:(UIPageViewControllerNavigationDirection)direction
{
    PWCPageContentViewController *viewController = [self viewControllerAtIndex:index];
    [self.pageViewController setViewControllers:@[viewController]
                                      direction:direction
                                       animated:YES
                                     completion:nil];
    [viewController.textView setText:[self.notes getNoteAtIndex:index]];
    
    // get the corresponding slide
    NSString *imagePath = [self.imageDirectoryPath stringByAppendingFormat:@"/%d.jpeg", index + 1];
    [viewController.slideView setImage:[UIImage imageWithContentsOfFile:imagePath]];

    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %lu", (unsigned long)(index + 1)]];
}

@end
