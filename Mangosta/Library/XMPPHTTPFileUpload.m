//
//  XMPPHTTPFileUpload.m
//  Mangosta
//
//  Created by Andres Canal on 5/19/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPHTTPFileUpload.h"

@implementation XMPPHTTPFileUpload

- (BOOL)activate:(XMPPStream *)aXmppStream
{
	if ([super activate:aXmppStream])
	{
		responseTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		
		return YES;
	}
	
	return NO;
}

- (void)deactivate
{
	dispatch_block_t block = ^{ @autoreleasepool {
		
		[responseTracker removeAllIDs];
		responseTracker = nil;
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	[super deactivate];
}


- (void)requestSlotForFile:(NSString *) filename size:(NSInteger) size contentType:(NSString*) contentType {
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		//	<iq from='romeo@montague.tld/garden' id='step_03'
		//		  to='upload.montague.tld' type='get'>
		//	   <request xmlns='urn:xmpp:http:upload'>
		//		  <filename>my_juliet.png</filename>
		//		  <size>23456</size>
		//		  <content-type>image/jpeg</content-type>
		//	   </request>
		//	</iq>
		
		NSString *iqID = [XMPPStream generateUUID];
		XMPPJID *uploadService = [XMPPJID jidWithString:@"upload.montague.tld"];
		XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:uploadService elementID:iqID];
		
		XMPPElement *request = [XMPPElement elementWithName:@"request"];
		[request addAttributeWithName:@"xmlns" stringValue:XMPPHTTPFileUploadNamespace];
		[request addChild:[XMPPElement elementWithName:@"filename" stringValue:filename]];
		[request addChild:[XMPPElement elementWithName:@"size" stringValue:filename]];
		[request addChild:[XMPPElement elementWithName:@"content-type" stringValue:filename]];
		
		[xmppStream sendElement:iq];
		
		[responseTracker addID:iqID
						target:self
					  selector:@selector(handleRequestSlot:withInfo:)
					   timeout:60.0];
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)handleRequestSlot:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info{
	if ([[iq type] isEqualToString:@"result"]){
		
	} else {
		
	}
}


@end
