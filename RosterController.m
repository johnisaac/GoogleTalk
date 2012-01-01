#import "RosterController.h"
#import "RequestController.h"
#import "XMPPStream.h"
#import "XMPPUser.h"
#import "ChatWindowManager.h"
#import "MailWindow.h"

@interface RosterController (PrivateAPI)

- (BOOL)isRoster:(NSXMLElement *)iq;
- (void)updateRosterWithIQ:(NSXMLElement *)iq;

- (BOOL)isChatMessage:(NSXMLElement *)message;
- (void)handleChatMessage:(NSXMLElement *)message;

- (BOOL)isBuddyRequest:(NSXMLElement *)presence;
- (void)handleBuddyRequest:(NSXMLElement *)presence;
- (void)updateRosterWithPresence:(NSXMLElement *)presence;

@end


@implementation RosterController


- (id)init
{
	if(self = [super init])
	{
		xmppStream = [[XMPPStream alloc] init];
		[xmppStream setDelegate:self];
		
		roster = [[NSMutableDictionary alloc] initWithCapacity:5];
		rosterKeys = [[NSArray alloc] init];
		
		NSArray *cmds = [NSArray arrayWithObjects:@"Invisible", @"Chat", @"Group Chat",@"Status",@"Off the Record",@"Email",nil];
        recog = [[NSSpeechRecognizer alloc] init]; 
        [recog setCommands:cmds];
		[recog startListening];
        [recog setDelegate:self];
		
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

	[NSApp beginSheet:signInSheet
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
}


- (void)updateAccountInfo
{
	[xmpp_hostname release];  xmpp_hostname  = nil;
	[xmpp_username release];  xmpp_username  = nil;
	[xmpp_vhostname release]; xmpp_vhostname = nil;
	[xmpp_password release];  xmpp_password  = nil;
	[xmpp_resource release];  xmpp_resource  = nil;
	
	xmpp_hostname = @"talk.google.com";	
	xmpp_port = 5222;
	
	usesSSL = ([sslButton state] == NSOnState);
	allowsSelfSignedCertificates = ([selfSignedButton state] == NSOnState);
	
	NSArray *components = [[jidField stringValue] componentsSeparatedByString:@"@"];
	xmpp_username  = [[components objectAtIndex:0] copy];
	xmpp_vhostname = @"gmail.com";
	
	xmpp_password = [[passwordField stringValue] copy];
	
	xmpp_resource = @" ";

}




- (IBAction)signIn:(id)sender
{
	// Update our variables from the form
	[self updateAccountInfo];
	
	shouldSignIn = YES;
	[signInButton setEnabled:NO];
	[registerButton setEnabled:NO];
	
	if(![xmppStream isConnected])
	{
		[xmppStream setAllowsSelfSignedCertificates:allowsSelfSignedCertificates];
		
		if(usesSSL)
		{
			[xmppStream connectToSecureHost:xmpp_hostname
									 onPort:xmpp_port
							withVirtualHost:xmpp_vhostname];
		}
		else
		{
			[xmppStream connectToHost:xmpp_hostname
							   onPort:xmpp_port
					  withVirtualHost:xmpp_vhostname];
		}
	}
	else
	{
		[xmppStream authenticateUser:xmpp_username
						withPassword:xmpp_password
							resource:xmpp_resource];
	}
	


}


- (IBAction)listen:(id)sender
{
	NSLog(@"listening");
    if ([sender state] == NSOnState) {
		[recog startListening];
    } else {
		[recog stopListening];
    }
}

- (IBAction)createAccount:(id)sender
{
	
	[self updateAccountInfo];
	
	shouldRegister = YES;
	[signInButton setEnabled:NO];
	[registerButton setEnabled:NO];
	
	if(![xmppStream isConnected])
	{
		[xmppStream setAllowsSelfSignedCertificates:allowsSelfSignedCertificates];

		if(usesSSL)
		{
			[xmppStream connectToSecureHost:xmpp_hostname
									 onPort:xmpp_port
							withVirtualHost:xmpp_vhostname];
		}
		else
		{
			[xmppStream connectToHost:xmpp_hostname
							   onPort:xmpp_port
					  withVirtualHost:xmpp_vhostname];
		}
	}
	else
	{
		[xmppStream registerUser:xmpp_username
					withPassword:xmpp_password];
	}
	
}


- (IBAction)changePresence:(id)sender
{
	
		NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
		
		[xmppStream sendElement:presence];
	
}

- (IBAction)loadPresence:(id)sender
	{
		NSLog(@"PRESENCE EXECUTED");
					NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
			
			[xmppStream sendElement:presence];
		
	}
	

- (IBAction)addBuddy:(id)sender
{

	NSString *jid = [buddyField stringValue];
		

	NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
	[item addAttribute:[NSXMLNode attributeWithName:@"jid" stringValue:jid]];
	
	NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
	[query addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"]];
	[query addChild:item];
	
	NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"set"]];
	[iq addChild:query];
	
	[xmppStream sendElement:iq];
	
	
	NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[presence addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[presence addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"subscribe"]];
	
	[xmppStream sendElement:presence];
	
	
	[buddyField setStringValue:@""];
}

- (IBAction)removeBuddy:(id)sender
{
	NSString *jid = [buddyField stringValue];

	
	NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
	[item addAttribute:[NSXMLNode attributeWithName:@"jid" stringValue:jid]];
	[item addAttribute:[NSXMLNode attributeWithName:@"subscription" stringValue:@"remove"]];
	
	NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
	[query addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"]];
	[query addChild:item];
	
	NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"set"]];
	[iq addChild:query];
	
	[xmppStream sendElement:iq];
	
	[buddyField setStringValue:@""];
}


- (IBAction)chat:(id)sender
{
	int selectedRow = [rosterTable selectedRow];
	
	if(selectedRow >= 0)
	{
		XMPPUser *user = [roster objectForKey:[rosterKeys objectAtIndex:selectedRow]];
		
		[ChatWindowManager openChatWindowWithXMPPStream:xmppStream forXMPPUser:user];
	}
}

- (XMPPStream *)xmppStream
{
	return xmppStream;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [rosterKeys count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	XMPPUser *user = [roster objectForKey:[rosterKeys objectAtIndex:rowIndex]];
	
	if([[tableColumn identifier] isEqualToString:@"name"])
		return [user name];
	else
		return [user jid];
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)tableColumn
			  row:(int)rowIndex
{
	XMPPUser *user = [roster objectForKey:[rosterKeys objectAtIndex:rowIndex]];
	NSString *newName = (NSString *)anObject;
	
	NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
	[item addAttribute:[NSXMLNode attributeWithName:@"jid" stringValue:[user jid]]];
	[item addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:newName]];
	
	NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
	[query addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"]];
	[query addChild:item];
	
	NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"set"]];
	[iq addChild:query];
	
	[xmppStream sendElement:iq];
}

- (void)tableView:(NSTableView *)tableView
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn *)tableColumn 
			  row:(int)rowIndex
{
	XMPPUser *user = [roster objectForKey:[rosterKeys objectAtIndex:rowIndex]];
	
	BOOL isRowSelected = ([tableView isRowSelected:rowIndex]);
	BOOL isFirstResponder = [[[tableView window] firstResponder] isEqual:tableView];
	BOOL isKeyWindow = [[tableView window] isKeyWindow];
	BOOL isApplicationActive = [NSApp isActive];
	
	BOOL isRowHighlighted = (isRowSelected && isFirstResponder && isKeyWindow && isApplicationActive);
	
	if([user isOnline])
	{
		[cell setTextColor:[NSColor blackColor]];
	}
	else
	{
		NSColor *grayColor;
		if(isRowHighlighted)
			grayColor = [NSColor colorWithCalibratedRed:(184/255.0) green:(175/255.0) blue:(184/255.0) alpha:1.0];
		else
			grayColor = [NSColor colorWithCalibratedRed:(134/255.0) green:(125/255.0) blue:(134/255.0) alpha:1.0];
			
		[cell setTextColor:grayColor];
	}
}



- (void)xmppStreamDidOpen:(XMPPStream *)xs
{
	if(shouldSignIn)
	{
		[xmppStream authenticateUser:xmpp_username
						withPassword:xmpp_password
							resource:xmpp_resource];
	}
	else if(shouldRegister)
	{
		[xmppStream registerUser:xmpp_username
					withPassword:xmpp_password];
	}
}

- (void)xmppStreamDidRegister:(XMPPStream *)xs
{
	shouldRegister = NO;
	[signInButton setEnabled:YES];
	[registerButton setEnabled:YES];
	[messageField setStringValue:@"Registered new user"];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)xs
{
	shouldSignIn = NO;
	[signInSheet orderOut:self];
	[NSApp endSheet:signInSheet];
	NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
	[query addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"jabber:iq:roster"]];
	
	NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	[iq addChild:query];
	
	[xmppStream sendElement:iq];
}

- (void)xmppStream:(XMPPStream *)xs didReceiveError:(id)error
{
	if(shouldSignIn)
	{
		shouldSignIn = NO;
		[signInButton setEnabled:YES];
		[registerButton setEnabled:YES];
		[messageField setStringValue:@"Invalid username/password"];
	}
	else if(shouldRegister)
	{
		shouldRegister = NO;
		[signInButton setEnabled:YES];
		[registerButton setEnabled:YES];
		[messageField setStringValue:@"Username is taken"];
	}
	else
	{
		NSLog(@"--- Unknown Error ---");
	}
}

- (void)xmppStream:(XMPPStream *)xs didReceiveIQ:(NSXMLElement *)iq
{
	if([self isRoster:iq])
	{
		[self updateRosterWithIQ:iq];
	}
	else
	{
		NSString *mail=[[iq attributeForName:@"id"] stringValue];
		NSLog(mail);
		if([mail isEqualToString:@"mail-request-1"])
		{
			
			NSLog(@"mail request");
			
			[mailWindow checkMail:iq];
			NSLog(@"mail request");
			
		}
		else if([mail isEqualToString:@"ss-1"])
		{
			NSLog(@"Shared Messages Displayed");
			NSLog([iq XMLString]);
			NSMutableArray *statuslist = [[iq elementForName:@"query"] elementsForName:@"status-list"];
			NSLog(@"%d",[statuslist count]);
			
			int k;
			for(k=0;k<[statuslist count];k++)
			{
				//NSLog([[statuslist objectAtIndex:k] stringValue]);
				[status_list addItemWithObjectValue:[[statuslist objectAtIndex:k] stringValue]];
			}
			//NSLog(@"%d",[statuslist count]);
		}
		else
		{
		
		NSLog(@"OTHER");
		//NSLog([iq stringValue]);
		NSString *id_value= [[[iq elementForName:@"iq"] attributeForName:@"id"] stringValue];
		NSLog(id_value);
		}
	}
}

- (void)xmppStream:(XMPPStream *)xs didReceiveMessage:(NSXMLElement *)message
{
	if([self isChatMessage:message])
	{
		[self handleChatMessage:message];
	}
	else
	{
		NSLog(@"--- Unknown Message ---");
	}
}

- (void)xmppStream:(XMPPStream *)xs didReceivePresence:(NSXMLElement *)presence
{
	if([self isBuddyRequest:presence])
	{
		[self handleBuddyRequest:presence];
	}
	else
	{
		[self updateRosterWithPresence:presence];
	}
}

- (void)xmppStreamDidClose:(XMPPStream *)xs
{
	[roster removeAllObjects];
	[rosterKeys release];
	rosterKeys = [[NSArray alloc] init];
	[NSApp beginSheet:signInSheet
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
}



- (BOOL)isRoster:(NSXMLElement *)iq
{
	NSXMLElement *query = [iq elementForName:@"query"];
	return [[query xmlns] isEqualToString:@"jabber:iq:roster"];
}


- (BOOL)isRosterItem:(NSXMLElement *)item
{
	NSXMLNode *subscription = [item attributeForName:@"subscription"];
	if([[subscription stringValue] isEqualToString:@"none"])
	{
		NSXMLNode *ask = [item attributeForName:@"ask"];
		if([[ask stringValue] isEqualToString:@"subscribe"]) {
			return YES;
		}
		else {
			return NO;
		}
	}
	return YES;
}


- (void)updateRosterWithIQ:(NSXMLElement *)iq
{
	NSArray *items = [[iq elementForName:@"query"] elementsForName:@"item"];
	
	int i;
	for(i = 0; i < [items count]; i++)
	{
		NSXMLElement *item = (NSXMLElement *)[items objectAtIndex:i];
		if([self isRosterItem:item])
		{
			NSString *jidKey = [[[item attributeForName:@"jid"] stringValue] lowercaseString];
				
			XMPPUser *user = [roster objectForKey:jidKey];
			if(user)
				[user updateWithItem:item];
			else
			{
				user = [[[XMPPUser alloc] initWithItem:item] autorelease];
				[roster setObject:user forKey:jidKey];
			}
		}
	}
	
	[rosterKeys release];
	rosterKeys = [[roster keysSortedByValueUsingSelector:@selector(compareByAvailabilityName:)] retain];
	
	[rosterTable abortEditing];
	[rosterTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[rosterTable reloadData];
	[grpTable reloadData];
	
	
	
}

- (BOOL)isChatMessage:(NSXMLElement *)message
{
	return [[[message attributeForName:@"type"] stringValue] isEqualToString:@"chat"];
}

- (void)handleChatMessage:(NSXMLElement *)message
{
	NSString *jidAndResource = [[message attributeForName:@"from"] stringValue];
	NSString *jid = [[jidAndResource componentsSeparatedByString:@"/"] objectAtIndex:0];
	NSString *jidKey = [jid lowercaseString];
	XMPPUser *user = [roster objectForKey:jidKey];
	[ChatWindowManager handleChatMessage:message withXMPPStream:xmppStream fromXMPPUser:user];
}

- (BOOL)isBuddyRequest:(NSXMLElement *)presence
{
	return [[[presence attributeForName:@"type"] stringValue] isEqualToString:@"subscribe"];
}

- (void)handleBuddyRequest:(NSXMLElement *)presence
{
	NSString *jidAndResource = [[presence attributeForName:@"from"] stringValue];
	NSString *jid = [[jidAndResource componentsSeparatedByString:@"/"] objectAtIndex:0];
	NSString *jidKey = [jid lowercaseString];
	if([roster objectForKey:jidKey])
	{
		NSXMLElement *response = [NSXMLElement elementWithName:@"presence"];
		[response addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
		[response addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"subscribed"]];
		
		[xmppStream sendElement:response];
	}
	else
	{
		[requestController handleBuddyRequest:jid];
	}
}

- (void)updateRosterWithPresence:(NSXMLElement *)presence
{
	NSString *jidAndResource = [[presence attributeForName:@"from"] stringValue];
	NSString *jid = [[jidAndResource componentsSeparatedByString:@"/"] objectAtIndex:0];
	NSString *jidKey = [jid lowercaseString];
	
	XMPPUser *user = [roster objectForKey:jidKey];
	[user updateWithPresence:presence];
	
	[rosterKeys release];
	rosterKeys = [[roster keysSortedByValueUsingSelector:@selector(compareByAvailabilityName:)] retain];
	
	[rosterTable abortEditing];
	[rosterTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[rosterTable reloadData];
	[grpTable reloadData];
}


-(IBAction)loadShared:(id)sender
{
	NSLog(@"Element Clicked");
	NSXMLElement *shared_id = [NSXMLElement elementWithName:@"iq"];
	[shared_id addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	[shared_id addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:[xmpp_username stringByAppendingString:@"@gmail.com"]]];
	[shared_id addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"ss-1"]];
	NSXMLElement *shared_query = [NSXMLElement elementWithName:@"query"];
	[shared_query addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"google:shared-status"]];
	[shared_query addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"2"]];
	[shared_id addChild:shared_query];
	[xmppStream sendElement:shared_id];
	NSLog(@"Element sENT");
}


-(IBAction)addUser:(id)sender
{
	NSLog(@"BUTTON CLICKED");
	NSIndexSet *selectedRows = [NSIndexSet initWithIndexSet:[grpTable selectedRowIndexes]];
	//selectedRows = ;
	NSLog(@"rows is %d",[selectedRows count]);
	
	/*if(selectedRow >= 0)
	{
		XMPPUser *user = [roster objectForKey:[rosterKeys objectAtIndex:selectedRow]];
		
		[ChatWindowManager openChatWindowWithXMPPStream:xmppStream forXMPPUser:user];
	}*/
}


-(IBAction)goOffline:(id)sender
{
	int selectedRow = [rosterTable selectedRow];
	int selectedRow1 = [rosterTable selectedRow];
	
	if(selectedRow1 >= 0)
	{
	XMPPUser *user = [roster objectForKey:[rosterKeys objectAtIndex:selectedRow]];
	NSXMLElement *iq_offline = [NSXMLElement elementWithName:@"iq"];
	[iq_offline addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"set"]];
	[iq_offline addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"otr-2"]];
	NSXMLElement *query_offline = [NSXMLElement elementWithName:@"query"];
	[query_offline addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"google:nosave"]];
	NSXMLElement *item_offline = [NSXMLElement elementWithName:@"item"];
	[item_offline addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"google:nosave"]];
	[item_offline addAttribute:[NSXMLNode attributeWithName:@"jid" stringValue:[user jid]]];
	[item_offline addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:@"enabled"]];
	[iq_offline addChild:query_offline];
	[query_offline addChild:item_offline];
	[xmppStream sendElement:iq_offline];
	}
	
	
}

-(IBAction)goInvisible:(id)sender
{
	NSXMLElement *iq_invisible	= [NSXMLElement elementWithName:@"iq"];
	NSXMLElement *query_invisible = [NSXMLElement elementWithName:@"query"];
	[query_invisible addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"google:shared-status"]];
	[query_invisible addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"2"]];
	NSXMLElement *invisible_value = [NSXMLElement elementWithName:@"invisible"];
	[invisible_value addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:@"true"]];
	[iq_invisible addChild:query_invisible];
	[query_invisible addChild:invisible_value];
	[iq_invisible addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"set"]];
	[iq_invisible addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"ss-2"]];
	[iq_invisible addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:[xmpp_username stringByAppendingString:@"@gmail.com"]]];
	[xmppStream sendElement:iq_invisible];
}


-(IBAction)checkEmail:(id)sender
{
	NSXMLElement *iq_mail	 = [NSXMLElement elementWithName:@"iq"];
	NSXMLElement *query_mail = [NSXMLElement elementWithName:@"query"];
	[iq_mail addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	[iq_mail addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"mail-request-1"]];
	[query_mail addAttribute:[NSXMLNode attributeWithName:@"xmlns" stringValue:@"google:mail:notify"]];
	[iq_mail addChild:query_mail];
	[xmppStream sendElement:iq_mail];
	
}

- (void)speechRecognizer:(NSSpeechRecognizer *)sender didRecognizeCommand:(id)aCmd {
    
	if ([(NSString *)aCmd isEqualToString:@"Invisible"]) {
		[self goInvisible:nil];
		
    }
	
    if ([(NSString *)aCmd isEqualToString:@"Chat"]) {
		[self chat:nil];
    }
	
    if ([(NSString *)aCmd isEqualToString:@"Status"]) {
		[self loadShared:nil];
    }
	
    if ([(NSString *)aCmd isEqualToString:@"Group Chat"]) {
		[self chat:nil];
    }
	
	
    if ([(NSString *)aCmd isEqualToString:@"Off the Record"]) {
		[self goOffline:nil];
    }
	
    if ([(NSString *)aCmd isEqualToString:@"Email"]) {
		[self checkEmail:nil];
    }
	
}
@end
