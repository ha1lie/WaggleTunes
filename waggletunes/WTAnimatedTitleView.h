#import <UIKit/UIKit.h>

@interface WTAnimatedTitleView : UIView
-(instancetype)initWithTitle:(NSString *)title minimumScrollOffsetRequired:(CGFloat)minimumOffset;
-(void)adjustLabelPositionToScrollOffset:(CGFloat)offset;
@end