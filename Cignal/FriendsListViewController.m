//
//  FriendsListViewController.m
//  Cignal
//
//  Created by Patrick Gibson on 1/8/12.
//

#import "FriendsListViewController.h"

#import "CreateCignalViewController.h"

@interface FriendsListViewController ()
@property (nonatomic, retain) NSMutableArray *_friends;
- (void)refreshFriends;
@end

@implementation FriendsListViewController

@synthesize selectedUsers;
@synthesize delegate;
@synthesize _friends;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.selectedUsers = [NSMutableArray arrayWithCapacity:10];
        _friends = [[NSMutableArray alloc] initWithCapacity:10]; 
        
        self.title = @"Select Friends";
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                                   style:UIBarButtonItemStyleDone
                                                                                  target:self 
                                                                                  action:@selector(closeModal:)]autorelease];
    }
    return self;
}

- (void)dealloc
{
    self._friends = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshFriends];
    // Do any additional setup after loading the view from its nib.
}

- (void)closeModal:(id)sender;
{
    [delegate setSelectedUsers:self.selectedUsers];
    [delegate closeModal:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)refreshFriends;
{
    NSLog(@"Refreshing friends");
    PFUser *currentUser = [PFUser currentUser];
    PFQuery *friendsQuery = [PFQuery queryWithClassName:@"_User"];
    
    NSMutableArray *friendListStrings = [NSMutableArray array];
    
    // XXX THIS IS SILLY
    for (NSNumber *friendID in [currentUser objectForKey:@"friends_list"]) {
        [friendListStrings addObject:[NSString stringWithFormat:@"%d", [friendID intValue], nil]];
    }
    
    [friendsQuery whereKey:@"username" containedIn:friendListStrings];
    
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Got back %i objects, updating table...", [objects count]);
        if (!error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Updating table..");
                self._friends = [objects mutableCopy];
                [self.tableView reloadData];
            });
            
        } else {
            NSLog(@"ERROR refeshing friends: %@", [error localizedDescription]);
        }
        
    }];
}

- (PFQuery *)queryForTable
{
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    PFUser *currentUser = [PFUser currentUser];
    
    NSMutableArray *friendListStrings = [NSMutableArray array];
    
    // XXX THIS IS SILLY
    for (NSNumber *friendID in [currentUser objectForKey:@"friends_list"]) {
        [friendListStrings addObject:[NSString stringWithFormat:@"%d", [friendID intValue], nil]];
    }
    
    [query whereKey:@"username" containedIn:friendListStrings];
    
    return query;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    PFUser *user = [_friends objectAtIndex:indexPath.row];
    
    // Configure the cell
    cell.textLabel.text = [user objectForKey:@"screen_name"];
    
    NSLog(@"Selected users: %@", selectedUsers);
    NSLog(@"checking for user: %@", user);
    
    // Silly hack to work around the different PFUser objects not correctly responding to isEqual
    BOOL alreadySelected = NO;
    for (PFUser *alreadySelectedUser in self.selectedUsers) {
        if ([[alreadySelectedUser objectForKey:@"username"] isEqualToString:[user objectForKey:@"username"]]) {
            alreadySelected = YES;
        }
    }
    
    if (alreadySelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return [_friends count];
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    PFUser *selectedUser = [_friends objectAtIndex:indexPath.row];

    // Silly hack to work around the different PFUser objects not correctly responding to isEqual
    BOOL alreadySelected = NO;
    PFUser *oldUser = nil;
    for (PFUser *alreadySelectedUser in self.selectedUsers) {
        if ([[alreadySelectedUser objectForKey:@"username"] isEqualToString:[selectedUser objectForKey:@"username"]]) {
            alreadySelected = YES;
            oldUser = alreadySelectedUser;
        }
    }
    if (!alreadySelected) { 
        // If we don't have that user in our list, select them.
        [self.selectedUsers addObject:selectedUser];
    } else { 
        // Otherwise, we already have them, so remove them.
        [self.selectedUsers removeObject:oldUser];
    }
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
    
    [self.tableView selectRowAtIndexPath:indexPath 
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];

    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
