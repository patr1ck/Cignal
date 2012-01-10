//
//  CignalColorSelectorCell.m
//  Cignal
//
//  Created by Patrick Gibson on 11-11-22.
//

#import "CignalColorSelectorCell.h"

@implementation CignalColorSelectorCell

@synthesize gradientSelector;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        NSMutableArray *colors = [NSMutableArray array];
        NSMutableArray *locations = [NSMutableArray array];
        UIColor *redColor = [UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0];
        [colors addObject:(id)[redColor CGColor]];
        [locations addObject:[NSNumber numberWithFloat:0.0]];
        
        UIColor *yellowColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.0 alpha:1.0];
        [colors addObject:(id)[yellowColor CGColor]];
        [locations addObject:[NSNumber numberWithFloat:0.5]];
        
        UIColor *greenColor = [UIColor colorWithRed:0.0 green:0.9 blue:0.0 alpha:1.0];
        [colors addObject:(id)[greenColor CGColor]];
        [locations addObject:[NSNumber numberWithFloat:1.0]];
        
        gradientSelector = [[SLPGradientSelector alloc] initWithFrame:CGRectMake(15, 5, 285, 34) 
                                                       colorLocations:locations 
                                                               colors:colors];
        [self addSubview:gradientSelector];
    }
    return self;
}

- (void)dealloc {
    self.gradientSelector = nil;
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
