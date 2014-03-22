//
//  NotesViewController.m
//  Slidecast
//
//  Created by moea on 3/17/14.
//  Copyright (c) 2014 toxicsoftware.com. All rights reserved.
//

#import "PWCNotesViewController.h"
#import "PWCUtilities.h"

@interface PWCNotesViewController ()

@property PWCUtilities * notes;
@property int index;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *noteText;

@end

@implementation PWCNotesViewController

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
	// load notes
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.notes      = [[PWCUtilities alloc] initNotesWithFilename:self.docTitle path:path numberOfPages:self.numberOfPages];
    self.index      = 0;
    NSString * text = [self.notes getNoteAtIndex:self.index];
    if ([text isEqualToString:@"empty"])
    {
        [self.noteText setText:@"Add Notes Here!"];
    }
    else
    {
        [self.noteText setText:text];
    }
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %d", (self.index + 1)]];
    
    // disable previous button
    self.previousButton.enabled = NO;
    if(self.numberOfPages <= 1) {
        self.nextButton.enabled = NO;
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
    if ([text isEqualToString:@"empty"])
    {
        [self.noteText setText:@"Add Notes Here!"];
    }
    else
    {
        [self.noteText setText:text];
    }
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %d", (self.index + 1)]];
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
    if ([text isEqualToString:@"empty"])
    {
        [self.noteText setText:@"Add Notes Here!"];
    }
    else
    {
        [self.noteText setText:text];
    }
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %d", (self.index + 1)]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if([sender tag] == 1)
    {
        [self.notes addNote:self.noteText.text atIndex:self.index];
        [self.notes saveNotes];
    }
}

@end
