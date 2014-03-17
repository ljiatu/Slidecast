//
//  Utilities.m
//  Slidecast
//
//  Created by Chayson Hurst on 3/17/14.
//  Copyright (c) 2014 toxicsoftware.com. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

- (id)init
{
    self = [super init];
    _notes = [[NSMutableArray alloc] init];
    _filePath = [[NSString alloc] init];
    return self;
}

- (void) openNotesWithFilename:(NSString *)fileName andPath:(NSString *)pathName
{
    //error testing job of caller
    self.filePath = [pathName stringByAppendingString:fileName];
    NSString * fileContent = [NSString stringWithContentsOfFile:self.filePath encoding:NSUTF8StringEncoding error:nil];
    self.notes = [[fileContent componentsSeparatedByString:[NSCharacterSet newlineCharacterSet]] mutableCopy];
}

- (void) addNote:(NSString *)note atIndex:(int)index
{
    [self.notes replaceObjectAtIndex:index withObject:note];
}

- (void) saveNotes
{
    //error testing job of caller
    //clear text file if you want to save
    for (int i = 0; i < [self.notes count]; i++)
    {
        [[self.notes objectAtIndex:i] writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [@"\n" writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (NSString *) getNoteAtIndex:(int)index
{
    return [self.notes objectAtIndex:index];
}

@end
