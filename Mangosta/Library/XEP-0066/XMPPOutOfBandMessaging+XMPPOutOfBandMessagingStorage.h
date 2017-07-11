//
//  XMPPOutOfBandMessaging+XMPPOutOfBandMessagingStorage.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 01/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XMPPOutOfBandMessagingStorage <NSObject>

- (void)prepareForUploadWithIdentifier:(NSString *)transferIdentifier MIMEType:(NSString *)MIMEType message:(XMPPMessage *)message;
- (void)prepareForDownloadWithIdentifier:(NSString *)transferIdentifier MIMEType:(NSString *)MIMEType message:(XMPPMessage *)message;
- (void)appendDataChunk:(NSData *)dataChunk forTransferWithIdentifier:(NSString *)transferIdentifier;
- (void)registerCompletionForTransferWithIdentifier:(NSString *)transferIdentifier;

@end


