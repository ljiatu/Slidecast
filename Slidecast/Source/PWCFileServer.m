//
//  PWCFileServer.m
//  Slidecast
//
//  Created by Jiatu Liu on 3/26/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCFileServer.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "HTTPServer.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface PWCFileServer ()

@property (nonatomic) HTTPServer *httpServer;

@end

@implementation PWCFileServer

# pragma mark Singleton Getter

- (UInt16)listeningPort
{
    return [self.httpServer listeningPort];
}

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    // set up http server
    // Configure our logging framework.
    // To keep things simple and fast, we're just going to log to the Xcode console.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Create server using our custom MyHTTPServer class
    _httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [self.httpServer setType:@"_http._tcp."];
    
    // Normally there's no need to run our server on any specific port.
    // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
    // However, for easy testing you may want force a certain port so you can just hit the refresh button.
    // [httpServer setPort:12345];
    
    // Serve files from our cache folder
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    [self.httpServer setDocumentRoot:[directories lastObject]];
    [self startServer];
    
    return self;
}

- (void)startServer
{
    // Start the server (and check for problems)
	NSError *error;
	if([self.httpServer start:&error])
	{
		DDLogInfo(@"Started HTTP Server on port %hu", [self.httpServer listeningPort]);
	}
	else
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
}

- (void)stopServer
{
    [self.httpServer stop];
}

@end
