//
//  CignalSegmentedBarGraphCell.m
//  Cignal
//
//  Created by Patrick Gibson on 11-11-22.
//

#import "CignalSegmentedBarGraphCell.h"
#import "SLPWeightedGradientView.h"
#import "Parse/Parse.h"

@interface CignalSegmentedBarGraphCell () {
    SLPWeightedGradientView *gradient;
}
@end

@implementation CignalSegmentedBarGraphCell

@synthesize otherReplies;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        gradient = [[SLPWeightedGradientView alloc] initWithFrame:CGRectMake(20, 10, CGRectGetWidth(self.frame) - 40, CGRectGetHeight(self.frame) - 20)];
        [self addSubview:gradient];
    }
    return self;
}

- (void)dealloc {
    [gradient release], gradient = nil;
    [super dealloc];
}

- (void)setOtherReplies:(NSArray *)_otherReplies
{
    [gradient removeAllWeights];
    
    for (PFObject *reply in _otherReplies) {
        CGFloat red = [[reply objectForKey:@"red"] floatValue];
        CGFloat green = [[reply objectForKey:@"green"] floatValue];
        CGFloat blue = [[reply objectForKey:@"blue"] floatValue];
        [gradient addWeightWithColor:[UIColor colorWithRed:red green:green blue:blue alpha:1.0]];
    }
    
    [gradient setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
