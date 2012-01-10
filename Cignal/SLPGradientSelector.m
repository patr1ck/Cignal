//
//  SLPGradientSelector.m
//  Cignal
//
//  Created by Patrick Gibson on 11-11-22.
//

#import "SLPGradientSelector.h"

#define kSliderTrackXInset 5
#define kSliderTrackYInset 5
#define kDeselectButtonWidthHeight 16
#define kSliderLeftRightWidth 5
#define kSliderTopBottomHeight 5
#define kSliderWidth 20

@interface SLPGradientSelector () {
    @private
    CGRect sliderTrackRect;
    CGRect sliderRect;
    CGRect gradientRect;
    CGRect deselectButtonRect;
}
@property (nonatomic, retain) NSArray *_colorLocations;
@property (nonatomic, retain) NSArray *_colors;
@property (nonatomic, retain) UIImageView *_sliderImageView;
@property (nonatomic, retain) UIView *_sliderColorView;
@property (nonatomic, retain) UIButton *_deselectButton;
@property (nonatomic, assign) BOOL _tracking;
@end


@implementation SLPGradientSelector

@synthesize _colorLocations;
@synthesize _colors;
@synthesize _sliderImageView;
@synthesize _sliderColorView;
@synthesize _deselectButton;
@synthesize _tracking;

@synthesize selectedColor;

#pragma mark - Object Lifecycle

- (id)initWithFrame:(CGRect)frame colorLocations:(NSArray *)colorLocations colors:(NSArray *)colors
{
    self = [super initWithFrame:frame];
    if (self) {
        self._colorLocations = colorLocations;
        self._colors = colors;
        self.selected = NO;
        self.backgroundColor = [UIColor clearColor];
        
        sliderTrackRect = CGRectMake(kSliderTrackXInset, 
                                     kSliderTrackYInset, 
                                     CGRectGetWidth(frame) - (kSliderTrackXInset*3) - kDeselectButtonWidthHeight,
                                     CGRectGetHeight(frame) - (kSliderTrackYInset*2));
                
        gradientRect = CGRectInset(sliderTrackRect, kSliderLeftRightWidth, kSliderTopBottomHeight);
        
        deselectButtonRect = CGRectMake(CGRectGetWidth(sliderTrackRect) + (kSliderTrackXInset*2),
                                        kSliderTrackYInset + kSliderTopBottomHeight,
                                        kDeselectButtonWidthHeight, 
                                        kDeselectButtonWidthHeight);
        
        _sliderColorView = [[UIView alloc] initWithFrame:CGRectZero];
        _sliderColorView.hidden = YES;
        [self addSubview:_sliderColorView];
        
        _sliderImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sliderFrame.png"]];
        _sliderImageView.hidden = YES;
        [self addSubview:_sliderImageView];
        
        _deselectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deselectButton setImage:[UIImage imageNamed:@"x_button.png"] forState:UIControlStateNormal];
        _deselectButton.frame = deselectButtonRect;
        _deselectButton.hidden = YES;
        [_deselectButton addTarget:self action:@selector(deselect) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_deselectButton];
        
    }
    return self;
}

- (void)dealloc {
    self._colors = nil;
    self._colorLocations = nil;
    self._sliderColorView = nil;
    self._sliderImageView = nil;
    self._deselectButton = nil;
    
    [super dealloc];
}

#pragma mark - Convenience

- (UIColor *)colorAtPoint:(float)xPoint betweenColor:(UIColor *)color1 andColor:(UIColor *)color2
{
    CGFloat red1, red2, newRed = 0;
    CGFloat green1, green2, newGreen = 0;
    CGFloat blue1, blue2, newBlue = 0;
    
    CGFloat alpha;
    
    // Just assume alpha is 1.0.
    [color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha];
    [color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha];
    
    newRed = (CGFloat) (red1 * (1 - xPoint) + red2 * xPoint);
    newGreen = (CGFloat) (green1 * (1 - xPoint) + green2 * xPoint);
    newBlue = (CGFloat) (blue1 * (1 - xPoint) + blue2 * xPoint);

    return [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:1.0];
}

// I need to clean this shit up like woah.
- (UIColor *)colorForPointOnTrack:(float)xPoint;
{
    // Calculate what the point is on a 0.0 - 1.0 basis
    CGFloat point = (CGFloat) xPoint / sliderTrackRect.size.width;

    
    // Okay, so the idea here is that we go through all the points starting at the left most, going up
    // until we find a color location that is greater than our point. Then we know the previous one is the one we want.
    // We do the same thing going the other way to find the color location on the right.
    int startIndex = 0;
    int endIndex = [_colorLocations count] - 1; 
    NSNumber *locationBefore = [_colorLocations objectAtIndex:startIndex];
    NSNumber *locationAfter = [_colorLocations objectAtIndex:endIndex];
    NSNumber *prevLocationBefore = nil;
    NSNumber *prevLocationAfter = nil;
    
    // left point
    while ([locationBefore floatValue] <= point) {
        prevLocationBefore = locationBefore;
        startIndex++;
        if (startIndex >= [_colorLocations count]) {
            break;
        }
        locationBefore = [_colorLocations objectAtIndex:startIndex];
    }
    int realStartIndex = (startIndex == 0) ? 0 : startIndex - 1;
    
    // right point
    while ([locationAfter floatValue] >= point) {
        prevLocationAfter = locationAfter;
        endIndex--;
        if (endIndex == 0) {
            break;
        }
        locationAfter = [_colorLocations objectAtIndex:endIndex];
    }
    int realEndIndex = (endIndex == ([_colors count] - 1)) ? endIndex : (endIndex + 1);
    
    CGFloat newFloor = (CGFloat) ([prevLocationBefore floatValue] + 0.0001) / [prevLocationAfter floatValue];
    CGFloat scopedPoint = (CGFloat) (point / [prevLocationAfter floatValue]) - newFloor;
    
    // Now that we know what two points we're between, we can figure out what color we should be.
    UIColor *newColor = [self colorAtPoint:scopedPoint 
                              betweenColor:[UIColor colorWithCGColor:(CGColorRef) [_colors objectAtIndex:realStartIndex]]
                                  andColor:[UIColor colorWithCGColor:(CGColorRef) [_colors objectAtIndex:realEndIndex]] ];
    
    [selectedColor release];
    selectedColor = [newColor retain];
    
    return newColor;
}

- (void)setSelectedAtXPoint:(CGFloat)xPoint
{
    self.selected = YES;    
    // Find the selected color.
    UIColor *newSelectedColor = [self colorForPointOnTrack:xPoint];
    
    sliderRect = CGRectMake(xPoint, 
                            kSliderTrackYInset, 
                            kSliderWidth, 
                            CGRectGetHeight(sliderTrackRect));
    
    // Add the box subview around the selected point, fill it with the selected color.
    _sliderColorView.backgroundColor = newSelectedColor;
    
    _sliderColorView.frame = sliderRect;
    _sliderImageView.frame = sliderRect;
    
    _sliderImageView.hidden = NO;
    _sliderColorView.hidden = NO;
    
    _deselectButton.hidden = NO;
}


#pragma mark - Gradient Drawing

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    int numberOfLocations = [_colorLocations count];
    
    CGFloat locations[numberOfLocations];
    
    int i = 0;
    for (NSNumber *location in _colorLocations) {
        locations[i++] = [location floatValue];
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)_colors, locations);
    
    // Draw the background
    //[[UIColor clearColor] set];
    //CGContextFillRect(context, rect);
    
    // Draw the track
    //[[UIColor blueColor] set];
    //CGContextFillRect(context, sliderTrackRect);
    
    // Draw the gradient
    CGContextSaveGState(context);
    CGContextAddRect(context, gradientRect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, 
                                gradient, 
                                CGPointMake(0, 0), 
                                CGPointMake(self.bounds.size.width, 0),
                                0);
    CGContextRestoreGState(context);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}

#pragma mark - Touch Handling

- (BOOL)isTracking
{
    return self._tracking;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{    
    // UIControl's tracking property isn't working for us, so let's just use our own.
    self._tracking = YES;
    
    // Check to see if the touch is within the area we care about.
    float xLocation = [touch locationInView:self].x;
    
    if (xLocation >= 0 && xLocation <= sliderTrackRect.size.width) {
        [self setSelectedAtXPoint:xLocation];
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    float xLocation = [touch locationInView:self].x;
    
    if (xLocation >= 0 && xLocation <= sliderTrackRect.size.width) {
        [self setSelectedAtXPoint:xLocation];
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
{
    self._tracking = NO;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

// Don't let our imageviews steal touches
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(deselectButtonRect, point)) {
        return _deselectButton;
    }
    
    return self;
}

#pragma mark - Public methods

- (void)setSelectedColor:(UIColor *)colorToSelect
{
    if (!colorToSelect) {
        [self deselect];
        return;
    }
    
    CGFloat gred, ggreen, gblue, galpha = 0;    
    [colorToSelect getRed:&gred green:&ggreen blue:&gblue alpha:&galpha];
    
    for (float i = 0; i <= sliderTrackRect.size.width; i += 0.1) {
        UIColor *trackColor = [self colorForPointOnTrack:i];
        CGFloat red1, green1, blue1, alpha1 = 0;
        [trackColor getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
        
        if (fabsf(gred - red1) > 0.001) {
            continue;
        }
        
        if (fabsf(ggreen - green1) > 0.001) {
            continue;
        }
        
        if (fabsf(gblue - blue1) > 0.001) {
            continue;
        }
        
        // If we got this far, the color match is close enough.
        [self setSelectedAtXPoint:i];
        
    }
}

- (void)deselect;
{
    [selectedColor release];
    selectedColor = nil;
    _deselectButton.hidden = YES;
    _sliderColorView.hidden = YES;
    _sliderImageView.hidden = YES;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
