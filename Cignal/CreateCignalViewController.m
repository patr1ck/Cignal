//
//  CreateCignalViewController.m
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import "Parse/Parse.h"

#import "CreateCignalViewController.h"
#import "CignalEditableTextTableViewCell.h"
#import "CignalSegmentedControlView.h"
#import "FriendsListViewController.h"

@interface CreateCignalViewController ()
@property (nonatomic, assign) UITextField *cignalTextField;
@property (nonatomic, retain) CignalSegmentedControlView *privacyControl;
@property (nonatomic, assign) BOOL showInvitedFriendsList;
@end

@implementation CreateCignalViewController

@synthesize tableView;
@synthesize invitedFriends;
@synthesize privacyControl;
@synthesize cignalTextField;
@synthesize showInvitedFriendsList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        privacyControl = [[CignalSegmentedControlView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        [privacyControl.segmentedControl addTarget:self
                                            action:@selector(privacyChange:)
                                  forControlEvents:UIControlEventValueChanged];
        self.showInvitedFriendsList = NO;
        self.invitedFriends = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    self.invitedFriends = nil;
    self.privacyControl = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)closeModal:(id)sender;
{
    [self.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)privacyChange:(UISegmentedControl *)segmentedControl;
{
    switch (segmentedControl.selectedSegmentIndex) {
        case 0: // Public
            if (self.showInvitedFriendsList == NO) { // Already not showing the list.
                return;
            } else {
                self.showInvitedFriendsList = NO;
                [self.tableView beginUpdates];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadSectionIndexTitles];
                [self.tableView endUpdates];

            }
            break;
        
        case 1: // Private
            if (self.showInvitedFriendsList == YES) { // Already showing the list.
                return;
            } else {
                self.showInvitedFriendsList = YES;
                [self.tableView beginUpdates];
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadSectionIndexTitles];
                [self.tableView endUpdates];
            }
            break;
            
        default:
            break;
    }
}



- (IBAction)createNewCignal:(id)sender;
{
    PFObject *cignal = [[[PFObject alloc] initWithClassName:@"Cignal"] autorelease];
    
    CFUUIDRef cfuuid = CFUUIDCreate(CFAllocatorGetDefault());
    CFStringRef uuidString = CFUUIDCreateString(CFAllocatorGetDefault(), cfuuid);
    NSString *uuid = (NSString *)uuidString;
    
    PFUser *meUser = [PFUser currentUser];
    
    if ([self.invitedFriends count] > 0) {
        PFACL *acl = [[[PFACL alloc] init] autorelease];
        [acl setPublicReadAccess:NO];
        [acl setPublicWriteAccess:NO];
        
        for (PFUser *user in self.invitedFriends) {
            [acl setReadAccess:YES forUser:user];
            [acl setWriteAccess:YES forUser:user];
        }
        
        [cignal setACL:acl];
    }
    
    [cignal setObject:uuid forKey:@"uuid"];
    [cignal setObject:cignalTextField.text forKey:@"title"];
    [cignal setObject:meUser forKey:@"owner"];
    [cignal setObject:[NSDate dateWithTimeIntervalSinceNow:(60 * 60 * 24)] forKey:@"expiry_date"];
    [cignal saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSString *channalName = [NSString stringWithFormat:@"cignal_%@", [meUser objectForKey:@"username"], nil];
            NSLog(@"Sending push notification to: %@", channalName);
            [PFPush sendPushMessageToChannelInBackground:channalName
                                             withMessage:[NSString stringWithFormat:@"New Cignal from %@: %@", [meUser objectForKey:@"screen_name"], cignalTextField.text, nil]];
        } else {
            NSLog(@"Couldn't create new cignal.");
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
                [self createNewCignal:nil];
            }
        }
    }];
    
    CFRelease(uuidString);
    CFRelease(cfuuid);
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - FriendsListViewControllerDelegate methods
- (void)setSelectedUsers:(NSMutableArray *)friends;
{
    self.invitedFriends = friends;
}


#pragma mark - UITableViewDelegate methods

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1) {
        return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2 && self.showInvitedFriendsList) {
        // Load and open the friends list view controller.
        FriendsListViewController *friendsListViewController = [[FriendsListViewController alloc] initWithStyle:UITableViewStylePlain];
        friendsListViewController.delegate = self;
        friendsListViewController.selectedUsers = self.invitedFriends;
        UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:friendsListViewController] autorelease];
        [friendsListViewController release];
        
        [self presentModalViewController:navController animated:YES];
        
    } else if (indexPath.section == 3 && self.showInvitedFriendsList){
        [self createNewCignal:nil];
    } else if (indexPath.section == 2 && !self.showInvitedFriendsList){
        [self createNewCignal:nil];
    }
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
{
    if (section == 1) {
        return 44;
    }
    
    return 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
{
    if (section == 1) {
        return privacyControl;
    }
    
    return nil;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if (section == 1) {
        return 0;
    }
    
    if (section == 2 && self.showInvitedFriendsList) {
        return [self.invitedFriends count] + 1;
    }
        
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // The cignal text section
    if (indexPath.section == 0) {
        static NSString *cellIdentifier = @"CignalEditableTextTableViewCell";
        CignalEditableTextTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[[CignalEditableTextTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        }
        
        if (indexPath.row == 0) {
            cignalTextField = cell.textField;
        }
        
        return cell;
    }
    
    // The Privacy controls section
    if (indexPath.section == 1) {
        return nil;
    }
    
    // 
    if (indexPath.section == 2 && self.showInvitedFriendsList) {
        if (indexPath.row == [self.invitedFriends count]) {
            static NSString *cellIdentifier = @"CignalAddFriendTableViewCell";
            UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
            }
            
            // I'd be nice to use the editing style + button here, but this class is already a little hacky.
            cell.textLabel.text = @"Invite a friend...";
            return cell;
        } else {
            static NSString *cellIdentifier = @"CignalFriendTableViewCell";
            UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
            }
            
            cell.textLabel.text = [[self.invitedFriends objectAtIndex:indexPath.row] objectForKey:@"screen_name"];
            return cell;
        }
    } else {
        
        static NSString *cellIdentifier = @"CignalTableViewCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        }
        
        cell.textLabel.text = @"Done";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        
    }
    
    static NSString *cellIdentifier = @"CignalTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.textLabel.text = @"Done";
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    switch (self.showInvitedFriendsList) {
        case YES:
            return 4;
            break;
        case NO:
            return 3;
        default:
            break;
    }
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    switch (section) {
        case 0:
            return nil;
            break;
        case 1:
            return @"Privacy";
            break;
        case 2:
            if (self.showInvitedFriendsList) {
                return @"Invited Friends";
            } else {
                return @"";
            }
            break;
        case 3:
            return nil;
            break;
            
        default:
            break;
    }
    
    return nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"New Cignal";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self 
                                                                            action:@selector(closeModal:)] autorelease];
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
