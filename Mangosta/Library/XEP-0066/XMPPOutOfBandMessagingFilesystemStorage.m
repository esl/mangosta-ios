//
//  XMPPOutOfBandMessagingFilesystemStorage.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 01/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOutOfBandMessagingFilesystemStorage.h"
@import MobileCoreServices;

@interface XMPPOutOfBandMessagingFilesystemStorage ()

@property (copy, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) NSFileManager *fileManager;

@end

@interface XMPPOutOfBandMessagingFilesystemStorageEntry ()

- (instancetype)initWithKind:(XMPPOutOfBandMessagingFilesystemStorageEntryKind)kind data:(NSData *)data MIMEType:(NSString *)MIMEType transferComplete:(BOOL)isTransferComplete;

@end

@interface NSString (XMPPOutOfBandMessagingFilesystemStorage)

@property (readonly) NSString *stringByApplyingFilenameSafeTransform;

@end

@interface NSURL (XMPPOutOfBandMessagingFilesystemStorage)

@property (readonly) NSString *inferredMIMEType;

@property (readonly) NSURL *URLByAppendingMessagePathExtension;
@property (readonly) NSURL *URLByAppendingUploadMarkerPathExtension;
@property (readonly) NSURL *URLByAppendingDownloadMarkerPathExtension;
@property (readonly) NSURL *URLByAppendingCompletionMarkerPathExtension;

- (NSURL *)URLByAppendingPathExtensionForMIMEType:(NSString *)MIMEType;

@end

@interface NSFileManager (XMPPOutOfBandMessagingFilesystemStorage)

- (NSString *)pathToResourceAtURL:(NSURL *)resourceURL relativeToDirectoryAtURL:(NSURL *)referenceDirectoryURL error:(NSError *__autoreleasing *)error;
- (BOOL)establishSymbolicLinkAtURL:(NSURL *)url withDestinationURL:(NSURL *)destURL error:(NSError * __autoreleasing *)error;

@end

@implementation XMPPOutOfBandMessagingFilesystemStorage

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithIdentifier:@"default"];
}

- (XMPPOutOfBandMessagingFilesystemStorageEntry *)entryForTransferIdentifier:(NSString *)transferIdentifier
{
    NSURL *dataFileURL = [self dataFileURLForIndexKey:transferIdentifier];
    if (!dataFileURL) {
        return nil;
    }
    
    XMPPOutOfBandMessagingFilesystemStorageEntryKind entryKind;
    if ([self.fileManager fileExistsAtPath:[dataFileURL URLByAppendingUploadMarkerPathExtension].path]) {
        entryKind = XMPPOutOfBandMessagingFilesystemStorageEntryKindUpload;
    } else if ([self.fileManager fileExistsAtPath:[dataFileURL URLByAppendingDownloadMarkerPathExtension].path]) {
        entryKind = XMPPOutOfBandMessagingFilesystemStorageEntryKindDownload;
    } else {
        return nil;
    }
    
    BOOL isEntryTransferComplete = [self.fileManager fileExistsAtPath:dataFileURL.URLByAppendingCompletionMarkerPathExtension.path];
    
    NSData *entryData;
    if (entryKind == XMPPOutOfBandMessagingFilesystemStorageEntryKindUpload || isEntryTransferComplete) {
        NSError *error;
        entryData = [[NSData alloc] initWithContentsOfURL:dataFileURL options:NSDataReadingMappedIfSafe error:&error];
        if (!entryData) {
            [self reportError:error];
            return nil;
        }
    } else {
        entryData = nil;
    }
    NSString *entryMIMEType = dataFileURL.inferredMIMEType;
    
    return [[XMPPOutOfBandMessagingFilesystemStorageEntry alloc] initWithKind:entryKind data:entryData MIMEType:entryMIMEType transferComplete:isEntryTransferComplete];
}

- (NSArray<XMPPMessage *> *)pendingMessagesForDestinationJID:(XMPPJID *)destinationJID
{
    NSArray *dataFileURLs = [self dataFileURLsForCollectionKey:[destinationJID bare]];
    
    NSMutableArray *pendingMessages = [NSMutableArray array];
    for (NSURL *dataFileURL in dataFileURLs) {
        if ([self.fileManager fileExistsAtPath:dataFileURL.URLByAppendingCompletionMarkerPathExtension.path]) {
            continue;
        }
        
        XMPPMessage *message;
        @try {
            message = [NSKeyedUnarchiver unarchiveObjectWithFile:dataFileURL.URLByAppendingMessagePathExtension.path];
        }
        @catch (NSException *exception) {}
        
        if (!message) {
            [self reportError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSFilePathErrorKey: dataFileURL.URLByAppendingMessagePathExtension.path}]];
            continue;
        }
        
        [pendingMessages addObject:message];
    }
    
    return pendingMessages;
}

- (void)prepareForUploadWithIdentifier:(NSString *)transferIdentifier MIMEType:(NSString *)MIMEType message:(XMPPMessage *)message
{
    [self prepareStorageForEntryOfKind:XMPPOutOfBandMessagingFilesystemStorageEntryKindUpload withIdentifier:transferIdentifier MIMEType:MIMEType message:message];
}

- (void)prepareForDownloadWithIdentifier:(NSString *)transferIdentifier MIMEType:(NSString *)MIMEType message:(XMPPMessage *)message
{
    [self prepareStorageForEntryOfKind:XMPPOutOfBandMessagingFilesystemStorageEntryKindDownload withIdentifier:transferIdentifier MIMEType:MIMEType message:message];
}

- (void)prepareStorageForEntryOfKind:(XMPPOutOfBandMessagingFilesystemStorageEntryKind)entryKind withIdentifier:(NSString *)transferIdentifier MIMEType:(NSString *)MIMEType message:(XMPPMessage *)message
{
    NSError *error;
    NSURL *dataFileURL = [self uniqueDataFileURLForMIMEType:MIMEType];
    
    if (![self.fileManager createDirectoryAtURL:dataFileURL.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:&error]) {
        [self reportError:error];
        return;
    }
    
    if (![[NSData data] writeToURL:dataFileURL options:0 error:&error]) {
        [self reportError:error];
        return;
    }
    
    NSURL *messageFileURL = dataFileURL.URLByAppendingMessagePathExtension;
    @try {
        [NSKeyedArchiver archiveRootObject:message toFile:messageFileURL.path];
    }
    @catch (NSException *exception) {
        [self reportError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey: messageFileURL.path}]];
        return;
    }
    
    NSURL *entryKindMarkerURL;
    switch (entryKind) {
        case XMPPOutOfBandMessagingFilesystemStorageEntryKindUpload:
            entryKindMarkerURL = dataFileURL.URLByAppendingUploadMarkerPathExtension;
            break;
            
        case XMPPOutOfBandMessagingFilesystemStorageEntryKindDownload:
            entryKindMarkerURL = dataFileURL.URLByAppendingDownloadMarkerPathExtension;
            break;
    }
    if (![[NSData data] writeToURL:entryKindMarkerURL options:0 error:&error]) {
        [self reportError:error];
        return;
    }
    
    NSURL *indexURL = [self indexURLForKey:transferIdentifier];
    NSURL *collectionItemURL = [[self collectionURLForKey:[[message to] bare]] URLByAppendingPathComponent:dataFileURL.lastPathComponent];
    
    for (NSURL *symbolicLinkURL in @[indexURL, collectionItemURL]) {
        NSURL *symbolicLinkDirectoryURL = symbolicLinkURL.URLByDeletingLastPathComponent;
        if (![self.fileManager createDirectoryAtURL:symbolicLinkDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            [self reportError:error];
            continue;
        }
        
        NSString *dataFileRelativePath = [self.fileManager pathToResourceAtURL:dataFileURL relativeToDirectoryAtURL:symbolicLinkDirectoryURL error:&error];
        if (!dataFileRelativePath) {
            [self reportError:error];
            continue;
        }
        NSURL *dataFileRelativeURL = [[NSURL alloc] initWithString:dataFileRelativePath];
        
        if (![self.fileManager establishSymbolicLinkAtURL:symbolicLinkURL withDestinationURL:dataFileRelativeURL error:&error]) {
            [self reportError:error];
        }
    }
}

- (void)appendDataChunk:(NSData *)dataChunk forTransferWithIdentifier:(NSString *)transferIdentifier
{
    NSURL *dataFileURL = [self dataFileURLForIndexKey:transferIdentifier];
    if (!dataFileURL) {
        return;
    }
    
    NSError *error;
    NSFileHandle *dataFileHandle = [NSFileHandle fileHandleForWritingToURL:dataFileURL error:&error];
    if (!dataFileHandle) {
        [self reportError:error];
        return;
    }
    
    @try {
        [dataFileHandle seekToEndOfFile];
        [dataFileHandle writeData:dataChunk];
    }
    @catch (NSException *exception) {
        [self reportError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey: dataFileURL.path}]];
    }
}

- (void)registerCompletionForTransferWithIdentifier:(NSString *)transferIdentifier
{
    NSURL *completionMarkerURL = [self dataFileURLForIndexKey:transferIdentifier].URLByAppendingCompletionMarkerPathExtension;
    if (!completionMarkerURL) {
        return;
    }
    NSError *error;
    if (![[NSData data] writeToURL:completionMarkerURL options:0 error:&error]) {
        [self reportError:error];
    }
}

- (NSURL *)uniqueDataFileURLForMIMEType:(NSString *)MIMEType
{
    return [[[self storageRootDirectoryURL] URLByAppendingPathComponent:[NSUUID UUID].UUIDString] URLByAppendingPathExtensionForMIMEType:MIMEType];
}

- (NSURL *)indexURLForKey:(NSString *)key
{
    return [[[self storageRootDirectoryURL]
             URLByAppendingPathComponent:@"index" isDirectory:YES]
            URLByAppendingPathComponent:key.stringByApplyingFilenameSafeTransform];
}

- (NSURL *)collectionURLForKey:(NSString *)key
{
    return [[[self storageRootDirectoryURL]
             URLByAppendingPathComponent:@"collections" isDirectory:YES]
            URLByAppendingPathComponent:key.stringByApplyingFilenameSafeTransform isDirectory:YES];
}

- (NSURL *)dataFileURLForIndexKey:(NSString *)key
{
    return [self indexURLForKey:key].URLByResolvingSymlinksInPath;
}

- (NSArray<NSURL *> *)dataFileURLsForCollectionKey:(NSString *)key
{
    NSURL *collectionURL = [self collectionURLForKey:key];
    if (![self.fileManager fileExistsAtPath:collectionURL.path]) {
        return @[];
    }
    
    NSError *error;
    NSArray *collectionItemURLs = [self.fileManager contentsOfDirectoryAtURL:collectionURL includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:0 error:&error];
    if (!collectionItemURLs) {
        [self reportError:error];
        return @[];
    }
    collectionItemURLs = [collectionItemURLs sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSDate *timestamp1, *timestamp2;
        
        BOOL isCompared =
        [obj1 getResourceValue:&timestamp1 forKey:NSURLContentModificationDateKey error:nil] &&
        [obj2 getResourceValue:&timestamp2 forKey:NSURLContentModificationDateKey error:nil];
        
        return isCompared ? [timestamp1 compare:timestamp2] : [[obj1 lastPathComponent] localizedStandardCompare:[obj2 lastPathComponent]];
    }];
    
    NSMutableArray *dataFileURLs = [NSMutableArray array];
    for (NSURL *collectionItemURL in collectionItemURLs) {
        NSURL *dataFileURL = collectionItemURL.URLByResolvingSymlinksInPath;
        if (!dataFileURL) {
            continue;
        }
        [dataFileURLs addObject:dataFileURL];
    }
    
    return dataFileURLs;
}

- (NSURL *)storageRootDirectoryURL
{
    return [[[self.fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject
             URLByAppendingPathComponent:@"XMPPOutOfBandMessagingFilesystemStorage"]
            URLByAppendingPathComponent:self.identifier];
}

- (void)reportError:(NSError *)error
{
    // TODO
    NSLog(@"XMPPOutOfBandMessagingFilesystemStorage error: %@", error);
}

@end

@implementation XMPPOutOfBandMessagingFilesystemStorageEntry

- (instancetype)initWithKind:(XMPPOutOfBandMessagingFilesystemStorageEntryKind)kind data:(NSData *)data MIMEType:(NSString *)MIMEType transferComplete:(BOOL)isTransferComplete
{
    self = [super init];
    if (self) {
        _kind = kind;
        _data = [data copy];
        _MIMEType = [MIMEType copy];
        _transferComplete = isTransferComplete;
    }
    return self;
}

@end

@implementation NSString (XMPPOutOfBandMessagingFilesystemStorage)

- (NSString *)stringByApplyingFilenameSafeTransform
{
    return [[[[self dataUsingEncoding:NSUTF8StringEncoding]
              base64EncodedStringWithOptions:0]
             stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
            stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

@end

@implementation NSURL (XMPPOutOfBandMessagingFilesystemStorage)

- (NSString *)inferredMIMEType
{
    NSString *uti = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(self.pathExtension), NULL));
    return CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(uti), kUTTagClassMIMEType));
}

- (NSURL *)URLByAppendingMessagePathExtension
{
    return [self URLByAppendingPathExtension:@"message"];
}

- (NSURL *)URLByAppendingUploadMarkerPathExtension
{
    return [self URLByAppendingPathExtension:@"upload"];
}

- (NSURL *)URLByAppendingDownloadMarkerPathExtension
{
    return [self URLByAppendingPathExtension:@"download"];
}

- (NSURL *)URLByAppendingCompletionMarkerPathExtension
{
    return [self URLByAppendingPathExtension:@"completed"];
}

- (NSURL *)URLByAppendingPathExtensionForMIMEType:(NSString *)MIMEType
{
    NSString *uti = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(MIMEType), NULL));
    NSString *fileExtension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(uti), kUTTagClassFilenameExtension)) ?: @"data";
    return [self URLByAppendingPathExtension:fileExtension];
}

@end

@implementation NSFileManager (XMPPOutOfBandMessagingFilesystemStorage)

- (BOOL)establishSymbolicLinkAtURL:(NSURL *)url withDestinationURL:(NSURL *)destURL error:(NSError *__autoreleasing *)error
{
    NSError *createError;
    if ([self createSymbolicLinkAtURL:url withDestinationURL:destURL error:&createError]) {
        return YES;
    } else if (![createError.domain isEqualToString:NSCocoaErrorDomain] || createError.code != NSFileWriteFileExistsError) {
        if (error) {
            *error = createError;
        }
        return NO;
    }
    
    NSURL *temporarySymbolicLinkURL = [url URLByAppendingPathExtension:[NSUUID UUID].UUIDString];
    if (![self createSymbolicLinkAtURL:temporarySymbolicLinkURL withDestinationURL:destURL error:error]) {
        return NO;
    }
    
    // replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: appears to fail for relative symlinks
    if (rename(temporarySymbolicLinkURL.fileSystemRepresentation, url.fileSystemRepresentation) != 0) {
        if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSURLErrorKey: url}];
        }
        return NO;
    }
    
    return YES;
}

- (NSString *)pathToResourceAtURL:(NSURL *)resourceURL relativeToDirectoryAtURL:(NSURL *)referenceDirectoryURL error:(NSError *__autoreleasing *)error
{
    NSURL *relativeTraversalURL = [[NSURL alloc] initFileURLWithPath:@"." relativeToURL:referenceDirectoryURL];
    
    // Traverse up the hierarchy from referenceDirectoryURL to a directory that contains resourceURL in its subtree
    do {
        NSURLRelationship relationship;
        if (![self getRelationship:&relationship ofDirectoryAtURL:relativeTraversalURL toItemAtURL:resourceURL error:error]) {
            return nil;
        }
        if (relationship != NSURLRelationshipOther) {
            break;
        }
        relativeTraversalURL = relativeTraversalURL.URLByDeletingLastPathComponent;
    } while (YES);
    
    // Traverse up the hierarchy from resourceURL to the common ancestor directory found above, registering path components in reverse order
    NSURL *resourceAncestorTraversalURL = resourceURL;
    NSMutableArray *resourceTraversalPathComponents = [[NSMutableArray alloc] init];
    do {
        NSURLRelationship relationship;
        if (![self getRelationship:&relationship ofDirectoryAtURL:relativeTraversalURL toItemAtURL:resourceAncestorTraversalURL error:error]) {
            return nil;
        }
        if (relationship == NSURLRelationshipSame) {
            break;
        }
        [resourceTraversalPathComponents insertObject:resourceAncestorTraversalURL.lastPathComponent atIndex:0];
        resourceAncestorTraversalURL = resourceAncestorTraversalURL.URLByDeletingLastPathComponent;
    } while (YES);
    
    // Apply the reverse order path components from the previous step to the main traversal URL
    for (NSString *pathComponent in resourceTraversalPathComponents) {
        relativeTraversalURL = [relativeTraversalURL URLByAppendingPathComponent:pathComponent];
    }
    
    return relativeTraversalURL.relativePath;
}

@end
