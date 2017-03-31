//
//  XMPPClientState.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 31/03/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPClientState.h"
#import "NSXMLElement+XEP_0352.h"
#import "XMPPLogging.h"

static const int xmppLogLevel = XMPP_LOG_LEVEL_VERBOSE | XMPP_LOG_FLAG_TRACE;

@implementation XMPPClientState

@synthesize active=_active;

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue
{
    self = [super initWithDispatchQueue:queue];
    if (self) {
        _active = YES;
    }
    return self;
}

- (BOOL)isActive
{
    __block BOOL active;
    dispatch_sync(moduleQueue, ^{
        active = _active;
    });
    return active;
}

- (void)setActive:(BOOL)active
{
    XMPPLogTrace();
    
    dispatch_sync(moduleQueue, ^{
        if (_active == active) return;
        
        if (active) {
            [self.xmppStream sendElement:[XMPPElement indicateActiveElement]];
        } else {
            [self.xmppStream sendElement:[XMPPElement indicateInactiveElement]];
        }
        
        _active = active;
        
        XMPPLogVerbose(@"Client state set to <%@>", active ? @"active" : @"inactive");
    });
}

@end
