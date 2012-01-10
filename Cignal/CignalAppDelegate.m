
#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import "Parse/Parse.h"

#import "CignalAppDelegate.h"
#import "LoginViewController.h"
#import "CignalListViewController.h"

#ifdef DEBUG
#import "TestFlight.h"
#endif

@implementation CignalAppDelegate


@synthesize window=_window;

@synthesize loginViewController=_loginViewController;
@synthesize navController=_navController;

@synthesize twitterAccount;
@synthesize accountStore;
@synthesize friendList;

- (void)transitionToMainScreen;
{
    self.window.rootViewController = self.navController;

    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionFade];
    [animation setDuration:1.5];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[self.window layer] addAnimation:animation forKey:@"TransitionToMainScreen"];
}

- (void)loadTwitterAccountWithCompletionHandler:(CignalLoadTwitterCompletionHandler)handler;
{
    // Grab the users Twitter account
    if (self.accountStore == nil || self.twitterAccount == nil) {    
        self.accountStore = [[[ACAccountStore alloc] init] autorelease];
        ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [self.accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
            
            if (error) {
                
                // We should never actually show the user some random error, but leave this in for debugging purposes for now.
                UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error" 
                                                                     message:[error localizedDescription]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Dismiss"
                                                           otherButtonTitles:nil] autorelease];
                [alertView show];
                NSLog(@"ERROR: %@", [error localizedDescription]);
            }
            

            if (granted) {
                NSArray *accountsArray = [self.accountStore accountsWithAccountType:accountType];
                
                // XXX: Handle the more-than-1-account case.
                
                if ([accountsArray count] > 0) {
                    self.twitterAccount = [accountsArray objectAtIndex:0];
                    handler();
                } else {
                    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"No Twitter Accounts" 
                                                                         message:@"Sorry, looks like this device has no Twitter accounts. Add some and try again!"
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Dismiss"
                                                               otherButtonTitles:nil] autorelease];
                    [alertView show];
                }
            } else {
                UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Can't login without Twitter!" 
                                                                    message:@"Sorry, we can't log you in without Twitter access."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Try Again"
                                                          otherButtonTitles:nil] autorelease];
                [alertView show];
            } // End "granted" conditional
            
        }]; // End request access to twitter accounts block
        
    }
}

#pragma mark - Application Events

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
// Check out the Run Script build script phase to see how these are populated.    
#ifdef DEBUG
    [TestFlight takeOff:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"TestFlightKey"]];
    [Parse setApplicationId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"ParseDevAppID"] 
                  clientKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"ParseDevClientKey"]];
#else
    [Parse setApplicationId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"ParseProdAppID"] 
                  clientKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"ParseProdClientKey"]];
#endif
    

    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self loadTwitterAccountWithCompletionHandler:^{}];
        self.window.rootViewController = self.navController;
    } else {
        self.window.rootViewController = self.loginViewController;
    }
    
    [self.window makeKeyAndVisible];
    
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                    UIRemoteNotificationTypeAlert|
                                                    UIRemoteNotificationTypeSound];
    return YES;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    [PFPush storeDeviceToken:newDeviceToken];
    [PFPush subscribeToChannelInBackground:@"" withTarget:self selector:@selector(subscribeFinished:error:)];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
	if ([error code] != 3010) // 3010 is for the iPhone Simulator
    {
        // show some alert or otherwise handle the failure to register.
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // If the user is logged in when the app comes to the foreground, refresh all cignals.
    
    if ([PFUser currentUser]) {
        CignalListViewController *listVC = [self.navController.viewControllers objectAtIndex:0];
        if ([listVC isKindOfClass:[CignalListViewController class]]) {
            [listVC refreshCignals];
        }
    }
     
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
    } else {
        NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
    }
}

- (void)dealloc
{
    self.accountStore = nil;
    [_window release];
    [_loginViewController release];
    [_navController release];
    [super dealloc];
}

@end
