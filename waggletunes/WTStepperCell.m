#import "WTStepperCell.h"

@implementation WTStepperCell

-(id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(NSString *)arg2 specifier:(PSSpecifier *)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];

    if (self) {

        HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:[arg3 propertyForKey:@"defaults"]];
        BOOL isDarkMode = false;
        if (@available(iOS 13, *)) {
            isDarkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        }
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.text = [NSString stringWithFormat:@"%d", (int)[preferences integerForKey:[arg3 propertyForKey:@"key"] default:5]];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        _valueLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
        _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:_valueLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_valueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_valueLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    
    return self;

}

- (void)controlChanged:(id)arg1 {
    [super controlChanged:arg1];
    _valueLabel.text = [NSString stringWithFormat:@"%d", (int)[(UIStepper *)arg1 value]];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    BOOL isDarkMode = false;
    if (@available(iOS 13, *)) {
        isDarkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    if (_valueLabel) {
        _valueLabel.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    }
}

@end