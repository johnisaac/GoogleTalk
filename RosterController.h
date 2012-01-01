#import <Cocoa/Cocoa.h>
@class  XMPPStream;

@interface RosterController : NSObject
{
	XMPPStream *xmppStream;
	
	NSMutableDictionary *roster;
	NSArray *rosterKeys;
	
	BOOL shouldSignIn;
	BOOL shouldRegister;
	
	int xmpp_port;
	BOOL usesSSL;
	BOOL allowsSelfSignedCertificates;
	NSString *xmpp_hostname;
	NSString *xmpp_username;
	NSString *xmpp_vhostname;
	NSString *xmpp_password;
	NSString *xmpp_resource;
	
	NSComboBox *status_list_box;
	NSSpeechRecognizer *recog;
    IBOutlet id buddyField;
    IBOutlet id jidField;
    IBOutlet id messageField;
    IBOutlet id passwordField;
    IBOutlet id portField;
    IBOutlet id registerButton;
    IBOutlet id requestController;
    IBOutlet id resourceField;
    IBOutlet id rosterTable;
    IBOutlet id selfSignedButton;
    IBOutlet id serverField;
    IBOutlet id signInButton;
    IBOutlet id signInSheet;
    IBOutlet id sslButton;
    IBOutlet id window;
	IBOutlet id status_msg;
	IBOutlet id grpTable;
	IBOutlet id mailWindow;
	IBOutlet id status_list;
	
}

- (IBAction)addBuddy:(id)sender;
- (IBAction)changePresence:(id)sender;
- (IBAction)chat:(id)sender;
- (IBAction)createAccount:(id)sender;
- (IBAction)removeBuddy:(id)sender;
- (IBAction)signIn:(id)sender;
- (IBAction)loadPresence:(id)sender;
- (IBAction)loadShared:(id)sender;
- (IBAction)addUser:(id)sender;
- (IBAction)goOffline:(id)sender;
- (IBAction)goInvisible:(id)sender;
- (IBAction)listen:(id)sender;
- (IBAction)checkEmail:(id)sender;
- (XMPPStream *)xmppStream;

@end
