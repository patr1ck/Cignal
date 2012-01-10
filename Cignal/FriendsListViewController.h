//
//  FriendsListViewController.h
//  Cignal
//
//  Created by Patrick Gibson on 1/8/12.
//

#import <Parse/Parse.h>

@protocol FriendsListViewControllerDelegate <NSObject>
- (void)setSelectedUsers:(NSArray *)friends;
- (IBAction)closeModal:(id)sender;
@end


@interface FriendsListViewController : UITableViewController

@property (nonatomic, assign) id<FriendsListViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *selectedUsers;

@end
