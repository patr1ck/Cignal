//
//  CingnalViewController.h
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import <UIKit/UIKit.h>

#import "Parse/Parse.h"

@interface CignalViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) PFObject *cignal;
@property (nonatomic, retain) NSArray *otherReplies;
@property (nonatomic, retain) UIColor *myResponse;

@end
