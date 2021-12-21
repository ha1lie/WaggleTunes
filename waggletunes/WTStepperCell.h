#import <Preferences/PSSpecifier.h>
#import <Cephei/HBPreferences.h>

@interface PSControlTableCell : PSTableCell
-(UIControl *)control;
-(void)controlChanged:(id)arg1;
-(id)controlValue;
@end

@interface HBStepperTableCell : PSControlTableCell
@end

@interface WTStepperCell: HBStepperTableCell
@property UILabel *valueLabel;
@end