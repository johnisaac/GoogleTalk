//
//  MailWindow.m
//  GTalk
//
//  Created by John Felix on 11/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MailWindow.h"
#import "RosterController.h"
#import "RequestController.h"
#import "XMPPStream.h"
#import "XMPPUser.h"
#import "ChatWindowManager.h"


@implementation MailWindow

-(id)init
{
	[super init];
	mail_list = [[ NSMutableArray alloc] init];
	mailTable = [[NSTableView alloc] init];
	return self;
}

-(IBAction)checkMail:(NSXMLElement*)iq
{
	NSLog(@"CHECK EMAIL");
	NSString *sender1 = [iq XMLString];
	NSXMLElement *sender_name_xml = [NSXMLElement new];
	NSString *sender_name = [NSString new];
	NSString *subject = [NSString new];
	NSString *from=@" From ";
	NSXMLElement   *sender_o;
	NSMutableArray *sender_list;
	//NSString *sender_name;
	NSArray *x=[[iq elementForName:@"mailbox"]  elementsForName:@"mail-thread-info"];
	NSLog(@"%d",[x count]);
	int j;
	
	for(j = 0; j < [x count]; j++)
	{
		sender_o = (NSXMLElement *)[x objectAtIndex:j];
		sender_name_xml =(NSXMLElement *)[[sender_o elementForName:@"senders"] elementForName:@"sender"];
		sender_name=[[sender_name_xml attributeForName:@"name" ] XMLString];
		//dummy = sender_name;
		subject = [[sender_o elementForName:@"subject"] stringValue];
		NSString *content = [sender_name stringByAppendingString:subject];
		[mailWindow orderFront:self];
		NSLog([sender_o XMLString]);
		NSLog(@"SENDER NAME");
		NSLog(sender_name);
		
		
		NSLog(subject);
		[mail_list addObject:subject];
	}
	NSLog(@" array count is %d",[mail_list count]);
	//[mail_list addObject:@"hi"];
	[mailTable reloadData];
	[mailWindow orderFront:self];

}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [mail_list count];
}

- (id)tableView:(NSTableView *)aTableView
   objectValueForTableColumn:(NSTableColumn *)aTableColumn
   row:(int)rowIndex;
{
	NSLog(@"Some item selected at ROW %d ", rowIndex);
	return [mail_list objectAtIndex:rowIndex];
	//return @"hello";
}

@end
