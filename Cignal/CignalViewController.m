//
//  CingnalViewController.m
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import "CignalViewController.h"

#import "CignalColorSelectorCell.h"
#import "CignalSegmentedBarGraphCell.h"

typedef enum {
    CignalSectionTitle = 0,
    CignalSectionYourResponse = 1,
    CignalSectionAllResponses = 2
} CignalSection;

@interface CignalViewController ()
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, retain) NSLock *responseTxLock;
- (void)refreshAllReplies;
@end


@implementation CignalViewController

@synthesize cignal;
@synthesize myResponse;
@synthesize tableView;
@synthesize otherReplies;
@synthesize isLoading;
@synthesize responseTxLock;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.myResponse =  nil;
        self.title = @"Cignal";
        self.isLoading = YES;
        responseTxLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc {
    self.responseTxLock = nil;
    self.myResponse = nil;
    [cignal release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Cignal Methods
- (void)updateCignalResponseWithColor:(UIColor *)color
{
    // Don't update if we're already updating. This is a bit of a hack... 
    // Really we should cancel pending responses if we get a new one.
    if ([responseTxLock tryLock]) {
    
        self.myResponse = color;
        
        PFUser *currentUser = [PFUser currentUser];
        NSString *userID = currentUser.objectId;
        
        // Look for an existing reply
        PFQuery *query = [PFQuery queryWithClassName:@"CignalReply"];
        [query whereKey:@"cignal" equalTo:self.cignal.objectId];
        [query whereKey:@"owner" equalTo:userID];
    
        CGFloat red1, green1, blue1, alpha1 = 0;    
        [color getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            PFObject *reply = [[[PFObject alloc] initWithClassName:@"CignalReply"] autorelease];
            NSLog(@"reply is: %@", reply);
            
            if ([objects count] == 1) {
                // Update it, if we have one.
                reply = [objects objectAtIndex:0];
                [reply setObject:[NSNumber numberWithFloat:red1] forKey:@"red"];
                [reply setObject:[NSNumber numberWithFloat:green1] forKey:@"green"];
                [reply setObject:[NSNumber numberWithFloat:blue1] forKey:@"blue"];
            } else if ([objects count] == 0) {
                // Create a new one, if we don't.
                reply = [[[PFObject alloc] initWithClassName:@"CignalReply"] autorelease];
                [reply setObject:[NSNumber numberWithFloat:red1] forKey:@"red"];
                [reply setObject:[NSNumber numberWithFloat:green1] forKey:@"green"];
                [reply setObject:[NSNumber numberWithFloat:blue1] forKey:@"blue"];
                [reply setObject:self.cignal.objectId forKey:@"cignal"];
                [reply setObject:userID forKey:@"owner"];
            } else {
                NSLog(@"We got back more than one cignal reply for this user. Weird.");
            }
            
            // Save it
            NSLog(@"Trying to save your response... %@", reply);
            [reply saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    NSLog(@"Couldn't save! %@", [error localizedDescription]);
                }
                [self refreshAllReplies];
                [responseTxLock unlock];
            }];
        }];
        
    }
}

- (void)refreshAllReplies;
{
    // Look for other replies..
    PFQuery *query = [PFQuery queryWithClassName:@"CignalReply"];
    [query whereKey:@"cignal" equalTo:self.cignal.objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        // Set our replies
        self.otherReplies = objects;
        
        // If one of the replies is our own, set that as well.
        for (PFObject *reply in objects) {
            if ([[reply objectForKey:@"owner"] isEqual:[[PFUser currentUser] objectId]]) {
                CGFloat red = [[reply objectForKey:@"red"] floatValue];
                CGFloat green = [[reply objectForKey:@"green"] floatValue];
                CGFloat blue = [[reply objectForKey:@"blue"] floatValue];
                
                self.myResponse = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView reloadData];
        });
        
    }];
}


#pragma mark - Actions

- (void)updateColorSelection:(SLPGradientSelector *)selector
{
    // Don't update if the user is still moving around.
    if (selector.tracking) {
        return;
    }
    
    [self updateCignalResponseWithColor:selector.selectedColor];
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == CignalSectionTitle) {
        CGSize textSize = [[self.cignal objectForKey:@"title"] sizeWithFont:[UIFont boldSystemFontOfSize:16.0] 
                                                          constrainedToSize:CGSizeMake(280, 500)
                                                              lineBreakMode:UILineBreakModeWordWrap];
        return (textSize.height < 44) ? 44 : (textSize.height + 20);
    }
    
    return 44;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier1 = @"CignalTableViewCell";
    static NSString *colorViewIdentifier = @"ColorViewIdentifier";
    static NSString *colorSelectorIdentifier = @"CignalColorSelectorCell";
    UITableViewCell *cell = nil;
    
    // CREATION
    switch (indexPath.section) {
        case CignalSectionYourResponse: {
            cell = [tableView dequeueReusableCellWithIdentifier:colorSelectorIdentifier];
            if (cell == nil) {
                cell = [[[CignalColorSelectorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:colorSelectorIdentifier] autorelease];
                [((CignalColorSelectorCell *)cell).gradientSelector addTarget:self action:@selector(updateColorSelection:) forControlEvents:UIControlEventValueChanged];
            }
            break;
        }
        case CignalSectionTitle: {
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier1];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier1] autorelease];
            }
            break;
        }
        case CignalSectionAllResponses: {
            cell = [tableView dequeueReusableCellWithIdentifier:colorViewIdentifier];
            if (cell == nil) {
                cell = [[[CignalSegmentedBarGraphCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:colorViewIdentifier] autorelease];
            }
            break;
        }    
        default:
            break;
    }

    // CONFIGURATION
    switch (indexPath.section) {
        case CignalSectionYourResponse: {
            if (self.myResponse) {
                CignalColorSelectorCell *colorSelectorCell = (CignalColorSelectorCell *)cell;
                colorSelectorCell.gradientSelector.selectedColor = myResponse;
            }
            break;
        }
        case CignalSectionTitle: {
            cell.textLabel.text = [cignal objectForKey:@"title"];
            cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
            cell.textLabel.numberOfLines = 10;
            break;
        }
        case CignalSectionAllResponses: {
            [(CignalSegmentedBarGraphCell *)cell setOtherReplies:otherReplies];
            break;
        }    
        default:
            break;
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{    
    if (section == CignalSectionAllResponses) {
        if ([otherReplies count] == 0) {
            return 0;
        }
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)_tableView titleForHeaderInSection:(NSInteger)section;
{
    switch (section) {
        case CignalSectionTitle:
            return @"";
            break;
        case CignalSectionYourResponse:
            return @"Your Response";
            break;
        case CignalSectionAllResponses:
            return @"All Responses";
            break;
            
        default:
            break;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)_tableView titleForFooterInSection:(NSInteger)section;
{
    switch (section) {
        case CignalSectionTitle:
            return [NSString stringWithFormat:@"Created by @%@", [[cignal objectForKey:@"owner"] objectForKey:@"screen_name"]];
            break;
        case CignalSectionYourResponse:
            return nil;
            break;
        case CignalSectionAllResponses:
            if ([otherReplies count] == 0) {
                return @"No responses yet!";
            }
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refreshAllReplies];
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
