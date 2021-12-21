#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Cephei/HBPreferences.h>
#import "CCColorCube.h"
#import <AudioToolbox/AudioToolbox.h>

@interface UIWindow (WaggleTunes) //I don't know why we have to do this, but I hope it's safe, and hopefully it doesn't crash it!
-(void)_setSecure:(BOOL)arg1;
@end

@interface UIApplication (WaggleTunes) 
+(id)sharedApplication;
-(long long)activeInterfaceOrientation;
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2 ;
-(void)noteActiveInterfaceOrientationDidChangeToOrientation:(long long)arg1 willAnimateWithSettings:(id)arg2 fromOrientation:(long long)arg3 ;
@end

// @interface WTDG: UIGestureRecognizerDelegate
// @end

@interface TunesViewController: UIWindow

-(void)setWasPlaying:(BOOL)arg1;
-(BOOL)wasPlaying;

//STATIC PROPS
//OVERARCHING VIEWS
@property UIView *albumImage;
@property UIImageView *realAlbumImage;
@property UIImageView *backButton;
@property UIImageView *pauseButton;
@property UIImageView *forwardButton;
@property UIVisualEffectView *controlParentView;
// @property UIView *blurView;
@property UIView *containerView;

//MANAGEMENT FLOW BOOLS
@property bool dragging;
@property bool isPause;
@property bool isNotched;
@property bool isHorizontal;
@property bool gestSet;
@property bool isIPad;

@property bool wasPlayingBopped;

// -(void)_setSecure:(BOOL)arg1;


//INTERACTION CONTROLLER
@property UIPanGestureRecognizer *dragAlbum;

//PREF KEYS
@property NSInteger sizeKey;
@property NSInteger colorKey;
@property NSInteger positionKey;
@property NSInteger hapticKey;
@property NSInteger appearanceKey;
@property bool enableOnLockscreen;

-(int)rotation;



-(void)hideForCover:(BOOL)coverCalled immediately:(BOOL)immediate;
-(void)showForCover:(BOOL)coverCalled immediately:(BOOL)immediate;

-(void)showLyrics;
-(void)openMusic;

//INTERFACE MANAGEMENT
-(void)showImage:(UIImage *)image;
-(void)updateColors;
-(void)playHapticFeedback;
-(void)setPlayIcon:(BOOL)arg1;
-(void)hideViewFromMiddle:(bool)arg1;
-(void)showViewAndControls;
-(void)handleOrientationChange:(long long)arg1;
-(BOOL)isShowingPause;
-(BOOL)controlsShowing;
-(NSData *)image;


//MEDIA MANAGEMENT
-(void)pause;
-(void)goBack;
-(void)goForward;

//PREF MANAGEMENT
-(void)setDefaultSize:(NSInteger)sizeArg;
-(void)setDefaultColor:(NSInteger)colorArg;
-(void)setDefaultAppearance:(NSInteger)appearanceArg;
-(void)setDefaultPosition:(NSInteger)positionArg;
-(void)setDefaultEnableOnLockscreen:(bool)enableOnLockscreenArg;


//INTERACTION MANAGEMENT
-(bool)isTuckedAway;
-(int)tuckedEdge;
-(void)dragForFreelyMoving:(UIPanGestureRecognizer *)pan;
-(void)startDrag;
-(void)handleAlbumInteraction;
-(void)enableFreeMotion;
-(void)disableFreeMotion;
-(CGRect)defaultHiddenPosition;
-(CGRect)defaultShowingPosition;

//INSTANCE MANAGEMENT
+(instancetype)sharedInstance;
-(bool)wasConfig;
-(id)init;
-(void)setSharedBackGest:(UITapGestureRecognizer *)backGest pauseGest:(UITapGestureRecognizer *)pauseGest forwardGest:(UITapGestureRecognizer *)forwardGest;

@end