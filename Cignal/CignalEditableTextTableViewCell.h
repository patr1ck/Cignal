//
//  CignalEditableTextTableViewCell.h
//  Cignal
//
//  Created by Patrick Gibson on 11/10/11.
//

#import <UIKit/UIKit.h>

@interface CignalEditableTextTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, retain) UITextField *textField;

@end
