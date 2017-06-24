//
//  XMPPRetransmissionMessageArchivingStorageFilter.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRetransmissionMessageArchivingStorageFilter.h"
#import "XMPPRetransmission+XMPPMessageStorageFiltering.h"

@interface XMPPRetransmissionMessageArchivingStorageFilter ()

@property (strong, nonatomic, readonly) id<XMPPMessageArchivingStorage> baseStorage;
@property (strong, nonatomic, readonly) XMPPRetransmission *xmppRetransmission;

@end

@implementation XMPPRetransmissionMessageArchivingStorageFilter

- (instancetype)initWithBaseStorage:(id<XMPPMessageArchivingStorage>)baseStorage xmppRetransmission:(XMPPRetransmission *)xmppRetransmission
{
    NSParameterAssert(![baseStorage respondsToSelector:@selector(setPreferences:forUser:)] && ![baseStorage respondsToSelector:@selector(preferencesForUser:)]);
    
    self = [super init];
    if (self) {
        _baseStorage = baseStorage;
        _xmppRetransmission = xmppRetransmission;
    }
    return self;
}

- (BOOL)configureWithParent:(XMPPMessageArchiving *)aParent queue:(dispatch_queue_t)queue
{
    return [self.baseStorage configureWithParent:aParent queue:queue];
}

- (void)archiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)stream
{
    if (isOutgoing && [self.xmppRetransmission isRetransmittingElement:message]) {
        return;
    }
    
    [self.baseStorage archiveMessage:message outgoing:isOutgoing xmppStream:stream];
}

@end
