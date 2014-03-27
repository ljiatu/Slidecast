//
//  Utilities.h
//  Slidecast
//
//  Created by Chayson Hurst on 3/17/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWCNotes : NSObject

- (id)initNotesWithFilename:(NSString *)fileName path:(NSString *)path numberOfPages:(int)numberOfPages;
- (void)addNote:(NSString *) note atIndex:(int) index;
- (void)saveNotes;
- (NSString *)getNoteAtIndex:(int) index;

@end
