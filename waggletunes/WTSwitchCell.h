#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PSSpecifier.h>

  //create a subclass of PSSwitchTableCell, it is recommended to change the XXX prefix to be the same as your preferences project prefix
@interface WTSwitchCell : PSSwitchTableCell
-(UIColor *)colorFromHex:(NSString *)hex withAlpha:(CGFloat)alpha;
@end