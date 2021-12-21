#import "WTSwitchCell.h"

@implementation WTSwitchCell

  -(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];

    //set the on tint color of the switch using the properties from the specifier
    if(self) {
      NSString *hexString = ([specifier propertyForKey:@"switchColor"]) ?: @"#FFFFFF";
      float hexAlpha = ([[specifier propertyForKey:@"switchColorAlpha"] floatValue]) ?: 1.0;
      ((UISwitch *)self.control).onTintColor = [self colorFromHex:hexString withAlpha:hexAlpha];
    }

    return self;
  }

  //add method to convert hex to UIColor, notice we added this method to the cell's interface
  //StackOverFlow - https://stackoverflow.com/a/12397366
  -(UIColor *)colorFromHex:(NSString *)hex withAlpha:(CGFloat)alpha {   
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&rgbValue];

    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float)((rgbValue & 0x00FF00) >> 8)) / 255.0 blue:((float)((rgbValue & 0x0000FF) >> 0)) / 255.0 alpha:alpha];
  }
@end