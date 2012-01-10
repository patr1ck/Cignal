//
//  CignalViewController.h
//  Cignal
//
//  Created by Patrick Gibson on 11/9/11.
//

#import <UIKit/UIKit.h>

@interface CignalListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *cignals;
@property (nonatomic, retain) NSMutableDictionary *cignalResponseCounts;

- (IBAction)createCignalPressed:(id)sender;
- (void)refreshCignals;

@end
