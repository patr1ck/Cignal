
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

#import "LoginViewController.h"
#import "CignalAppDelegate.h"

#import "Parse/Parse.h"
#import "UIDevice+IdentifierAddition.h"

@interface LoginViewController ()
- (void)getMyTwitterIDForTwitterAccount:(ACAccount *)twitterAccount;
- (void)tryToLoginWithID:(NSString *)twitterID andScreenName:(NSString *)screenName;
@end

@implementation LoginViewController

- (IBAction)loginWithTwitterPressed:(id)sender;
{    
    CignalAppDelegate *appDelegate = (CignalAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Start up some overlay "Loading..." view here...
    
    // The we ask the app delegate to load the twitter account for us since it owns it.
    [appDelegate loadTwitterAccountWithCompletionHandler:^{
        [self getMyTwitterIDForTwitterAccount:appDelegate.twitterAccount];
    }];
}

- (void)getMyTwitterIDForTwitterAccount:(ACAccount *)twitterAccount;
{
    NSURL *requestEndpoint = [NSURL URLWithString:@"http://api.twitter.com/1/users/show.json"];
    NSDictionary *requestParameters = [NSDictionary dictionaryWithObjectsAndKeys:twitterAccount.username, @"screen_name", nil];
    
    TWRequest *twitterRequest = [[TWRequest alloc] initWithURL:requestEndpoint
                                                    parameters:requestParameters
                                                 requestMethod:TWRequestMethodGET];
    [twitterRequest setAccount:twitterAccount];
    [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        if (!error) {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData 
                                                                               options:0 
                                                                                 error:nil];
            NSString *myTwitterID = [[responseDictionary objectForKey:@"id"] stringValue];
            [self tryToLoginWithID:myTwitterID andScreenName:twitterAccount.username];
            
        } else {
            NSLog(@"ERROR: Couldn't get our own info from twitter.");
        }
        
    }];
    [twitterRequest autorelease];

}

- (void)tryToLoginWithID:(NSString *)twitterID andScreenName:(NSString *)screenName;
{
    CignalAppDelegate *appDelegate = (CignalAppDelegate *)[[UIApplication sharedApplication] delegate];

    
    [PFUser logInWithUsernameInBackground:twitterID password:@"" block:^(PFUser *user, NSError *error) {
        if (user) {
            // Successful login.
            NSLog(@"Logged in.");
            [appDelegate transitionToMainScreen];
        } else {
            // The username or password is invalid. 
            NSLog(@"Couldn't login. Creating account.");
            
            // The user probably doesn't exist, so create them.
            PFUser *user = [[[PFUser alloc] init] autorelease];
            user.username = twitterID;
            user.password = @"";
            [user setObject:screenName forKey:@"screen_name"];
            
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        
                        // User created. Go to the main screen.
                        NSLog(@"Success signing up.");
                        [appDelegate transitionToMainScreen];
                    } else {
                        NSString *errorString = [[error userInfo] objectForKey:@"error"];
                        NSLog(@"ERROR: Couldn't sign up: %@", errorString);
                        
                        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error Logging in" 
                                                                             message:errorString
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"Dismiss"
                                                                   otherButtonTitles:nil] autorelease];
                        [alertView show];
                        
                    }
                }];
        }
    }];

}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
