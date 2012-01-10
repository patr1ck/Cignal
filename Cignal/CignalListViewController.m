//
//  CignalViewController.m
//  Cignal
//
//  Created by Patrick Gibson on 11/9/11.
//

#import "CignalListViewController.h"
#import "CreateCignalViewController.h"
#import "CignalViewController.h"
#import "CignalAppDelegate.h"

#import <Twitter/Twitter.h>
#import "Parse/Parse.h"

@interface CignalListViewController ()
- (void)refreshResponseCountForCignal:(PFObject *)cignal;
- (void)updateMyFriends:(NSArray *)friendIDs;
@end

@implementation CignalListViewController

@synthesize tableView;
@synthesize cignals;
@synthesize cignalResponseCounts;


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Twitter Methods

- (void)refreshFriendsListFromTwitter;
{
    // Ensure we have a twitter account.
    CignalAppDelegate *appDelegate = (CignalAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate loadTwitterAccountWithCompletionHandler:^{}];
    
    ACAccount *twitterAccount = appDelegate.twitterAccount;

    NSURL *requestEndpoint = [NSURL URLWithString:@"http://api.twitter.com/1/friends/ids.json"];
    
    TWRequest *twitterRequest = [[[TWRequest alloc] initWithURL:requestEndpoint
                                                    parameters:nil
                                                 requestMethod:TWRequestMethodGET] autorelease];
    [twitterRequest setAccount:twitterAccount];
    [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        if (!error) {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData 
                                                                               options:0 
                                                                                 error:nil];
            
            NSArray *friendIDs = [responseDictionary objectForKey:@"ids"];
            [self updateMyFriends:friendIDs];
        } else {
            NSLog(@"ERROR: Couldn't get our friends list info from twitter.");
        }
        
    }];
}

#pragma mark - Parse Methods

- (void)updateTableWithCignals:(NSArray *)_cignals
{
    self.cignals = _cignals;
    [tableView reloadData];
}

- (void)updateMyFriends:(NSArray *)friendIDs;
{
    PFUser *meUser = [PFUser currentUser];
    [meUser setObject:friendIDs forKey:@"friends_list"];

    [meUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            NSLog(@"Couldn't save updated friends list!");
        } else {
            NSLog(@"Done saving friends list. Updating subscriptions");
            
            /// XXX should really get all existing subscriptions, compare against those, and (un)subscribe as needed.
            for (NSNumber *userID in friendIDs) {
                NSString *channalName = [NSString stringWithFormat:@"cignal_%@", userID , nil]; 
                NSLog(@"Subscribing to %@", channalName);
                [PFPush subscribeToChannelInBackground:channalName
                                                 block:^(BOOL succeeded, NSError *error) {
                                                     if (succeeded) {
                                                         NSLog(@"Successfully subscribed to %@", channalName);
                                                     } else {
                                                         NSLog(@"Couldn't subscribe to %@", channalName);
                                                         if (error) {
                                                             NSLog(@"Error was: %@", [error localizedDescription]);
                                                         }
                                                     }
                                                 }];
            }
            
        }
    }];

}

- (void)refreshCignals;
{
    NSLog(@"Refreshing cignals");
    PFQuery *cignalsQuery = [PFQuery queryWithClassName:@"Cignal"];
    [cignalsQuery whereKey:@"expiry_date" greaterThanOrEqualTo:[NSDate date]];
    [cignalsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Got back %i objects, updating table...", [objects count]);
        if (!error) {
            
            for (PFObject *cignal in objects) {
                NSLog(@"Refreshing response for cignal: %@", cignal);
                [self refreshResponseCountForCignal:cignal];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Updating table..");
                [self updateTableWithCignals:objects];
            });
            
        } else {
            NSLog(@"ERROR refeshing cignals: %@", [error localizedDescription]);
        }

    }];
}

- (void)refreshResponseCountForCignal:(PFObject *)cignal;
{
    NSLog(@"Refreshing response count for cignal: %@", cignal);
    PFQuery *cignalsQuery = [PFQuery queryWithClassName:@"CignalReply"];
    [cignalsQuery whereKey:@"cignal" equalTo:cignal.objectId];
    [cignalsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Got back the cignal replies, updating count...");
        if (!error) {
            [self.cignalResponseCounts setObject:[NSNumber numberWithInt:[objects count]] forKey:[cignal objectForKey:@"uuid"]];
            [tableView reloadData];
        } else {
            NSLog(@"ERROR refreshing response count for cignal (%@): %@", cignal, [error localizedDescription]);
        }
    }];
}


#pragma mark - IBActions

-(IBAction)createCignalPressed:(id)sender;
{
    CreateCignalViewController *createViewController = [[CreateCignalViewController alloc] initWithNibName:nil 
                                                                                                    bundle:nil];
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:createViewController] autorelease];
    [createViewController release];
    [self presentModalViewController:navController animated:YES];
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CignalViewController *cignalViewController = [[[CignalViewController alloc] initWithNibName:nil 
                                                                                         bundle:nil] autorelease];
    cignalViewController.cignal = [cignals objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:cignalViewController animated:YES];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return [cignals count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CignalTableViewCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
    }

    if ([cignals count] > 0) {
        PFObject *thisCignal = [cignals objectAtIndex:indexPath.row];
        cell.textLabel.text = [thisCignal objectForKey:@"title"];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d Responses", 
                                     [[self.cignalResponseCounts objectForKey:[thisCignal objectForKey:@"uuid"]] intValue]];
    }

    return cell;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
     self.title = @"Cignals";
    cignalResponseCounts = [[NSMutableDictionary alloc] initWithCapacity:10];
    [self refreshFriendsListFromTwitter];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshCignals];
    
    [PFPush getSubscribedChannelsInBackgroundWithBlock:^(NSSet *channels, NSError *error) {
        NSLog(@"Subscribed to: %@", channels);
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
