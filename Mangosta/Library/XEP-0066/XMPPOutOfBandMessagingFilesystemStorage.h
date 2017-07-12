//
//  XMPPOutOfBandMessagingFilesystemStorage.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 01/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPOutOfBandMessaging+XMPPOutOfBandMessagingStorage.h"

@class XMPPOutOfBandMessagingFilesystemStorageEntry;

typedef NS_ENUM(NSInteger, XMPPOutOfBandMessagingFilesystemStorageEntryKind) {
    XMPPOutOfBandMessagingFilesystemStorageEntryKindUpload,
    XMPPOutOfBandMessagingFilesystemStorageEntryKindDownload
};

@interface XMPPOutOfBandMessagingFilesystemStorage : NSObject <XMPPOutOfBandMessagingStorage>

- (instancetype)initWithIdentifier:(NSString *)identifier;

- (XMPPOutOfBandMessagingFilesystemStorageEntry *)entryForTransferIdentifier:(NSString *)transferIdentifier;
- (NSArray<XMPPMessage *> *)pendingMessagesForDestinationJID:(XMPPJID *)destinationJID;

@end

@interface XMPPOutOfBandMessagingFilesystemStorageEntry : NSObject

@property (assign, nonatomic, readonly) XMPPOutOfBandMessagingFilesystemStorageEntryKind kind;
@property (strong, nonatomic, readonly) NSURL *fileURL;
@property (copy, nonatomic, readonly) NSString *MIMEType;
@property (assign, nonatomic, readonly, getter=isTransferComplete) BOOL transferComplete;

- (instancetype)init NS_UNAVAILABLE;

@end
