//
//  Utilities.h
//  Slidecast
//
//  Created by Chayson Hurst on 3/17/14.
//  Copyright (c) 2014 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWCUtilities : NSObject

- (void) openNotesWithFilename:(NSString *) fileName andPath:(NSString *) pathName
                    andPageNum:(int) size;
- (void) addNote:(NSString *) note atIndex:(int) index;
- (void) saveNotes;
- (NSString *) getNoteAtIndex:(int) index;

@end
