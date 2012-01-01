#import "ChatWindowManager.h"
#import "ChatController.h"
#import "XMPPStream.h"
#import "XMPPUser.h"

@implementation ChatWindowManager

+ (ChatController *)chatControllerForXMPPUser:(XMPPUser *)user
{
	NSArray *windows = [NSApp windows];
	
	int i;
	for(i = 0; i < [windows count]; i++)
	{
		NSWindow *currentWindow = [windows objectAtIndex:i];
		ChatController *currentWC = [currentWindow windowController];
		
		if([currentWC isKindOfClass:[ChatController class]] && [[currentWC xmppUser] isEqual:user])
		{
			return currentWC;
		}
	}
	
	return nil;
}

+ (void)openChatWindowWithXMPPStream:(XMPPStream *)stream forXMPPUser:(XMPPUser *)user
{
	ChatController *cc = [[self class] chatControllerForXMPPUser:user];
	
	if(cc)
	{
		[[cc window] makeKeyAndOrderFront:self];
	}
	else
	{
		ChatController *temp = [[ChatController alloc] initWithXMPPStream:stream forXMPPUser:user];
		[temp showWindow:self];
	}
}

+ (void)handleChatMessage:(NSXMLElement *)message withXMPPStream:(XMPPStream *)stream fromXMPPUser:(XMPPUser *)user
{
	ChatController *cc = [[self class] chatControllerForXMPPUser:user];
	
	if(cc)
	{
		[cc receiveMessage:message];
	}
	else
	{
		ChatController *newCC = [[ChatController alloc] initWithXMPPStream:stream forXMPPUser:user];
		[newCC showWindow:self];
		
		ChatController *newCC1 = [[ChatController alloc] initWithXMPPStream:stream forXMPPUser:@"shenario1@gmail.com"];
		[newCC1 showWindow:self];

		[newCC receiveMessage:message];
		[newCC1	receiveMessage:message];
	}
}

@end
