//
//  NSXMLElement+XEP_0277.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 15/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

extern NSString *const XMPPPubSubDefaultMicroblogNode;
extern NSString *const XMPPCapabilitiesMicroblogImplicitSubscription;

@interface NSXMLElement (XEP_0277)

// TODO: [pwe] There are many more fields in Atom spec
+ (instancetype)microblogEntryWithTitle:(NSString *)titleText authorName:(NSString *)authorName authorJID:(XMPPJID *)authorJID publishedDate:(NSDate *)publishedDate updatedDate:(NSDate *)updatedDate;

- (BOOL)isMicroblogEntry;
- (NSString *)microblogEntryID;
- (NSString *)microblogEntryTitle;
- (NSString *)microblogEntryAuthorName;
- (NSDate *)microblogEntryPublishedDate;
- (NSDate *)microblogEntryUpdatedDate;

@end
