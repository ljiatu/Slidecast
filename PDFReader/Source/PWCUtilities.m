//
//  Utilities.m
//  Slidecast
//
//  Created by Chayson Hurst on 3/17/14.
//  Copyright (c) 2014 toxicsoftware.com. All rights reserved.
//

#import "PWCUtilities.h"
#import "CPDFDocument.h"
#import "CPDFPage.h"

@interface PWCUtilities()

@property NSMutableArray * notes;
@property NSString * filePath;

@end

@implementation PWCUtilities

- (id)initNotesWithFilename:(NSString *)fileName path:(NSString *)path numberOfPages:(int)numberOfPages
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _notes = [[NSMutableArray alloc] init];
    _filePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@/notes.txt", fileName]];
    
    BOOL checkFile = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
    if (checkFile == NO)
    {
        // make the text file and initialize array size
        [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:nil attributes:nil];
        // set notes to be nil for everything right now
        NSFileHandle * newFile = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
        NSString * emptyString = @"empty\n";
        NSData * emptyData = [emptyString dataUsingEncoding:NSUTF8StringEncoding];
        for (int i = 0; i < numberOfPages; ++i)
        {
            [self.notes addObject:emptyString];
            [newFile writeData:emptyData];
        }
    }
    else
    {
        NSString * fileContent = [NSString stringWithContentsOfFile:self.filePath
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil];
        self.notes = [[fileContent componentsSeparatedByString:@"\n"] mutableCopy];
        NSLog(@"number of notes page %d", self.notes.count);
        for(int i = 0; i < self.notes.count; ++i) {
            NSLog(@"Notes for this page: %@", [self.notes objectAtIndex:i]);
            if([[self.notes objectAtIndex:i] isEqualToString:@""]) {
                NSLog(@"Yes");
            }
        }
    }
    
    return self;
}

- (void)addNote:(NSString *)note atIndex:(int)index
{
    NSLog(@"%@\n", note);
    [self.notes replaceObjectAtIndex:index withObject:note];
}

- (void)saveNotes
{
    // error testing job of caller
    // clear text file if you want to save
    NSFileHandle * writeFile = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
    [writeFile truncateFileAtOffset:0];
    int notesCount = [self.notes count];
    NSLog(@"%d", notesCount);
    for (int i = 0; i < notesCount; ++i)
    {
        NSString * writeString = [[self.notes objectAtIndex:i] stringByAppendingString:@"\n"];
        NSData * writeData = [writeString dataUsingEncoding:NSUTF8StringEncoding];
        [writeFile writeData:writeData];
    }
    [writeFile closeFile];
}

- (NSString *)getNoteAtIndex:(int)index
{
    return [self.notes objectAtIndex:index];
}

@end
