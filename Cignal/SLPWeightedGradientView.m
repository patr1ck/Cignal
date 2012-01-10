//
//  SLPWeightedGradientView.m
//  Cignal
//
//  Created by Patrick Gibson on 11/22/11.
//

#import "SLPWeightedGradientView.h"

#pragma mark - CoreGraphics Helper Methods
void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);
void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color) {
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);        
    
}

@interface SLPGradientWeight : NSObject 
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, assign) int count;
@end

@implementation SLPGradientWeight
@synthesize color, count;
@end


@interface SLPWeightedGradientView ()
@property (nonatomic, retain) NSArray *_colorLocations;
@property (nonatomic, retain) NSArray *_colors;
@property (nonatomic, retain) NSMutableArray *_cweights;
@end

@implementation SLPWeightedGradientView

@synthesize _colorLocations;
@synthesize _colors;
@synthesize _cweights;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cweights = [[NSMutableArray alloc] initWithCapacity:10];
        self.backgroundColor = [UIColor purpleColor];
    }
    return self;
}

- (void)dealloc {
    self._cweights = nil;
    self._colorLocations = nil;
    self._colors = nil;
    [super dealloc];
}

- (void)addWeightWithColor:(UIColor *)newColor;
{
    
    //
    //if ([newColor isEqual:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]]) {
    //    return;
    //}
    
    /* This is sort of silly, but comes out of the evolution of this product.
     Orginally there were a discrete number of response states, so in displaying the responses,
     we wanted to group the identical ones together. Now that we have a continuous color bar,
     it's extremely unlikely that now states will be the exact same color. Regardless, I've left
     this code in just in case.
     */
    for (SLPGradientWeight *weight in _cweights) {
        if ([weight.color isEqual:newColor]) {
            weight.count++;
            return;
        }
    }
    
    // The weight didn't exist, so add it.
    SLPGradientWeight *newWeight = [[SLPGradientWeight alloc] init];
    newWeight.color = newColor;
    newWeight.count = 1;
    [_cweights addObject:newWeight];
    [newWeight release];
    
    // Sort weights so they reflect the selector gradient
    [_cweights sortUsingComparator:^NSComparisonResult(SLPGradientWeight *obj1, SLPGradientWeight *obj2) {
        UIColor *color1 = obj1.color;
        UIColor *color2 = obj2.color;
        CGFloat red1, green1, blue1, alpha1 = 0;
        CGFloat red2, green2, blue2, alpha2 = 0;
        [color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
        [color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
        
        if (green1 != green2 && red1 == red2) { // Comparing two red-ish values
            if (green1 < green2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        } else if (red1 != red2 && green1 == green2) { // Comparing two green-ish values
            if (red1 < red2) {
                return NSOrderedDescending;
            } else {
                return NSOrderedAscending;
            }
        } else if (red1 == green2 || red2 == green1) { // Comparing a red-ish to a green-ish values
            if (red1 > red2)
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }

    }];
}

- (void)removeAllWeights;
{
    [_cweights removeAllObjects];
}


- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat xValue = 0.0;
    
    for (SLPGradientWeight *weight in _cweights) {
        [weight.color set];
        
        CGFloat weightWidth = ceilf(self.frame.size.width / [_cweights count]);
        
        CGRect segmentedBar = CGRectMake(xValue, 0, weightWidth, self.frame.size.height);
        CGContextFillRect(context, segmentedBar);
        
        if (xValue != 0.0) {
            //draw1PxStroke(context, CGPointMake(xValue, 0), CGPointMake(xValue, self.frame.size.height), [UIColor lightGrayColor].CGColor);
        }
        
        xValue += weightWidth;
    }
}



@end
