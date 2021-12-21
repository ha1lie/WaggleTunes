//WaggleTunes by HallieHax
//Tweak.xm

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import <CoreFoundation/CoreFoundation.h>
#include <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#import <MediaRemote/MediaRemote.h>
#import <Cephei/HBRespringController.h>
#import <AudioToolbox/AudioToolbox.h>
#include <dlfcn.h>
#import "TunesController.h"

// OBJC_EXTERN CFStringRef MGCopyAnswer(CFStringRef key) WEAK_IMPORT_ATTRIBUTE;

typedef CFStringRef (*mg_copy_answer)(CFStringRef);

@interface SpringBoard: UIApplication
@property TunesViewController *tunesController;
@property NSString *nowPlayingSong;
-(void)showController;
-(void)goBack:(UITapGestureRecognizer *)rec;
-(void)pause:(UITapGestureRecognizer *)rec;
-(void)goForward:(UITapGestureRecognizer *)rec;
-(void)takeScreenshot;
@end

@interface MRNowPlayingState: NSObject
-(BOOL)isPlaying;
-(NSDictionary *)nowPlayingInfo; 
@end

@interface CSCoverSheetViewController: UIViewController
-(void)viewDidAppear:(BOOL)arg1;
-(void)viewDidDisappear:(BOOL)arg1;
@end

@interface LXScrollingLyricsViewControllerPresenter: NSObject
-(void)present;
@end

@interface SBApplicationController: NSObject
-(id)_appInfosToBundleIDs:(id)arg1;
@end


@interface SBApplication: NSObject 
@property NSString *bundleIdentifier;
// -(SBApplicationInfo *)info;
-(NSString *)displayName;
@end

@interface SBMediaController
+(id)sharedInstance;
-(SBApplication *)nowPlayingApplication;
@end

%group universal
%hook SpringBoard

static TunesViewController *tunesController = nil;
static NSString *nowPlayingSong = @"";

-(void)takeScreenshot {
	HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:@"com.halliehax.waggletunes.prefs"];
	if ([preferences boolForKey:@"hideSS" default:YES]) {
		if (tunesController != nil) {
			[tunesController hideForCover:NO immediately:YES];
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				%orig;
				[tunesController showForCover:NO immediately:YES];
			});
		} else {
			%orig;
		}
	} else {
		%orig;
	}
}

-(void)applicationDidFinishLaunching:(id)arg1 { //Handles initiating the listener for our tweak
	%orig(arg1);
    HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:@"com.halliehax.waggletunes.prefs"];
    if ([preferences boolForKey:@"isEnabled" default:YES]) {
        [[NSNotificationCenter defaultCenter] addObserverForName:@"kMRMediaRemoteNowPlayingInfoDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification *note) {
            [self showController];
        }];
    }
	[self showController];
}

%new
-(void)showController {
	if (tunesController != nil) {
		MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
            NSDictionary *infoDict = (__bridge NSDictionary*)information;
            NSString *song = [infoDict objectForKey:@"kMRMediaRemoteNowPlayingInfoTitle"];
            NSData *imageData = [infoDict objectForKey:@"kMRMediaRemoteNowPlayingInfoArtworkData"];
			float pbrate = [[infoDict objectForKey:@"kMRMediaRemoteNowPlayingInfoPlaybackRate"] floatValue];
			if (!infoDict) { //Hide if now pid is gone
				[tunesController hideForCover:NO immediately:NO];
				[tunesController setWasPlaying:NO];
			} else {
				[tunesController setWasPlaying:YES];
			}
			if (song != nil) {
				if (pbrate > 0.0 && ![tunesController isShowingPause]) {
					[tunesController setPlayIcon:false];
				} else if (pbrate == 0.0 && [tunesController isShowingPause]) {
					[tunesController setPlayIcon:true];
				}
				UIImage *image = [UIImage imageWithData:imageData];
				[tunesController showImage:image];
				nowPlayingSong = song;
			} else {
				// [tunesController hide];
				tunesController = nil;
			}
        });
	} else {
		//Doesn't exist, please show one!
		dispatch_async(dispatch_get_main_queue(), ^{
			tunesController = [TunesViewController sharedInstance];
			if (![tunesController wasConfig]) {
				UITapGestureRecognizer *backGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goBack:)];
				UITapGestureRecognizer *pauseGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pause:)];
				UITapGestureRecognizer *forwardGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goForward:)];
				[tunesController setSharedBackGest:backGest pauseGest:pauseGest forwardGest:forwardGest];
			}
			[self showController];
		});
	}
}

%new
-(void)goBack:(UITapGestureRecognizer *)rec {
	MRMediaRemoteSendCommand(MRMediaRemoteCommandPreviousTrack, nil);
	[tunesController goBack];
}

%new
-(void)pause:(UITapGestureRecognizer *)rec {
	MRMediaRemoteSendCommand(MRMediaRemoteCommandTogglePlayPause, nil);
	[tunesController pause];
}

%new
-(void)goForward:(UITapGestureRecognizer *)rec {
	MRMediaRemoteSendCommand(MRMediaRemoteCommandNextTrack, nil);
	[tunesController goForward];
}

%end

%hook UIApplication

-(void)noteActiveInterfaceOrientationDidChangeToOrientation:(long long)arg1 willAnimateWithSettings:(id)arg2 fromOrientation:(long long)arg3 {
	if ([self isEqual:[UIApplication sharedApplication]]) {
		[[TunesViewController sharedInstance] handleOrientationChange:arg1];
	}
	%orig;
}

%end

%hook CSCoverSheetViewController
-(void)viewDidAppear:(BOOL)arg1  {
	%orig(arg1);
	TunesViewController *tvc = [TunesViewController sharedInstance];
	if (tvc != nil) {
		[tvc hideForCover:YES immediately:NO];
	}
}
-(void)viewDidDisappear:(BOOL)arg1  {
	%orig(arg1);
	TunesViewController *tvc = [TunesViewController sharedInstance];
	if (tvc != nil) {
		if ([tvc wasPlaying]) {
			[tvc showForCover:YES immediately:NO];
		}
	}

}
%end


%hook TunesViewController

-(void)showLyrics {
	%orig; ///Library/MobileSubstrate/DynamicLibraries/LyricationFloatingOverlay.dylib
	if (dlopen("/Library/MobileSubstrate/DynamicLibraries/LyricationFloatingOverlay.dylib", RTLD_LAZY)) {
		LXScrollingLyricsViewControllerPresenter *lyrics = [[%c(LXScrollingLyricsViewControllerPresenter) alloc] init];
		if (lyrics) {
			[lyrics present];
		}
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh oh!" message:@"You don't have Lyrication by Marcel Braun installed! It's a great tweak, and works well with WaggleTunes! Please install it from repo.basepack.co" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
	
}

-(void)openMusic {
	%orig;
	NSString *musicID = [[%c(SBMediaController) sharedInstance] nowPlayingApplication].bundleIdentifier;
	[[UIApplication sharedApplication] launchApplicationWithIdentifier:musicID suspended:NO];

}

%end

%end //END OF UNIVERSAL


%group unsupportedIOS
%hook SpringBoard
-(void)applicationDidFinishLaunching:(BOOL)arg1 {
	%orig(arg1);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks for installing WaggleTunes!" message:@"Unfortunately, this version does not work on iOS versions lower than 13.0! Sorry for the confusion, and please request a refund containing information about your iOS version." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}
%end
%end //END OF TOO LOW


// Group "bh" was used to respring the device to make sure the file could be written in time
// Group "ol" was used to respring message if offline
//Group tgp was an unapproved and not allowed service download(pirated)

//universal - Success
//unsupportedIOS - Failure

%ctor {
	if (@available(iOS 13.0, *)) {
		%init(universal);
	} else {
		%init(unsupportedIOS);
	}
}
