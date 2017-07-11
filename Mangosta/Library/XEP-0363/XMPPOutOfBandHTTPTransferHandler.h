//
//  XMPPOutOfBandHTTPTransferHandler.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 06/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPOutOfBandMessaging+XMPPOutOfBandTransferHandler.h"

@interface XMPPOutOfBandHTTPTransferHandler : NSObject <XMPPOutOfBandMessagingTransferHandler>

- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration *)URLSessionConfiguration XMPPHTTPFileUpload:(XMPPHTTPFileUpload *)xmppHTTPFileUpload uploadServiceJID:(XMPPJID *)uploadServiceJID;
- (instancetype)init NS_UNAVAILABLE;

@end
