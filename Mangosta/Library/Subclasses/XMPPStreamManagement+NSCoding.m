//
//  XMPPStreamManagement+NSCoding.m
//  Mangosta
//
//  Created by Tom Ryan on 4/7/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPStreamManagement+NSCoding.h"
#import <XMPPFramework/XMPPStreamManagementMemoryStorage.h>
#import <XMPPFramework/XMPPStreamManagementStanzas.h>

#define XMPPStreamManagementPreferenceName @"XMPPStreamManagementPreferenceName"

@implementation XMPPStreamManagement (NSCoding)



- (void)saveState {
	XMPPStreamManagementMemoryStorage *memoryStorage = self.storage;
	NSString *resumptionId = [memoryStorage valueForKey:@"resumptionId"];
	uint32_t timeout = [[memoryStorage valueForKey:@"timeout"] unsignedIntValue];
	NSDate *lastDisconnect = [memoryStorage valueForKey:@"lastDisconnect"];
	uint32_t lastHandledByClient = [[memoryStorage valueForKey:@"lastHandledByClient"] unsignedIntValue];
	uint32_t lastHandledByServer = [[memoryStorage valueForKey:@"lastHandledByServer"] unsignedIntValue];
	NSArray *pendingOutgoingStanzas = [memoryStorage valueForKey:@"pendingOutgoingStanzas"];
	
	NSMutableDictionary *payload = [NSMutableDictionary dictionary];
	
	[payload setObject:resumptionId forKey:@"resumptionId"];
	[payload setObject:@(timeout) forKey:@"timeout"];
	[payload setObject:lastDisconnect forKey:@"lastDisconnect"];
	[payload setObject:@(lastHandledByClient) forKey:@"lastHandledByClient"];
	[payload setObject:@(lastHandledByServer) forKey:@"lastHandledByServer"];
	
	NSMutableArray *mary = [NSMutableArray array];
	for (XMPPStreamManagementOutgoingStanza *obj in pendingOutgoingStanzas) {
		[mary addObject:[NSKeyedArchiver archivedDataWithRootObject:obj]];
	}
	[payload setObject:mary forKey:@"pendingOutgoingStanzas"];
	
	[[NSUserDefaults standardUserDefaults] setObject:payload forKey:XMPPStreamManagementPreferenceName];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadState {
	NSDictionary *payload = [[NSUserDefaults standardUserDefaults] objectForKey:XMPPStreamManagementPreferenceName];
	
	NSMutableArray *objectStanzas = [NSMutableArray array];
	
	if ([payload objectForKey:@"pendingOutgoingStanzas"]) {
		NSArray *stanzas = [payload objectForKey:@"pendingOutgoingStanzas"];
		for (NSData *data in stanzas) {
			XMPPStreamManagementOutgoingStanza *stanza = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			[objectStanzas addObject:stanza];
		}
	}
	
	XMPPStreamManagementMemoryStorage *memoryStorage = self.storage;
	
	if (payload[@"resumptionId"] && payload[@"timeout"] && payload[@"lastDisconnect"]) {
		[memoryStorage setResumptionId:payload[@"resumptionId"] timeout:[payload[@"timeout"] unsignedIntValue] lastDisconnect:payload[@"lastDisconnect"] forStream:self.xmppStream];
	}
	
	if (payload[@"lastDisconnect"] && payload[@"lastHandledByClient"] && payload[@"lastHandledByServer"]) {
		[memoryStorage setLastDisconnect:payload[@"lastDisconnect"] lastHandledByClient:[payload[@"lastHandledByClient"] unsignedIntValue] lastHandledByServer:[payload[@"lastHandledByServer"] unsignedIntValue] pendingOutgoingStanzas:objectStanzas forStream:self.xmppStream];
	}
}

- (void)deleteState {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XMPPStreamManagementPreferenceName];
}

@end
