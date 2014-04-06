//
//  NotesViewController.m
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCNotesViewController.h"
#import "PWCNotes.h"

@interface PWCNotesViewController ()

@property PWCNotes * notes;
@property NSInteger index;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *noteText;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end

@implementation PWCNotesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _notes = [[PWCNotes alloc] initNotesWithFilename:self.docTitle path:path numberOfPages:self.numberOfPages];
    _index = 0;
    NSString * text = [self.notes getNoteAtIndex:self.index];
    [self.noteText setText:text];
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %ld", (long)(self.index + 1)]];
    
    // if there is only one slide, disable the next button
    if (self.numberOfPages <= 1) {
        self.nextButton.enabled = NO;
    }

    // set the note text delegate to the view controller
    self.noteText.delegate = self;
}

- (IBAction)addAndSaveNotes:(id)sender
{
    [self.notes addNote:self.noteText.text atIndex:self.index];
    [self.notes saveNotes];
    if ([self.noteText isFirstResponder]) {
        // dismiss the keyboard when hitting save
        [self.noteText resignFirstResponder];
    }
}

- (IBAction)handleRightSwipe
{
    if (self.index > 0) {
        // go to the previous page if this is not the first page
        NSString * text = [self.notes getNoteAtIndex:(--self.index)];
        [self.noteText setText:text];
        [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %ld", (long)(self.index + 1)]];
    }
}

- (IBAction)handleLeftSwipe
{
    if (self.index < self.numberOfPages - 1) {
        // go to the next page if this is not the last page
        NSString * text = [self.notes getNoteAtIndex:(++self.index)];
        [self.noteText setText:text];
        [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %ld", (long)(self.index + 1)]];
    }
}

- (IBAction)prevAction:(id)sender
{
    if (self.index == 1)
    {
        // disable previous button if this is the first page
        self.previousButton.enabled = NO;
    }
    if (self.index == self.numberOfPages - 1)
    {
        // enable the next button if this is second to last page
        self.nextButton.enabled = YES;
    }
    
    [self.notes addNote:self.noteText.text atIndex:self.index];
    [self.notes saveNotes];
    --self.index;
    NSString * text = [self.notes getNoteAtIndex:self.index];
    [self.noteText setText:text];
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %ld", (long)(self.index + 1)]];
}

- (IBAction)nextAction:(id)sender
{
    if (self.index == 0)
    {
        // enable the previous button if this is the second page
        self.previousButton.enabled = YES;
    }
    if (self.index == self.numberOfPages - 2)
    {
        // disable the next button if this is the last page
        self.nextButton.enabled = NO;
    }
    
    [self.notes addNote:self.noteText.text atIndex:self.index];
    [self.notes saveNotes];
    ++self.index;
    NSString * text = [self.notes getNoteAtIndex:self.index];
    [self.noteText setText:text];
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %ld", (long)(self.index + 1)]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
