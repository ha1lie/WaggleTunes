#include "WTRootListController.h"
#include "WTAnimatedTitleView.h"

@implementation WTRootListController

static HBPreferences *preferences;

- (instancetype)init {
    self = [super init];

    if (self) {
        HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
        appearanceSettings.tintColor = [UIColor colorWithRed:(203.0/255.0) green:(31.0/255.0) blue:(75.0/255.0) alpha:1.0];
		appearanceSettings.tableViewCellSeparatorColor = [UIColor clearColor];
        // appearanceSettings.tableViewBackgroundColor = [UIColor colorWithWhite:242.f / 255.f alpha:1];
        self.hb_appearanceSettings = appearanceSettings;

		preferences = [[HBPreferences alloc] initWithIdentifier:@"com.halliehax.waggletunes.prefs"];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:(203.0/255.0) green:(31.0/255.0) blue:(75.0/255.0) alpha:1.0];

	if (!self.navigationItem.titleView) {
		WTAnimatedTitleView *titleView = [[WTAnimatedTitleView alloc] initWithTitle:@"WaggleTunes" minimumScrollOffsetRequired:-150];
		self.navigationItem.titleView = titleView;
	}

	
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
	//Send scroll offset updates to view
	if([self.navigationItem.titleView respondsToSelector:@selector(adjustLabelPositionToScrollOffset:)]) {
		[(WTAnimatedTitleView *)self.navigationItem.titleView adjustLabelPositionToScrollOffset:scrollView.contentOffset.y];
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)respring {
  [HBRespringController respring];
}

-(void)resetPrefs {

	if (preferences) {
		[preferences setBool:YES forKey:@"isEnabled"];
		[preferences setBool:NO forKey:@"lockscreenEnabled"];
		[preferences setBool:YES forKey:@"hideSS"];
		[preferences setInteger:0 forKey:@"positions"];
		[preferences setInteger:0 forKey:@"haptics"];
		[preferences setInteger:0 forKey:@"size"];
		[preferences setInteger:0 forKey:@"colors"];
		[preferences setInteger:0 forKey:@"appearance"];
		[preferences setInteger:5 forKey:@"verSens"];
		[preferences setInteger:5 forKey:@"horSens"];
		[preferences setInteger:0 forKey:@"lpAction"];
		[preferences setInteger:0 forKey:@"backgroundStyle"];
	} else {
		preferences = [[HBPreferences alloc] initWithIdentifier:@"com.halliehax.waggletunes.prefs"];
	}

	[self respring];

}


@end
