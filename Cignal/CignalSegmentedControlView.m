//
//  CignalSegmentedControlView.m
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import "CignalSegmentedControlView.h"

@implementation CignalSegmentedControlView

@synthesize segmentedControl;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Public", @"Private", nil]];
        [self addSubview:segmentedControl];
        segmentedControl.frame = CGRectMake(10, 0, self.frame.size.width - 20, self.frame.size.height);
        [segmentedControl setSelectedSegmentIndex:0];
    }
    return self;
}

- (void)dealloc {
    [segmentedControl release];
    segmentedControl = nil;
    [super dealloc];
}

@end
