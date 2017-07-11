//
//  XMPPOutOfBandMessaging.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 28/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOutOfBandMessaging.h"
#import "XMPPOutOfBandMessaging+XMPPOutOfBandTransferHandler.h"
#import "XMPPOutOfBandMessaging+XMPPOutOfBandMessagingStorage.h"
#import "XMPPMessage+XEP_0066.h"

@interface XMPPOutOfBandMessaging ()

@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, NSProgress *> *progressIndex;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, NSError *> *errorIndex;

@end

@interface XMPPOutOfBandTransfer ()

@property (unsafe_unretained, nonatomic, readonly) XMPPOutOfBandMessaging *outOfBandMessaging;
@property (copy, nonatomic, readonly) XMPPMessage *message;
@property (strong, nonatomic) NSProgress *progress;

- (instancetype)initWithOutOfBandMessaging:(XMPPOutOfBandMessaging *)outOfBandMessaging message:(XMPPMessage *)message;

@end

@interface XMPPOutOfBandUpload ()

- (instancetype)initWithOutOfBandMessaging:(XMPPOutOfBandMessaging *)outOfBandMessaging message:(XMPPMessage *)message data:(NSData *)data MIMEType:(NSString *)MIMEType;

@end

@interface XMPPOutOfBandDownload ()

- (instancetype)initWithOutOfBandMessaging:(XMPPOutOfBandMessaging *)outOfBandMessaging message:(XMPPMessage *)message URL:(NSURL *)URL;

@end

@implementation XMPPOutOfBandMessaging

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue transferHandler:(id<XMPPOutOfBandMessagingTransferHandler>)transferHandler storage:(id<XMPPOutOfBandMessagingStorage>)storage
{
    self = [super initWithDispatchQueue:queue];
    if (self) {
        _transferHandler = transferHandler;
        _storage = storage;
        _progressIndex = [[NSMutableDictionary alloc] init];
        _errorIndex = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithTransferHandler:(id<XMPPOutOfBandMessagingTransferHandler>)transferHandler storage:(id<XMPPOutOfBandMessagingStorage>)storage
{
    return [self initWithDispatchQueue:nil transferHandler:transferHandler storage:storage];
}

- (void)submitOutgoingMessage:(XMPPMessage *)message withOutOfBandData:(NSData *)data MIMEType:(NSString *)MIMEType
{
    NSParameterAssert(![message hasOutOfBandData]);
    
    dispatch_block_t block = ^{
        NSString *messageID = [message elementID];
        if (messageID) {
            [self.storage prepareForUploadWithIdentifier:messageID MIMEType:MIMEType message:message];
            [self.storage appendDataChunk:data forTransferWithIdentifier:messageID];
        }
        
        [self.transferHandler handleUpload:[[XMPPOutOfBandUpload alloc] initWithOutOfBandMessaging:self message:message data:data MIMEType:MIMEType]];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)retrieveOutOfBandDataForMessage:(XMPPMessage *)message
{
    NSParameterAssert([message hasOutOfBandData] && [message outOfBandURL]);
    
    dispatch_block_t block = ^{
        [self.transferHandler handleDownload:[[XMPPOutOfBandDownload alloc] initWithOutOfBandMessaging:self message:message URL:[message outOfBandURL]]];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (NSProgress *)dataTransferProgressForMessage:(XMPPMessage *)message
{
    __block NSProgress *progress;
    dispatch_block_t block = ^{
        progress = [message elementID] ? self.progressIndex[[message elementID]] : nil;
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return progress;
}

- (NSError *)dataTransferErrorForMessage:(XMPPMessage *)message
{
    __block NSError *error;
    dispatch_block_t block = ^{
        error = [message elementID] ? self.errorIndex[[message elementID]] : nil;
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return error;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message hasOutOfBandData] && [message outOfBandURL]) {
        [multicastDelegate xmppOutOfBandMessaging:self didReceiveOutOfBandDataMessage:message];
    }
}

- (void)transfer:(XMPPOutOfBandTransfer *)transfer didBeginWithProgress:(NSProgress *)progress
{
    NSString *messageId = [transfer.message elementID];
    if (!messageId) {
        return;
    }
    
    dispatch_block_t block = ^{
        self.progressIndex[messageId] = progress;
        [multicastDelegate xmppOutOfBandMessaging:self didBeginDataTransferForMessage:transfer.message];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)upload:(XMPPOutOfBandUpload *)upload didCompleteWithDownloadURL:(NSURL *)downloadURL
{
    [upload.message addOutOfBandURI:downloadURL.absoluteString desc:nil];
    
    dispatch_block_t block = ^{
        [multicastDelegate xmppOutOfBandMessaging:self didPrepareToSendOutOfBandDataMessage:upload.message];
        [self.xmppStream sendElement:upload.message];
        [self transferDidComplete:upload];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)download:(XMPPOutOfBandDownload *)download didProvideMIMEType:(NSString *)MIMEType
{
    dispatch_block_t block = ^{
        NSString *messageID = [download.message elementID];
        if (messageID) {
            [self.storage prepareForDownloadWithIdentifier:messageID MIMEType:MIMEType message:download.message];
            [multicastDelegate xmppOutOfBandMessaging:self didPrepareDataTransferStorageEntryForMessage:download.message];
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)download:(XMPPOutOfBandDownload *)download didProvideDataChunk:(NSData *)dataChunk
{
    dispatch_block_t block = ^{
        NSString *messageID = [download.message elementID];
        if (messageID) {
            [self.storage appendDataChunk:dataChunk forTransferWithIdentifier:messageID];
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)transferDidComplete:(XMPPOutOfBandTransfer *)transfer
{
    dispatch_block_t block = ^{
        NSString *messageID = [transfer.message elementID];
        if (messageID) {
            [self.storage registerCompletionForTransferWithIdentifier:messageID];
            [self.progressIndex removeObjectForKey:messageID];
        }
        
        [multicastDelegate xmppOutOfBandMessaging:self didCompleteDataTransferForMessage:transfer.message];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (void)transfer:(XMPPOutOfBandTransfer *)transfer didFailWithError:(NSError *)error
{
    NSString *messageId = [transfer.message elementID];
    if (!messageId) {
        return;
    }
    
    dispatch_block_t block = ^{
        [self.progressIndex removeObjectForKey:messageId];
        self.errorIndex[messageId] = error;
        [multicastDelegate xmppOutOfBandMessaging:self didFailDataTransferForMessage:transfer.message];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

@end

@implementation XMPPOutOfBandTransfer

- (instancetype)initWithOutOfBandMessaging:(XMPPOutOfBandMessaging *)outOfBandMessaging message:(XMPPMessage *)message
{
    self = [super init];
    if (self) {
        _outOfBandMessaging = outOfBandMessaging;
        _message = [message copy];
    }
    return self;
}

- (void)beginWithProgress:(NSProgress *)progress
{
    self.progress = progress;
    [self.outOfBandMessaging transfer:self didBeginWithProgress:progress];
}

- (void)failWithError:(NSError *)error
{
    [self.outOfBandMessaging transfer:self didFailWithError:error];
}

@end

@implementation XMPPOutOfBandUpload

- (instancetype)initWithOutOfBandMessaging:(XMPPOutOfBandMessaging *)outOfBandMessaging message:(XMPPMessage *)message data:(NSData *)data MIMEType:(NSString *)MIMEType
{
    self = [super initWithOutOfBandMessaging:outOfBandMessaging message:message];
    if (self) {
        _data = data;
        _MIMEType = [MIMEType copy];
    }
    return self;
}

- (void)completeWithDownloadURL:(NSURL *)downloadURL
{
    [self.outOfBandMessaging upload:self didCompleteWithDownloadURL:downloadURL];
}

@end

@implementation XMPPOutOfBandDownload

- (instancetype)initWithOutOfBandMessaging:(XMPPOutOfBandMessaging *)outOfBandMessaging message:(XMPPMessage *)message URL:(NSURL *)URL
{
    self = [super initWithOutOfBandMessaging:outOfBandMessaging message:message];
    if (self) {
        _URL = URL;
    }
    return self;
}

- (void)provideMIMEType:(NSString *)MIMEType
{
    [self.outOfBandMessaging download:self didProvideMIMEType:MIMEType];
}

- (void)provideDataChunk:(NSData *)dataChunk
{
    [self.outOfBandMessaging download:self didProvideDataChunk:dataChunk];
}

- (void)complete
{
    [self.outOfBandMessaging transferDidComplete:self];
}

@end
