
#import <UIKit/UIKit.h>

#import <Accounts/Accounts.h>

typedef void(^CignalLoadTwitterCompletionHandler)(void);

@class LoginViewController;

@interface CignalAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet LoginViewController *loginViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;

@property (nonatomic, retain) NSArray *friendList;
@property (nonatomic, retain) ACAccountStore *accountStore;
@property (nonatomic, retain) ACAccount *twitterAccount;


- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error;

- (void)transitionToMainScreen;
- (void)loadTwitterAccountWithCompletionHandler:(CignalLoadTwitterCompletionHandler)handler;

@end
