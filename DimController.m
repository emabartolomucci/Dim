#import "DimController.h"

const CGFloat MAX_ALPHA = 0.9; //So the user can see their screen, even at max darkness

//DimController handles changes in brightness and enabled-ness. It updates the settings if needed when those change.
@implementation DimController
+ (DimController*)sharedInstance {
	static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
	if (self = [super init]) {
		prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.dim"];
		[prefs registerDefaults:@{
			@"enabled": @NO,
			@"alpha": [NSNumber numberWithFloat:0.3],
			@"alphaInterval": [NSNumber numberWithFloat:0.1]
		}];
		[prefs setBool:NO forKey:@"enabled"]; //Default to disabled when SpringBoard starts, regardless of the previous setting

		_prefsChangedFromSettings = NO;
		_enabled = NO;
		_brightness = [prefs floatForKey:@"alpha"];
		_alphaInterval = [prefs floatForKey:@"alphaInterval"];
	}
	return self;
}

- (void)updateSettings {
	[self setEnabled:[prefs boolForKey:@"enabled"]];
	[self setBrightness:(1 - [prefs floatForKey:@"alpha"])];
	_alphaInterval = [prefs floatForKey:@"alphaInterval"];
	_prefsChangedFromSettings = NO;
}

- (void)setEnabled:(BOOL)enabled {
	if (enabled == _enabled)
		return;

	_enabled = enabled;
	if (!enabled && dimOverlay)
		[dimOverlay release];
	else if (enabled) {
		dimOverlay = [[DimWindow alloc] init];
		dimOverlay.windowLevel = 1000001; //Beat that ryan petrich
	    dimOverlay.alpha = _brightness;
	    dimOverlay.hidden = NO;
	}

	if (!_prefsChangedFromSettings)
		[prefs setBool:_enabled forKey:@"enabled"];
}

- (void)setBrightness:(CGFloat)brightness {
	//Ensures the brighntess is between 0 and MAX_ALPHA
	CGFloat newBrightness = fmax(brightness, 0.0);
	newBrightness = fmin(newBrightness, MAX_ALPHA);
	_brightness = newBrightness;

	if (_enabled)
		dimOverlay.alpha = newBrightness;

	if (!_prefsChangedFromSettings)
		[prefs setFloat:(1 - _brightness) forKey:@"alpha"];
}

@end