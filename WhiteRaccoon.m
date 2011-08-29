//  WhiteRaccoon
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "WhiteRaccoon.h"










/*======================================================WRBase============================================================*/

@implementation WRBase
@synthesize passive, password, username, schemeId;



static NSMutableDictionary *folders;

+ (void)initialize
{    
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        folders = [[NSMutableDictionary alloc] init];
    }
}


+(NSDictionary *) cachedFolders {
    return folders;
}

+(void) addFoldersToCache:(NSArray *) foldersArray forParentFolderPath:(NSString *) key {
    [folders setObject:foldersArray forKey:key];
}


- (id)init {
    self = [super init];
    if (self) {
        self.schemeId = kWRFTP;
        self.passive = NO;
        self.password = nil;
        self.username = nil;
        self.hostname = nil;
        self.path = @"";
    }
    return self;
}

-(NSURL*) fullURL {
    // first we merge all the url parts into one big and beautiful url
    NSString * fullURLString = [self.scheme stringByAppendingFormat:@"%@%@%@%@", @"://", self.credentials, self.hostname, self.path];       
    return [NSURL URLWithString:fullURLString];
}

-(NSString *)path {
    //  we remove all the extra slashes from the directory path, including the last one (if there is one)
    //  we also escape it
    NSString * escapedPath = [[path stringByStandardizingPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];   
    
    
    //  we need the path to be absolute, if it's not, we *make* it
    if (![escapedPath isAbsolutePath]) {
        escapedPath = [@"/" stringByAppendingString:escapedPath];
    }
    
    return escapedPath;
}


-(void) setPath:(NSString *)directoryPathLocal {
    [directoryPathLocal retain];
    [path release];
    path = directoryPathLocal;
}



-(NSString *)scheme {
    switch (self.schemeId) {
        case kWRFTP:
            return @"ftp";
            break;
    }
    
    return @"";
}

-(NSString *) hostname {
    return [hostname stringByStandardizingPath];
}

-(void)setHostname:(NSString *)hostnamelocal {
    [hostnamelocal retain];
    [hostname release];
    hostname = hostnamelocal;
}

-(NSString *) credentials {    
    
    NSString * cred;
    
    if (self.username!=nil) {
        if (self.password!=nil) {
            cred = [NSString stringWithFormat:@"%@:%@@", self.username, self.password];
        }else{
            cred = [NSString stringWithFormat:@"%@@", self.username];
        }
    }else{
        cred = @"";
    }
    
    return [[cred stringByStandardizingPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
}




-(void) start{
}

-(void) destroy{
    
}

- (void)dealloc {
    [password release];
    [hostname release];
    [username release];
    [path release];
    [super dealloc];
}

@end






/*======================================================WRRequestQueue============================================================*/

@implementation WRRequestQueue
@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        headRequest = nil;
        tailRequest = nil;
    }
    return self;
}

-(void) addRequest:(WRRequest *) request{
    
    request.delegate = self;
    if(!request.passive)request.passive = self.passive;
    if(!request.password)request.password = self.password;
    if(!request.username)request.username = self.username;
    if(!request.hostname)request.hostname = self.hostname;
    
    if (tailRequest == nil){
        [request retain];
        tailRequest = request;
    }else{
        [request retain];
        
        
        tailRequest.nextRequest = request;
        request.prevRequest = tailRequest;
        
        
        [tailRequest release];
        tailRequest = request;
    }
    
    if (headRequest == nil) {
        [tailRequest retain];
        headRequest = tailRequest;        
    }    
}

-(void) addRequestInFront:(WRRequest *) request {
    request.delegate = self;
    if(!request.passive)request.passive = self.passive;
    if(!request.password)request.password = self.password;
    if(!request.username)request.username = self.username;
    if(!request.hostname)request.hostname = self.hostname;
    
    if (headRequest == nil) {
        [request retain];
        headRequest = request;
    }else{
        [request retain];
        
        headRequest.prevRequest = request;
        request.nextRequest = headRequest;
        
        [headRequest release];
        headRequest = request;
    }
    
    if (tailRequest == nil) {
        [headRequest retain];
        tailRequest = headRequest;        
    }
}

-(void) addRequestsFromArray: (NSArray *) array{
    
}

-(void) removeRequestFromQueue:(WRRequest *) request {
    
    if ([headRequest isEqual:request]) {
        [request.nextRequest retain];
        [headRequest release];
        headRequest = request.nextRequest;
    }
    
    if ([tailRequest isEqual:request]) {
        [request.nextRequest retain];
        [tailRequest release];
        tailRequest = request.prevRequest;
    }
    
    request.prevRequest.nextRequest = request.nextRequest;
    request.nextRequest.prevRequest = request.prevRequest;
    
    request.nextRequest = nil;
    request.prevRequest = nil;
}

-(void) start{
    [super start];
    [headRequest start];
}

-(void) destroy{
    [super destroy];
    [headRequest destroy];
    headRequest.nextRequest = nil;
}


// delegate methods

-(void) requestCompleted:(WRRequest *) request {
    
    [self.delegate requestCompleted:request];
    
    [headRequest.nextRequest retain];
    [headRequest release];
    headRequest = headRequest.nextRequest;
    
    [headRequest start];
}

-(void) requestFailed:(WRRequest *) request{
    
    [self.delegate requestFailed:request];
}

-(BOOL) shouldOverwriteFileWithRequest:(WRRequest *)request {
    if (![self.delegate respondsToSelector:@selector(shouldOverwriteFileWithRequest:)]) {
        return NO;
    }else{
        return [self.delegate shouldOverwriteFileWithRequest:request];
    }
}



-(void)dealloc {
    [headRequest release];
    [tailRequest release];
    [delegate release];
    [super dealloc];
}

@end














/*======================================================WRRequest============================================================*/

@implementation WRRequest
@synthesize type, error, nextRequest, prevRequest, delegate;

-(void)destroy {
    streamInfo.bytesConsumedThisIteration = 0;
    streamInfo.bytesConsumedInTotal = 0;
}

-(void)dealloc {
    [error release];
    [nextRequest release];
    [prevRequest release];
    [delegate release];
    
    [super dealloc];
}

@end















/*======================================================WRRequestDownload============================================================*/

@implementation WRRequestDownload
@synthesize receivedData;

-(WRRequestTypes)type {
    return kWRDownloadRequest;
}



-(void) start{    
    [super start];
    
    if (self.hostname==nil) {
        NSLog(@"the address is nil error");
        [self.delegate requestFailed:self];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)self.fullURL);
    streamInfo.readStream = (NSInputStream *)readStreamRef;
    
    if (streamInfo.readStream==nil) {
        NSLog(@"the address is incorect");
        [self.delegate requestFailed:self];
        return;
    }
    
    
    streamInfo.readStream.delegate = self;
	[streamInfo.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[streamInfo.readStream open];
}

//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            streamInfo.bytesConsumedInTotal = 0;
            self.receivedData = [NSMutableData data];
        } break;
        case NSStreamEventHasBytesAvailable: {
            
            streamInfo.bytesConsumedThisIteration = [streamInfo.readStream read:streamInfo.buffer maxLength:kWRDefaultBufferSize];
            
            if (streamInfo.bytesConsumedThisIteration!=-1) {
                if (streamInfo.bytesConsumedThisIteration==0) {  
                    [self.delegate requestCompleted:self]; 
                    [self destroy]; 
                }else{
                    [self.receivedData appendBytes:streamInfo.buffer length:streamInfo.bytesConsumedThisIteration]; 
                }
            }else{
                NSLog(@"Stream read failed. Abort!");
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"errror: %@", [theStream streamError]);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
            
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream was intrerupted by server");
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
    }
}

-(void) destroy{
    [super destroy];
    
    [streamInfo.readStream close];
    [streamInfo.readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [streamInfo.readStream release];
    streamInfo.readStream = nil;    
}

-(void)dealloc {
    [receivedData release];
    [super dealloc];
}

@end

















/*======================================================WRRequestUpload============================================================*/

@interface WRRequestUpload () //note the empty category name
-(void)upload;
@end

@implementation WRRequestUpload
@synthesize listrequest, sentData;

-(WRRequestTypes)type {
    return kWRUploadRequest;
}

-(void) start{    
    [super start];
    
    if (self.hostname==nil) {
        NSLog(@"the address is nil error");
        [self.delegate requestFailed:self];
        return;
    }   
    
    //we first list the directory to see if our folder is up already
    
    self.listrequest = [[[WRRequestListDir alloc] init] autorelease];    
    self.listrequest.path = [self.path stringByDeletingLastPathComponent];
    self.listrequest.hostname = self.hostname;
    self.listrequest.username = self.username;
    self.listrequest.password = self.password;
    self.listrequest.delegate = self;
    [self.listrequest start];
}

-(void) requestCompleted:(WRRequest *) request{
    
    BOOL fileAlreadyExists = NO;
    NSString * fileName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    for (NSDictionary * file in self.listrequest.filesInfo) {
        NSString * name = [file objectForKey:(id)kCFFTPResourceName];
        if ([fileName isEqualToString:name]) {
            fileAlreadyExists = YES;
        }
    }
    
    
    if (fileAlreadyExists) {
        if (![self.delegate shouldOverwriteFileWithRequest:self]) {
            NSLog(@"There is already an file/folder with that name and you decided not to overwrite!");
            [self.delegate requestFailed:self];
        }else{
            //unfortunately, for FTP there is no current solution for deleting/overwriting a folder (or I was not able to find one yet)
            //it will fail with permission error
            [self upload];
        }
    }else{
        [self upload];
    }    
}


-(void) requestFailed:(WRRequest *) request{
    NSLog(@"listing had failed");
    [self.delegate requestFailed:self];
}

-(void)upload {
    // a little bit of C because I was not able to make NSInputStream play nice
    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef)self.fullURL);
    streamInfo.writeStream = (NSOutputStream *)writeStreamRef;
    
    if (streamInfo.writeStream==nil) {
        NSLog(@"the address is incorect");
        [self.delegate requestFailed:self];
        return;
    }
    
    if (self.sentData==nil&&self.type==kWRUploadRequest) {
        NSLog(@"the sending data is nil my friend, you need to put up something");
        [self.delegate requestFailed:self];
        return;
    }
    
    streamInfo.writeStream.delegate = self;
	[streamInfo.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[streamInfo.writeStream open];
}


//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            streamInfo.bytesConsumedInTotal = 0;            
        } break;
        case NSStreamEventHasBytesAvailable: {
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
            streamInfo.bytesConsumedThisIteration = [streamInfo.writeStream write:&((const uint8_t *)self.sentData.bytes)[streamInfo.bytesConsumedInTotal] maxLength:kWRDefaultBufferSize];
            
            if (streamInfo.bytesConsumedThisIteration!=-1) {
                if (streamInfo.bytesConsumedInTotal + streamInfo.bytesConsumedThisIteration>=self.sentData.length) {
                    [self.delegate requestCompleted:self]; 
                    [self destroy];
                    
                    [self.sentData replaceBytesInRange:NSMakeRange(0, self.sentData.length) withBytes:NULL length:0];
                }else{
                    streamInfo.bytesConsumedInTotal += streamInfo.bytesConsumedThisIteration;
                }
            }else{
                NSLog(@"Stream read failed. Abort!");
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"errror: %@", [theStream streamError]);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
            
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream was intrerupted by server");
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
    }
}



-(void) destroy{
    [super destroy];
    
    [listrequest release];
    [sentData release];
    [streamInfo.writeStream close];
    [streamInfo.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [streamInfo.writeStream release];
    streamInfo.writeStream = nil;    
}

@end




















/*======================================================WRRequestCreateDirectory============================================================*/

@implementation WRRequestCreateDirectory

-(WRRequestTypes)type {
    return kWRCreateDirectoryRequest;
}

-(NSString *)path {
    //  the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    return [[super path] stringByAppendingString:@"/"];
}

-(void) upload {
    [super upload];
    streamInfo.writeStream.delegate = self;
}


//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            
        } break;
        case NSStreamEventHasBytesAvailable: {
        
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"errror: %@", [theStream streamError]);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
        case NSStreamEventEndEncountered: {
            [self.delegate requestCompleted:self];
            [self destroy];
        } break;
    }
}

@end














/*======================================================WRRequestListDir============================================================*/

@implementation WRRequestListDir
@synthesize filesInfo;


-(WRRequestTypes)type {
    return kWRListDirectoryRequest;
}

-(NSString *)path {
    //  the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    return [[super path] stringByAppendingString:@"/"];
}

-(void) start {
    [super start];
    streamInfo.readStream.delegate = self;
}

//stream delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
			self.filesInfo = [NSMutableArray array];
        } break;
        case NSStreamEventHasBytesAvailable: {
            
            
            streamInfo.bytesConsumedThisIteration = [streamInfo.readStream read:streamInfo.buffer maxLength:kWRDefaultBufferSize];
            
            if (streamInfo.bytesConsumedThisIteration!=-1) {
                if (streamInfo.bytesConsumedThisIteration==0) {
                   [WRBase addFoldersToCache:self.filesInfo forParentFolderPath:self.path];  
                   [self.delegate requestCompleted:self]; 
                   [self destroy]; 
                }else{
                    NSUInteger  offset = 0;
                    CFIndex     parsedBytes;
                    
                    do {        
                        
                        CFDictionaryRef listingEntity = NULL;
                        
                        parsedBytes = CFFTPCreateParsedResourceListing(NULL, &streamInfo.buffer[offset], streamInfo.bytesConsumedThisIteration - offset, &listingEntity);
                        
                        if (parsedBytes > 0) {
                            if (listingEntity != NULL) {            
                                [self.filesInfo addObject:(NSDictionary *)listingEntity];                            
                            }            
                            offset += parsedBytes;            
                        }
                        
                        if (listingEntity != NULL) {            
                            CFRelease(listingEntity);            
                        }                    
                    } while (parsedBytes>0); 
                }
            }else{
                NSLog(@"Stream read failed. Abort!");
                [self.delegate requestFailed:self];
                [self destroy];
            }
            
            
        } break;
        case NSStreamEventHasSpaceAvailable: {
            
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"errror: %@", [theStream streamError]);
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
        case NSStreamEventEndEncountered: {
            [self.delegate requestFailed:self];
            [self destroy];
        } break;
    }
}


-(void)dealloc {    
    [filesInfo release];
    [super dealloc];
}

@end

