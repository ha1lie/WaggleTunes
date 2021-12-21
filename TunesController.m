#import "TunesController.h"

@implementation TunesViewController

static BOOL wasPlayingBopped = false;

//OVERARCHING VIEWS
static UIImageView *albumImage;
// static UIImageView *backButton;
// static UIImageView *pauseButton;
// static UIImageView *forwardButton;
static UIView *controlParentView;
static UIWindow *containerView;

//MANAGEMENT FLOW BOOLS
static BOOL dragging = false;
static BOOL isPause = true;
static BOOL isNotched = false;
static BOOL isHorizontal = false;
static BOOL gestSet = false;
static BOOL isIPad = false;

//ROTATION MANAGEMENT 
static int lastOrientation;
static BOOL canTuckTop; //These aren't always the edges they're called, but are named as such as non-key windows see them this way
static BOOL canTuckLeft;
static BOOL canTuckRight;
static BOOL canTuckBottom;

static CGFloat horizontalSensitivity = 100;
static CGFloat verticalSensitivity = 60;

//INTERACTION CONTROLLER
static UIPanGestureRecognizer *dragAlbum;

//INTERFACE CONSTANTS
static CGFloat width = 0;
static CGFloat height = 0;
static CGFloat controlsWidth = 120;
static CGFloat albumSize = 0;
static CGFloat outsetDist = 0;

//PREF KEYS
static NSInteger sizeKey;
static NSInteger colorKey;
static NSInteger positionKey;
static NSInteger hapticKey;
static NSInteger appearanceKey;
static NSInteger hSensKey;
static NSInteger vSensKey;
static NSInteger lpActionKey;
static BOOL enableOnLockscreen;
static NSInteger backKey;

static CCColorCube *colorCalc;

static BOOL hallifiedHidden = NO;

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

-(void)hideForCover:(BOOL)coverCalled immediately:(BOOL)immediate {
    if (coverCalled) {
        if (!enableOnLockscreen) {
            [UIView animateWithDuration: immediate ? 0.0 : 0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
                self.alpha = 0.0;
            } completion: ^(BOOL isFinished) {
                hallifiedHidden = YES;
            }];
        }
    } else {
        [UIView animateWithDuration:immediate ? 0.0 : 0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
            self.alpha = 0.0;
        } completion: ^(BOOL isFinished) {
            hallifiedHidden = YES;
        }];
    }
    
}

-(void)showForCover:(BOOL)coverCalled immediately:(BOOL)immediate {
    if (coverCalled) {
        if (!enableOnLockscreen) {
            [UIView animateWithDuration:immediate ? 0.0 : 0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
                self.alpha = 1.0;
            } completion: ^(BOOL isFinished) {
                hallifiedHidden = NO;
            }];
        }
    } else {
        [UIView animateWithDuration:immediate ? 0.0 : 0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
            self.alpha = 1.0;
        } completion: ^(BOOL isFinished) {
            hallifiedHidden = NO;
        }];
    }
}

//INTERFACE MANAGEMENT
-(void)showImage:(UIImage *)image { //Change the image being shown to user
    _realAlbumImage.image = image;
    if (hallifiedHidden) {
        [self showForCover:NO immediately:NO];
    }
    if ((int)colorKey == 0) {
        [self updateColors];
    }
}

-(void)updateColors {
    if (_realAlbumImage.image) {
        NSArray *imgColors = [colorCalc extractColorsFromImage:_realAlbumImage.image flags:CCOnlyDistinctColors];
        UIColor *firstColor = [UIColor blackColor];
        UIColor *secondColor = [UIColor whiteColor];
        bool invertNeeded = NO;
        if (imgColors.count >= 2) {
            firstColor = imgColors[0];
            secondColor = imgColors[1];
            const CGFloat* firstComponents = CGColorGetComponents(firstColor.CGColor);
            const CGFloat* secondComponents = CGColorGetComponents(secondColor.CGColor);
            if ((((firstComponents[0] + firstComponents[1] + firstComponents[2]) < 30) && firstComponents[0] <= 10 && firstComponents[1] <= 10 && firstComponents[2] <= 10)) {
                invertNeeded = YES;
            } else if ((((secondComponents[0] + secondComponents[1] + secondComponents[2]) < 765) && secondComponents[0] >= 245 && secondComponents[1] >= 245 && secondComponents[2] >= 245)) {
                invertNeeded = YES;
            }
        }
        [_controlParentView setBackgroundColor: backKey != 0 ? [UIColor clearColor] : invertNeeded ? secondColor : firstColor];
        [_backButton setTintColor:invertNeeded ? firstColor : secondColor];
        [_pauseButton setTintColor:invertNeeded ? firstColor : secondColor];
        [_forwardButton setTintColor:invertNeeded ? firstColor : secondColor];
    }
}

-(void)playHapticFeedback {
    if (hapticKey != 0) {
        //Haptics aree enabled!
        AudioServicesPlaySystemSound(hapticKey);
    }
}

-(void)setPlayIcon:(BOOL)arg1 {
    NSString *appendage = @"";
    if (appearanceKey == 0) {
        appendage = @".fill";
    }
    if (arg1) {
        if (@available(iOS 13, *)) { 
            _pauseButton.image = [[UIImage systemImageNamed:[NSString stringWithFormat:@"play%@", appendage]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]; 
        }
        isPause = false;
    } else {
        if (@available(iOS 13, *)) { 
            _pauseButton.image = [[UIImage systemImageNamed:[NSString stringWithFormat:@"pause%@", appendage]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]; 
        }
        isPause = true;
    }
}

-(void)hideViewFromMiddle:(bool)arg1 { //Move controls to tucked
    bool changeSelfFrame = false;
    bool changeControlFrame = false;
    CGRect contFrame = CGRectMake(0, 0, 0, 0);
    CGRect selfFrame = CGRectMake(0, 0, 0, 0);
    if (positionKey == 0) {
        //Is a top only view
        changeSelfFrame = true;
        selfFrame = [self defaultHiddenPosition];
        changeControlFrame = true;
        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
    } else {
        //Allowed to free float!
        CGFloat xPos = _containerView.frame.origin.x;
        CGFloat yPos = _containerView.frame.origin.y;

        CGFloat bottomHMax;
        CGFloat topHMax;
        
        CGFloat topVMax = isHorizontal ? horizontalSensitivity : verticalSensitivity;
        CGFloat bottomVMax = height - (isHorizontal ? horizontalSensitivity : verticalSensitivity);

        if (arg1) {
            topHMax = width / 2;
            bottomHMax = width / 2;
            if (isHorizontal) {
                yPos = _containerView.frame.origin.y + (albumSize / 2);
            } else {
                xPos = _containerView.center.x;
            }
        } else {
            topHMax = width - (isHorizontal ? verticalSensitivity : horizontalSensitivity);
            bottomHMax = isHorizontal ? verticalSensitivity : horizontalSensitivity;
        }
        
        if (yPos <= topVMax) {
            //Is at the top of the screen, wants to tuck up
            if (canTuckTop) {
                if (isNotched) {
                    CGFloat start = isIPad ? albumSize + 5 + controlsWidth : width * 0.3;
                    CGFloat possibleRange = isIPad ? width - ((albumSize + 5 + controlsWidth) * 2) : (width * 0.4) - albumSize;
                    CGFloat endX = possibleRange * (fabs(xPos) / (width - albumSize));    
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(start + endX, outsetDist - albumSize, albumSize, albumSize);
                    
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                } else {
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(xPos, outsetDist - albumSize, albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                }
            } else {
                //Isn't allowed to tuck to the top, must go to the sides
                if (xPos < width / 2 && canTuckLeft) {//Smoosh it on the left
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(outsetDist - albumSize, yPos < topVMax ? topVMax : yPos, albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                } else { //Must be able to smoosh it to the right
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(width - outsetDist, yPos < topVMax ? topVMax : yPos, albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                }
            }
        } else if (yPos >= bottomVMax) {
            //Is at the bottom of the screen
            if (canTuckBottom) {
                CGFloat start = isIPad ? albumSize + 5 + controlsWidth : 50;
                CGFloat possibleRange = isIPad ? width - ((albumSize + 5 + controlsWidth) * 2) : width - 100;
                CGFloat endX = possibleRange * (fabs(xPos) / (width - albumSize));
                changeSelfFrame = true;
                selfFrame = CGRectMake(start + endX, height - 10, albumSize, albumSize);
                if ([self controlsShowing]) {
                    changeControlFrame = true;
                    contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                }
            } else {
                //Can't tuck to the bottom, so will go to the sides
                if (xPos < width / 2 && canTuckLeft) {//Smoosh it on the left
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(10 - albumSize, height - (60 + albumSize), albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                } else { //Must be able to smoosh it to the right
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(width - 10, height - (60 + albumSize), albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                }
            }
        } else if (xPos <= bottomHMax) {
            //Should tuck to the left
            if (canTuckLeft) {
                changeSelfFrame = true;
                selfFrame = CGRectMake(10 - albumSize, yPos, albumSize, albumSize);
                if ([self controlsShowing]) {
                    changeControlFrame = true;
                    contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                }
            } else {
                //Needs to smoosh to top or bottom
                if (yPos <= (height / 2)) {
                    //Smooosh into the TOP
                    if (isNotched) {
                        CGFloat start = isIPad ? albumSize + 5 + controlsWidth : width * 0.3;
                        CGFloat possibleRange = isIPad ? width - ((albumSize + 5 + controlsWidth) * 2) : (width * 0.4) - albumSize;
                        CGFloat endX = possibleRange * (fabs(xPos) / (width - albumSize));
                        changeSelfFrame = true;
                        selfFrame = CGRectMake(start + endX, outsetDist - albumSize, albumSize, albumSize);
                        
                        if ([self controlsShowing]) {
                            changeControlFrame = true;
                            contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                        }
                    } else {
                        changeSelfFrame = true;
                        selfFrame = CGRectMake(xPos, outsetDist - albumSize, albumSize, albumSize);
                        if ([self controlsShowing]) {
                            changeControlFrame = true;
                            contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                        }
                    }
                } else {
                    //Push that sucker to the bottom!
                    CGFloat start = isIPad ? albumSize + 5 + controlsWidth : 50;
                    CGFloat possibleRange = isIPad ? width - ((albumSize + 5 + controlsWidth) * 2) : width - 100;
                    CGFloat endX = possibleRange * (fabs(xPos) / (width - albumSize));
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(start + endX, height - 10, albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                }
            }
        } else if (xPos >= topHMax) {
            //Should tuck to the RIGHT
            if (canTuckRight) {
                changeSelfFrame = true;
                selfFrame = CGRectMake(width - 10, yPos, albumSize, albumSize);
                if ([self controlsShowing]) {
                    changeControlFrame = true;
                    contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                }
            } else {
                //Needs to smoosh to top or bottom
                if (yPos <= (height / 2)) {
                    //Smooosh into the TOP
                    if (isNotched) {
                        CGFloat start = isIPad ? albumSize + 5 + controlsWidth : width * 0.3;
                        CGFloat possibleRange = isIPad ? width - ((albumSize + 5 + controlsWidth) * 2) : (width * 0.4) - albumSize;
                        CGFloat endX = possibleRange * (xPos / (width - albumSize));
                        changeSelfFrame = true;
                        selfFrame = CGRectMake(start + endX, outsetDist - albumSize, albumSize, albumSize);
                        
                        if ([self controlsShowing]) {
                            changeControlFrame = true;
                            contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                        }
                    } else {
                        changeSelfFrame = true;
                        selfFrame = CGRectMake(xPos, outsetDist - albumSize, albumSize, albumSize);
                        if ([self controlsShowing]) {
                            changeControlFrame = true;
                            contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                        }
                    }
                } else {
                    //Push that sucker to the bottom!
                    CGFloat start = isIPad ? albumSize + 5 + controlsWidth : 50;
                    CGFloat possibleRange = isIPad ? width - ((albumSize + 5 + controlsWidth) * 2) : width - (100 + albumSize);
                    CGFloat endX = possibleRange * (fabs(xPos) / (width));
                    changeSelfFrame = true;
                    selfFrame = CGRectMake(start + endX, height - 10, albumSize, albumSize);
                    if ([self controlsShowing]) {
                        changeControlFrame = true;
                        contFrame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, 0, 50);
                    }
                }
            }
        }
    }
    if (_realAlbumImage.image != nil && !hallifiedHidden) {
        [UIView animateWithDuration:0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
            if (changeSelfFrame) {
                _containerView.frame = selfFrame;
            }
            if (changeControlFrame) {
                _controlParentView.frame = contFrame;
            }
        } completion: nil];
    }
}

-(void)showViewAndControls { //Move controls to useable
    if ([self isTuckedAway]) {
        bool changeSelfFrame = false;
        bool changeControlFrame = false;
        CGRect contFrame = CGRectMake(0, 0, 0, 0);
        CGRect selfFrame = CGRectMake(0, 0, 0, 0);

        //Untuck the view and the controls
        if (positionKey == 0) {
            //Is a locked position view
            changeSelfFrame = true;
            selfFrame = [self defaultShowingPosition];
            changeControlFrame = true;
            contFrame = CGRectMake(_controlParentView.frame.origin.x, (albumSize - 50) / 2, controlsWidth, 50);
        } else {
            int tuckedEdge = [self tuckedEdge];
            if (tuckedEdge == 1) { //Portrait
                changeSelfFrame = true;
                selfFrame = CGRectMake(_containerView.frame.origin.x - ((albumSize + 5 + controlsWidth) / 2), 40, (albumSize + 5 + controlsWidth), albumSize);
                selfFrame = CGRectMake(isHorizontal ? _containerView.frame.origin.x : _containerView.frame.origin.x - ((albumSize + 5 + controlsWidth) / 2), !canTuckRight ? (45 + albumSize + controlsWidth) : 40, (albumSize + 5 + controlsWidth), albumSize);
                changeControlFrame = true;
                contFrame = CGRectMake(_controlParentView.frame.origin.x, (albumSize - 50) / 2, controlsWidth, 50);
            } else if (tuckedEdge == 2) { //Bottom
                changeSelfFrame = true;
                selfFrame = CGRectMake(isHorizontal ? _containerView.frame.origin.x : _containerView.frame.origin.x - ((albumSize + 5 + controlsWidth) / 2), !canTuckLeft ? height - (45 + albumSize + controlsWidth) : height - (40 + albumSize), (albumSize + 5 + controlsWidth), albumSize);
                changeControlFrame = true;
                contFrame = CGRectMake(_controlParentView.frame.origin.x, (albumSize - 50) / 2, controlsWidth, 50);
            } else if (tuckedEdge == 3) { //Left
                changeSelfFrame = true;
                selfFrame = CGRectMake(10, _containerView.frame.origin.y, albumSize + 5 + controlsWidth, albumSize);
                changeControlFrame = true;
                contFrame = CGRectMake(_controlParentView.frame.origin.x, (albumSize - 50) / 2, controlsWidth, 50);
            } else if (tuckedEdge == 4) { //Right
                if (isHorizontal) {
                    changeSelfFrame = true;
                    selfFrame = CGRectMake((width - ( albumSize + (isIPad ? 40 : 10))), _containerView.frame.origin.y, albumSize + 5 + controlsWidth, albumSize);
                } else {
                    changeSelfFrame = true;
                    selfFrame = CGRectMake((width - (albumSize + 15 + controlsWidth)), _containerView.frame.origin.y, albumSize + 5 + controlsWidth, albumSize);
                }
                
                changeControlFrame = true;
                contFrame = CGRectMake(_controlParentView.frame.origin.x, (albumSize - 50) / 2, controlsWidth, 50);
            }
        }
        
        [UIView animateWithDuration:0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
            if (changeSelfFrame) {
                _containerView.frame = selfFrame;
            }
            if (changeControlFrame) {
                _controlParentView.frame = contFrame;
            }
        } completion: nil];
    }   
}

-(void)handleOrientationChange:(long long)arg1 {
    int orientation = (int)arg1;
    BOOL shouldRotate = NO;
    CGFloat oAngle = 0;
    //NEED TO CHECK IF THE OPEN APP IS ALLOWED TO ORIENTATE
    
    if (orientation == 1) { //Portrait
        shouldRotate = YES;
        oAngle = 0;
        isHorizontal = false;
        canTuckRight = true;
        canTuckLeft = true;
        canTuckTop = true;
        canTuckBottom = false;
    } else if (orientation == 2) { //Upside down
        shouldRotate = YES;
        oAngle = 180;
        isHorizontal = false;
        canTuckRight = true;
        canTuckLeft = true;
        canTuckTop = false;
        canTuckBottom = true;
    } else if (orientation == 3) {
        shouldRotate = YES;
        oAngle = 90;
        isHorizontal = true;
        canTuckRight = true;
        canTuckLeft = false;
        canTuckTop = true;
        canTuckBottom = true;
    } else if (orientation == 4) {
        shouldRotate = YES;
        oAngle = -90;
        isHorizontal = true;
        canTuckRight = false;
        canTuckLeft = true;
        canTuckTop = true;
        canTuckBottom = true;
    }
    
    if (shouldRotate) {
        [UIView animateWithDuration:0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
            _albumImage.transform = CGAffineTransformMakeRotation(DEGREES_RADIANS(oAngle));
        } completion: nil];
        [self hideViewFromMiddle:true];
        lastOrientation = orientation;
    }
}

-(BOOL)isShowingPause {
    return isPause;
}

-(BOOL)controlsShowing {
    CGFloat wid = round(_controlParentView.frame.size.width);
    return wid != 0; //The rects are equal if the controls are hidden, invert to return if showing
}

-(NSData *)image {
    return UIImagePNGRepresentation(_realAlbumImage.image);
}

-(int)rotation {
    return (int)[[UIApplication sharedApplication] activeInterfaceOrientation];
}



//MEDIA MANAGEMENT
-(void)pause {
    [self playHapticFeedback];
    if (isPause) {
        [self setPlayIcon:true];
        isPause = false;
    } else {
        [self setPlayIcon:false];
        isPause = true;
    }
    [UIView animateWithDuration:0.15 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
        self.pauseButton.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations: ^{
            self.pauseButton.alpha = 1.0;
        } completion: nil];
    }];
}

-(void)goBack {
    [self playHapticFeedback];
    [UIView animateWithDuration:0.15 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
        self.backButton.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations: ^{
            self.backButton.alpha = 1.0;
        } completion: nil];
    }];
}

-(void)goForward {
    [self playHapticFeedback];
    [UIView animateWithDuration:0.15 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
        self.forwardButton.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations: ^{
            self.forwardButton.alpha = 1.0;
        } completion: nil];
    }];
}



//PREF MANAGEMENT
-(void)setDefaultSize:(NSInteger)sizeArg {
    albumSize = 50 + (10 * sizeArg);
    CGFloat diff = (50 + (10 * sizeKey)) - albumSize;
    [UIView animateWithDuration:0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
        _albumImage.frame = CGRectMake(0, 0, albumSize, albumSize);
        _realAlbumImage.frame = CGRectMake(0, 0, albumSize, albumSize);
        _controlParentView.frame = CGRectMake(albumSize + 5, (albumSize - 50) / 2, [self isTuckedAway] ? 0 : controlsWidth, 50);
        
        if (positionKey == 0) {
            if ([self isTuckedAway]) {
                _containerView.frame = [self defaultHiddenPosition];
            } else {
                _containerView.frame = [self defaultShowingPosition];
            }
        } else {
            if ([self isTuckedAway]) {
                if (_containerView.frame.origin.x < 0) {
                    _containerView.frame = CGRectMake(_containerView.frame.origin.x + diff, _containerView.frame.origin.y, _containerView.frame.size.width, _containerView.frame.size.height);
                } else if (_containerView.frame.origin.y < 0) { 
                    _containerView.frame = CGRectMake(_containerView.frame.origin.x, _containerView.frame.origin.y + diff, _containerView.frame.size.width, _containerView.frame.size.height);
                }
            }
        }
    } completion: nil];
    sizeKey = sizeArg;
}

-(void)setDefaultColor:(NSInteger)colorArg {
    // UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    // UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    if (colorArg == 0) { //Says to use the album colors
        [self updateColors];
    } else {
        BOOL isDarkMode = false;
        if (@available(iOS 13, *)) {
            isDarkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        }
        UIColor *myControlColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        [_controlParentView setBackgroundColor: backKey != 0 ? [UIColor clearColor] : isDarkMode ? [UIColor blackColor] : [UIColor whiteColor]];
        [_backButton setTintColor:myControlColor];
        [_pauseButton setTintColor:myControlColor];
        [_forwardButton setTintColor:myControlColor];

    }
    colorKey = colorArg;
}

-(void)setDefaultAppearance:(NSInteger)appearanceArg {
    NSString *pauseKey = @"";
    if ([self isShowingPause]) { pauseKey = @"pause"; } else { pauseKey = @"play"; }
    NSString *appendage = @"";
    if (appearanceArg == 0) {
        appendage = @".fill";
    }
    if (@available(iOS 13, *)) {
        _pauseButton.image = [[UIImage systemImageNamed:[NSString stringWithFormat:@"%@%@", pauseKey, appendage]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _backButton.image = [[UIImage systemImageNamed:[NSString stringWithFormat:@"backward%@", appendage]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _forwardButton.image = [[UIImage systemImageNamed:[NSString stringWithFormat:@"forward%@", appendage]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    appearanceKey = appearanceArg;
}

-(void)setDefaultPosition:(NSInteger)positionArg { 
    if (positionArg == 0) {
        CGRect updateTo;
        if ([self isTuckedAway]) {
            updateTo = [self defaultHiddenPosition];
        } else {
            updateTo = [self defaultShowingPosition];
        }
        [UIView animateWithDuration:0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations: ^{
            _containerView.frame = updateTo;
        } completion: nil];
        [self disableFreeMotion];
    } else {
        [self enableFreeMotion];
    }
    positionKey = positionArg;
}

-(void)setDefaultEnableOnLockscreen:(bool)enableOnLockscreenArg {
    if (!enableOnLockscreenArg) {
        [self _setSecure:NO];
    } else {
        [self _setSecure:YES];
    }
    enableOnLockscreen = enableOnLockscreenArg;
}

-(void)setVerticalSensitivity:(NSInteger)vSens {
    verticalSensitivity = (height / 5) * ((CGFloat)vSens / 10);
    vSensKey = vSens;
}

-(void)setHorizontalSensitivity:(NSInteger)hSens {
    horizontalSensitivity = (width / 4) * ((CGFloat)hSens / 10);    
    hSensKey = hSens;
}

-(void)setLpActionKey:(NSInteger)lpaKey {
    lpActionKey = lpaKey;
}

-(void)setBackKey:(NSInteger)hihi {
    backKey = hihi;
    if (@available(iOS 13, *)) {
        _controlParentView.effect = hihi == 1 ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial] : nil;
    }
    [self setDefaultColor:colorKey];
}

//INTERACTION MANAGEMENT
-(bool)isTuckedAway { //Check location of controller
    CGFloat yPos = round(_containerView.frame.origin.y);
    CGFloat xPos = round(_containerView.frame.origin.x);
    BOOL isTucked = false;
    if (yPos == (outsetDist - albumSize)) {
        isTucked = true;
    } else if (yPos == (height - 10)) {
        isTucked = true;
    } else if (xPos == (10 - albumSize)) {
        isTucked = true;
    } else if (xPos == (width - 10)) {
        isTucked = true;
    }
    return isTucked;
}

-(int)tuckedEdge { //Top-1 Bottom-2 Left-3 Right-4
    CGFloat yPos = round(_containerView.frame.origin.y);
    CGFloat xPos = round(_containerView.frame.origin.x);
    int edge = 0;
    if (yPos == (outsetDist - albumSize)) {
        edge = 1;
    } else if (yPos == (height - 10)) {
        edge = 2;
    } else if (xPos == (10 - albumSize)) {
        edge = 3;
    } else if (xPos == (width - 10)) {
        edge = 4;
    }
    return edge;
}

-(void)dragForFreelyMoving:(UIPanGestureRecognizer *)pan {
    CGPoint location = [pan locationInView:self];
    CGFloat offSet = albumSize / 2;
    _containerView.frame = CGRectMake(location.x - offSet, location.y - offSet, _containerView.frame.size.width, _containerView.frame.size.height);

    if (pan.state == UIGestureRecognizerStateEnded) {
        //The drag ended, check if the view needs to be tucked or left where it is!
        dragging = false;
        //check and hide if needed
        CGFloat xPos = _containerView.frame.origin.x;
        CGFloat yPos = _containerView.frame.origin.y;

        CGFloat bottomHMax;
        CGFloat topHMax;
        
        CGFloat topVMax = 100;
        CGFloat bottomVMax = height - 150;

        bool doHalf = (yPos > bottomVMax);

        if (doHalf) {
            topHMax = width / 2;
            bottomHMax = width / 2;
        } else {
            topHMax = width - (40 + (albumSize / 2));
            bottomHMax = 40;
        }

        if ((yPos <= topVMax) || (xPos <= bottomHMax) || (xPos >= topHMax)) {
            [self hideViewFromMiddle:false];
        }
    } else if (pan.state == UIGestureRecognizerStateBegan) {
        dragging = true;
        [self startDrag];
    }
}

-(void)startDrag {
    if (![self controlsShowing]) {
        //Show the controls because we just started dragging from the tucked view
        [UIView animateWithDuration:0.4 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
            _controlParentView.frame = CGRectMake(_controlParentView.frame.origin.x, _controlParentView.frame.origin.y, controlsWidth, _controlParentView.frame.size.height);
        } completion: nil];
    }
}

-(void)handleAlbumInteraction {
    if (![self isTuckedAway]) {
        [self hideViewFromMiddle:(positionKey == 1)];
    } else {
        [self showViewAndControls];
    }
}

-(void)enableFreeMotion {
    //Go ahead and give the pan gest rec
    dragAlbum = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragForFreelyMoving:)];
    [_albumImage addGestureRecognizer:dragAlbum];
}

-(void)disableFreeMotion {
    //Remove the pan gest rec
    [_albumImage removeGestureRecognizer:dragAlbum];
}

-(CGRect)defaultHiddenPosition {
    int ornt = [self rotation];
    if ( !isIPad && isNotched) { //Is notched phone
        return CGRectMake((width / 2) - (albumSize / 2), 40 - albumSize, albumSize, albumSize);
    } else { //Is iPad or early iPhone
        if (ornt == 1) { //Portrait
            return CGRectMake(width - 10, 40, albumSize, albumSize);
        } else if (ornt == 2) { //Upside down
            return CGRectMake(10 - albumSize, height - (albumSize + 40), albumSize, albumSize);
        } else if (ornt == 3) { //left
            return CGRectMake(width - (albumSize + 40), height - 10, albumSize, albumSize);
        } else { //Right
            return CGRectMake(40, 10 - albumSize, albumSize, albumSize);
        }
    }
}

-(CGRect)defaultShowingPosition {
    int ornt = [self rotation];
    if ( !isIPad && isNotched) { //Is notched phone
        if (!isHorizontal) {
            return CGRectMake((width / 2) - ((albumSize + 5 + controlsWidth) / 2), 40, (albumSize + 5 + controlsWidth), albumSize);
        } else {
            if (ornt == 3) { //Left
                return CGRectMake((width / 2) - (albumSize / 2), 40, (albumSize + 5 + controlsWidth), albumSize);
            } else { //Must be right
                return CGRectMake((width / 2) - (albumSize / 2), 45 + controlsWidth, (albumSize + 5 + controlsWidth), albumSize);
            }
        }
    } else { //Is iPad or early iPhone
        if (ornt == 1) { //Portrait
            return CGRectMake(width - (albumSize + 15 + controlsWidth), 40, (albumSize + 5 + controlsWidth), albumSize);
        } else if (ornt == 2) { //Upside down
            return CGRectMake(15 + controlsWidth, height - (albumSize + 40), (albumSize + 5 + controlsWidth), albumSize);
        } else if (ornt == 3) { //left
            return CGRectMake(width - (albumSize + 40), height - (albumSize + 15 + controlsWidth), (albumSize + 5 + controlsWidth), albumSize);
        } else { //Right
            return CGRectMake(40, 15 + controlsWidth, (albumSize + 5 + controlsWidth), albumSize);
        }
    }
}

-(void)setWasPlaying:(BOOL)arg1 {
    wasPlayingBopped = arg1;
}
-(BOOL)wasPlaying {
    return wasPlayingBopped;
}


//INSTANCE MANAGEMENT
+(instancetype)sharedInstance {
    static TunesViewController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[TunesViewController alloc] init];
    });
    return sharedController;
}

-(bool)wasConfig {
    return gestSet;
}

-(id)init {

    width = [UIScreen mainScreen].bounds.size.width;
    height = [[UIScreen mainScreen] bounds].size.height;

    HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:@"com.halliehax.waggletunes.prefs"];

	[preferences registerInteger:&hapticKey default:0 forKey:@"haptics"]; //BTW if you're curious this is how the haptics are handled without a function. Can show logic if interested! 

	enableOnLockscreen = [preferences boolForKey:@"lockscreenEnabled" default:0];
	colorKey = [preferences integerForKey:@"colors" default:0];
	sizeKey = [preferences integerForKey:@"size" default:0];
	positionKey = [preferences integerForKey:@"positions" default:0];
	hapticKey = [preferences integerForKey:@"haptics" default:0];
	appearanceKey = [preferences integerForKey:@"appearance" default:0];
    [self setHorizontalSensitivity:[preferences integerForKey:@"horSens" default:5]];
    [self setVerticalSensitivity:[preferences integerForKey:@"verSens" default:5]];
    lpActionKey = [preferences integerForKey:@"lpAction" default:0];
    backKey = [preferences integerForKey:@"backgroundStyle" default:0];

    colorCalc = [[CCColorCube alloc] init];

	[preferences registerPreferenceChangeBlock: ^{

		NSInteger tmpcolor = [preferences integerForKey:@"colors" default:0];
		NSInteger tmpsize = [preferences integerForKey:@"size" default:0];
		NSInteger tmpposition = [preferences integerForKey:@"positions" default:0];
		NSInteger tmpappearance = [preferences integerForKey:@"appearance" default:0];
        bool tmpEnableOnLockscreen = [preferences boolForKey:@"lockscreenEnabled" default:NO];
        NSInteger tmpvsenskey = [preferences integerForKey:@"verSens" default:0];
        NSInteger tmphsenskey = [preferences integerForKey:@"horSens" default:0];
        NSInteger tmplpActionKey = [preferences integerForKey:@"lpAction" default:0];
        NSInteger tmpBackKey = [preferences integerForKey:@"backgroundStyle" default:0];

		if (colorKey != tmpcolor) {
			[self setDefaultColor:tmpcolor];
		} 

        if (enableOnLockscreen != tmpEnableOnLockscreen) {
            [self setDefaultEnableOnLockscreen:tmpEnableOnLockscreen];
        }
		
		if (sizeKey != tmpsize) {
			[self setDefaultSize:tmpsize];
		} 
		
		if (positionKey != tmpposition) {
			[self setDefaultPosition:tmpposition]; //We'll fix that before I question why it's not working!
		} 
		
		if (appearanceKey != tmpappearance) {
			[self setDefaultAppearance:tmpappearance];
		}

        if (vSensKey != tmpvsenskey) {
            [self setVerticalSensitivity:tmpvsenskey];
        }
        if (hSensKey != tmphsenskey) {
            [self setHorizontalSensitivity:tmphsenskey];
        }

        if (lpActionKey != tmplpActionKey) {
            [self setLpActionKey:tmplpActionKey];
        }

        if (backKey != tmpBackKey) {
            [self setBackKey:tmpBackKey];
        }
	}];

    isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    if (!isIPad) { //Is not an iPad
        outsetDist = 40;
    } else {
        //IS on an iPad
        outsetDist = 10;
    }

    isNotched = false;
    if (!isIPad) {
        int h = (int)[UIScreen mainScreen].nativeBounds.size.height;
        isNotched = (h == 2436) || (h == 2688) || (h == 1792) || (h == 2340) || (h == 2532) || (h == 2778);
    }

    albumSize = 50 + (sizeKey * 10);
    
    lastOrientation = [[UIDevice currentDevice] orientation];
    if (lastOrientation == 3 || lastOrientation == 4) {
        isHorizontal = true;
        if (lastOrientation == 3) {
            //Notched left
            canTuckRight = true;
            canTuckLeft = false;
            canTuckBottom = true;
            canTuckTop = true;
        } else { //Has  to be 4
            canTuckRight = false;
            canTuckLeft = true;
            canTuckBottom = true;
            canTuckTop = true;
        }
    } else {
        isHorizontal = false;
        if (lastOrientation == 1) {
            //Portrait
            canTuckRight = true;
            canTuckLeft = true;
            canTuckBottom = false;
            canTuckTop = true;
        } else { //Has  to be 2
            canTuckRight = true;
            canTuckLeft = true;
            canTuckBottom = true;
            canTuckTop = false;
        }
    }

    if (width > height) {
        CGFloat tmpHeight = height;
        height = width;
        width = tmpHeight;
    }
    self = [super initWithFrame:CGRectMake(0, 0, width, height)];
    // self.frame = CGRectMake(0, 0, width, height);
    if (self) { 
        self.windowLevel = UIWindowLevelStatusBar + 1000;
        self.clipsToBounds = NO;
        self.userInteractionEnabled = YES;
        self.opaque = NO;
        if (enableOnLockscreen) {
            [self _setSecure:YES];
        }
        [self makeKeyAndVisible];

        _containerView = [[UIView alloc] initWithFrame:[self defaultHiddenPosition]];
        _containerView.frame = [self defaultHiddenPosition];
        _containerView.userInteractionEnabled = YES;

        _albumImage = [[UIView alloc] initWithFrame:CGRectMake(0, 0, albumSize, albumSize)];
        _albumImage.clipsToBounds = NO;
        _albumImage.layer.cornerRadius = 6;
        _albumImage.userInteractionEnabled = YES;

        _realAlbumImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, albumSize, albumSize)];
        _realAlbumImage.clipsToBounds = YES;
        _realAlbumImage.layer.cornerRadius = 6;
        _realAlbumImage.userInteractionEnabled = YES;

        if (@available(iOS 13, *)) {
            UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
            _controlParentView = [[UIVisualEffectView alloc] initWithEffect:backKey == 1 ? effect : nil];
            _controlParentView.frame = CGRectMake((albumSize + 5), (albumSize - 50) / 2, 0, 50);
            _controlParentView.clipsToBounds = YES;
            _controlParentView.layer.cornerRadius = 6;
            _controlParentView.userInteractionEnabled = YES;
        }
        [self addSubview:_containerView];
        [_containerView addSubview:_albumImage];
        [_albumImage addSubview:_realAlbumImage];
        if (_controlParentView) {
            [_albumImage addSubview:_controlParentView];
        }
        UIColor *controlColor = [UIColor blackColor];

        _backButton = [[UIImageView alloc] initWithFrame:CGRectMake(10, 12.5, (controlsWidth / 3) - 10, 25)];
        _backButton.clipsToBounds = YES;
        _backButton.tintColor = controlColor;
        _backButton.layer.cornerRadius = 6;
        _backButton.userInteractionEnabled = YES;
        [_controlParentView.contentView addSubview:_backButton];

        _pauseButton = [[UIImageView alloc] initWithFrame:CGRectMake((controlsWidth / 3) + 10, 12.5, (controlsWidth / 3) - 20, 25)];
        _pauseButton.clipsToBounds = YES;
        _pauseButton.tintColor = controlColor;
        _pauseButton.layer.cornerRadius = 6;
        _pauseButton.userInteractionEnabled = YES;
        [_controlParentView.contentView addSubview:_pauseButton];

        _forwardButton = [[UIImageView alloc] initWithFrame:CGRectMake(((controlsWidth / 3) * 2), 12.5, (controlsWidth / 3) - 10, 25)];
        _forwardButton.clipsToBounds = YES;
        _forwardButton.tintColor = controlColor;
        _forwardButton.layer.cornerRadius = 6;
        _forwardButton.userInteractionEnabled = YES;
        [_controlParentView.contentView addSubview:_forwardButton];
        [self setDefaultAppearance:appearanceKey];

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAlbumInteraction)];
        singleTap.numberOfTapsRequired = 1; 
        [_albumImage addGestureRecognizer:singleTap];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [_albumImage addGestureRecognizer:longPress];

        if ((int)positionKey == 1) {
            //Allowing the view to be moved freely
            [self enableFreeMotion];    
        }
    }
    [self setDefaultColor:colorKey];
    return self;
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)lngprs {
    //Do logic to figure out what long press should do
    if ((int)lngprs.state == (int)1) {
        //Do stuff to do whatever
        if (lpActionKey == 1) {
            [self showLyrics];
        } else if (lpActionKey == 2) {
            [self openMusic];
        }
	}
}

-(void)showLyrics {
    //Do logic to ensure that the user has a lyric presenter installed!
}

-(void)openMusic {
}

-(void)setSharedBackGest:(UITapGestureRecognizer *)backGest pauseGest:(UITapGestureRecognizer *)pauseGest forwardGest:(UITapGestureRecognizer *)forwardGest {
    [_backButton addGestureRecognizer:backGest];
    [_pauseButton addGestureRecognizer:pauseGest];
    [_forwardButton addGestureRecognizer:forwardGest];
    gestSet = true;
}

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (hallifiedHidden) {
        return nil;
    }
    id hitView = [super hitTest:point withEvent:event];
    if (hitView != self) {
        for (UIView *subview in self.subviews.reverseObjectEnumerator) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if (result == _containerView) {
                UIView *albumThingy = result.subviews[0];
                UIView *cpv = albumThingy.subviews[0];
                if (cpv == _realAlbumImage) {
                    cpv = albumThingy.subviews[1];
                }
                CGPoint mappedPoint = [cpv convertPoint:subPoint fromView:result];
                UIView *possibleView = [cpv hitTest:mappedPoint withEvent:event];
                if (possibleView) {
                    if (possibleView.subviews.count != 3) {
                        return possibleView;
                    }
                }
            }
        }
        return hitView;
    } else {
        CGPoint mappedPoint = [_controlParentView convertPoint:point fromView:self];
        UIView *possibleView = [_controlParentView hitTest:mappedPoint withEvent:event];
        if (!possibleView) {
            return nil;
        }
        return possibleView;
    }
    return nil;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self setDefaultColor:colorKey];
}

@end