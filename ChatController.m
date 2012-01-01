#import "ChatController.h"
#import "XMPPStream.h"
#import "XMPPUser.h"


@implementation ChatController

- (id)initWithXMPPStream:(XMPPStream *)stream forXMPPUser:(XMPPUser *)user
{
	if(self = [super initWithWindowNibName:@"ChatWindow"])
	{
		xmppStream = [stream retain];
		xmppUser = [user retain];
	}
	return self;
}

- (void)awakeFromNib
{
	[messageView setString:@""];
	
	if([xmppUser name])
		[[self window] setTitle:[xmppUser name]];
	else
		[[self window] setTitle:[xmppUser jid]];
	
	[[self window] makeFirstResponder:messageField];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self autorelease];
}

- (void)dealloc
{
	NSLog(@"Destroying self: %@", self);
	
	[xmppUser release];
	[super dealloc];
}

- (XMPPUser *)xmppUser
{
	return xmppUser;
}

- (void)receiveMessage:(NSXMLElement *)message
{
	NSString *messageStr = [[message elementForName:@"body"] stringValue];
	
	NSString *paragraph = [NSString stringWithFormat:@"%@\n\n", messageStr];
	
	NSMutableParagraphStyle *mps = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[mps setAlignment:NSLeftTextAlignment];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
	[attributes setObject:mps forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSColor colorWithCalibratedRed:250 green:250 blue:250 alpha:1] forKey:NSBackgroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[messageView textStorage] appendAttributedString:as];
}

- (IBAction)sendMessage:(id)sender
{
	NSString *messageStr = [messageField stringValue];
	
	if([messageStr length] > 0)
	{
		NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
		[body setStringValue:messageStr];
		
		NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
		[message addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"chat"]];
		[message addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:[xmppUser jid]]];
		//[message addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:@"shenario1@gmail.com"]];
		[message addChild:body];
		
		[xmppStream sendElement:message];
		
		
		NSXMLElement *body1 = [NSXMLElement elementWithName:@"body"];
		[body1 setStringValue:messageStr];
		
		NSXMLElement *message1 = [NSXMLElement elementWithName:@"message"];
		[message1 addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"chat"]];
		//[message addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:[xmppUser jid]]];
		[message1 addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:@"shenario1@gmail.com"]];
		[message1 addChild:body1];
		[xmppStream sendElement:message1];
		
		NSString *paragraph = [NSString stringWithFormat:@"%@\n\n", messageStr];
		
		NSMutableParagraphStyle *mps = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[mps setAlignment:NSRightTextAlignment];
		
		NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
		[attributes setObject:mps forKey:NSParagraphStyleAttributeName];
		
		NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
		[as autorelease];
		NSColor *grayColor;
		grayColor = [NSColor colorWithCalibratedRed:(184/255.0) green:(175/255.0) blue:(184/255.0) alpha:1.0];
		[messageView setTextColor: grayColor];
		[[messageView textStorage] appendAttributedString:as];
		
		NSScrollView *scrollView = [messageView enclosingScrollView];
		NSPoint newScrollOrigin;
		
		if ([[scrollView documentView] isFlipped])
			newScrollOrigin = NSMakePoint(0.0, NSMaxY([[scrollView documentView] frame]));
		else
			newScrollOrigin = NSMakePoint(0.0, 0.0);
		
		[[scrollView documentView] scrollPoint:newScrollOrigin];
		
		[messageField setStringValue:@""];
		[[self window] makeFirstResponder:messageField];
	}
}

@end
