//
//  SLPGradientSelector.h
//  Cignal
//
//  Created by Patrick Gibson on 11-11-22.
//

#import <UIKit/UIKit.h>

@interface SLPGradientSelector : UIControl

@property (nonatomic, retain) UIColor *selectedColor;

- (id)initWithFrame:(CGRect)frame colorLocations:(NSArray *)colorLocations colors:(NSArray *)colors;
- (void)deselect;

@end
