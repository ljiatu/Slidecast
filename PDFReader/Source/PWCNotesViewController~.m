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
@property (weak, nonatomic) IBOutlet UIToolbar *nextButton;
@property (weak, nonatomic) IBOutlet UIToolbar *prevButton;
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
	//load notes
    self.notes      = [[PWCUtilities alloc] init];
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
        NSUserDomainMask, YES) lastObject];
    NSLog(@"%@\n", self.docTitle);
    [self.notes openNotesWithFilename:self.docTitle andPath:path
        andPageNum:self.pageNum];
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
    [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %d",
        (self.index + 1)]];
}

- (IBAction)prevAction:(id)sender
{
    if (self.index == 0)
    {
        //do nothing
    }
    else
    {
        [self.notes addNote:self.noteText.text atIndex:self.index];
        [self.notes saveNotes];
        self.index--;
        NSString * text = [self.notes getNoteAtIndex:self.index];
        if([text isEqualToString:@"empty"])
        {
            [self.noteText setText:@"Add Notes Here!"];
        }
        else
        {
            [self.noteText setText:text];
        }
        [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %d",
            (self.index + 1)]];
    }
}

- (IBAction)nextAction:(id)sender
{
    NSLog(@"blow me\n");
    if (self.index == self.pageNum)
    {
        //do nothing
    }
    else
    {
        [self.notes addNote:self.noteText.text atIndex:self.index];
        [self.notes saveNotes];
        self.index++;
        NSString * text = [self.notes getNoteAtIndex:self.index];
        if([text isEqualToString:@"empty"])
        {
            [self.noteText setText:@"Add Notes Here!"];
        }
        else
        {
            [self.noteText setText:text];
        }
        [self.pageTitle setTitle:[NSString stringWithFormat:@"Notes for slide %d",
            (self.index + 1)]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if([sender tag] == 1)
    {
        NSLog(@"saved\n");
        [self.notes addNote:self.noteText.text atIndex:self.index];
        [self.notes saveNotes];
    }
}

@end
