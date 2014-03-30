//
//  Utilities.m
//  Slidecast
//
//  Created by Chayson Hurst on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCNotes.h"
#import "CPDFDocument.h"
#import "CPDFPage.h"

@interface PWCNotes ()

@property NSString * filePath;
@property NSMutableArray * notes;

@end

@implementation PWCNotes

- (id)initNotesWithFilename:(NSString *)fileName path:(NSString *)path numberOfPages:(int)numberOfPages
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _filePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@/notes.txt", fileName]];
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
    if (!exists)
    {
        // if file does not exist, create one and initialize the content
        _notes = [[NSMutableArray alloc] init];
        [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:nil attributes:nil];
        NSString * emptyString = @"Add Notes Here!";
        for (int i = 0; i < numberOfPages; ++i)
        {
            [self.notes addObject:emptyString];
        }
        // write content of the array to the file
        [self.notes writeToFile:self.filePath atomically:YES];
    }
    else
    {
        // otherwise, load it from the text file
        _notes = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
    }
    
    return self;
}

- (void)addNote:(NSString *)note atIndex:(int)index
{
    [self.notes replaceObjectAtIndex:index withObject:note];
}

- (void)saveNotes
{
    // clear text file if you want to save
    NSFileHandle * writeFile = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
    [writeFile truncateFileAtOffset:0];
    [self.notes writeToFile:self.filePath atomically:YES];
    [writeFile closeFile];
}

- (NSString *)getNoteAtIndex:(int)index
{
    return [self.notes objectAtIndex:index];
}

@end
