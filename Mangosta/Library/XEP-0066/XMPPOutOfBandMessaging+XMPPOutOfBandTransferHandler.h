//
//  XMPPOutOfBandMessaging+XMPPOutOfBandTransferHandler.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 01/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPOutOfBandUpload, XMPPOutOfBandDownload;

@protocol XMPPOutOfBandMessagingTransferHandler <NSObject>

- (void)handleUpload:(XMPPOutOfBandUpload *)upload;
- (void)handleDownload:(XMPPOutOfBandDownload *)download;

@end

@interface XMPPOutOfBandTransfer : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (void)beginWithProgress:(NSProgress *)progress;
- (void)failWithError:(NSError *)error;

@end

@interface XMPPOutOfBandUpload : XMPPOutOfBandTransfer

@property (strong, nonatomic, readonly) NSData *data;
@property (copy, nonatomic, readonly) NSString *MIMEType;

- (void)completeWithDownloadURL:(NSURL *)downloadURL;

@end

@interface XMPPOutOfBandDownload : XMPPOutOfBandTransfer

@property (strong, nonatomic, readonly) NSURL *URL;

- (void)provideMIMEType:(NSString *)MIMEType;
- (void)provideDataChunk:(NSData *)dataChunk;
- (void)complete;

@end

