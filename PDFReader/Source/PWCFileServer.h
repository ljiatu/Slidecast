//
//  PWCFileServer.h
//  Slidecast
//
//  Created by Jiatu Liu on 3/26/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import <Foundation/Foundation.h>

// Singleton File Server
@interface PWCFileServer : NSObject

+ (id)getSharedServer;
- (UInt16)listeningPort;

@end
