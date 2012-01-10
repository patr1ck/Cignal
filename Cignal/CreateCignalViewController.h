//
//  CreateCignalViewController.h
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import <UIKit/UIKit.h>

#import "FriendsListViewController.h"

@interface CreateCignalViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FriendsListViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *invitedFriends;

- (IBAction)createNewCignal:(id)sender;

// FriendsListViewControllerDelegate
- (void)setSelectedUsers:(NSArray *)friends;
- (IBAction)closeModal:(id)sender;

@end
