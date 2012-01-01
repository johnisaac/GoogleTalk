//
//  MailWindow.h
//  GTalk
//
//  Created by John Felix on 11/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class  XMPPStream;

@interface MailWindow : NSObject {
	IBOutlet NSTableView *mailTable;
	IBOutlet id mailWindow;
	NSMutableArray *mail_list;
}
-(void)checkMail:(NSXMLElement*)iq;
@end
