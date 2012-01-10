//
//  CignalEditableTextTableViewCell.m
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import "CignalEditableTextTableViewCell.h"

@implementation CignalEditableTextTableViewCell

@synthesize textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, self.frame.size.width - 40, self.frame.size.height)];
        [self.contentView addSubview:textField];
        textField.placeholder = @"Is it shark week yet?";
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyDone;
    }
    return self;
}

- (void)dealloc {
    [textField release];
    textField = nil;
    [super dealloc];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField; 
{
    [self.textField resignFirstResponder];
    return YES;
}


@end
