/*-----------------------------------------------------------------------------
** This software is in the public domain, furnished "as is", without technical 
** support, and with no warranty, express or implied, as to its usefulness for
** any purpose.
**----------------------------------------------------------------------------*/
#import <limits.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate: NSObject <UIApplicationDelegate,
    CLLocationManagerDelegate>
{
    UIWindow *window;
    UILabel *testLabel;
    CLLocationManager *locationManager; 
    CLHeading *currentHeading;
    CLLocation *currentLocation;
}

- (void)initializeUI;
- (void)setOutput:(NSString *)fromOutput;
- (void)processOutputWithLocation:(CLLocation *)fromLocation
                          heading:(CLHeading *)fromHeading;
- (void)startStandardUpdates;
- (void)startHeadingEvents;
@end

@implementation AppDelegate

#pragma mark -
#pragma mark NSObject

- (id)init
{
    if ((self = [super init]) != nil) {
        window = nil;
        testLabel = nil;
        locationManager = nil;
    }
    return self;
}

- (void)dealloc
{
    [window release];
    [testLabel release];
    [locationManager release];
    [super dealloc];
}

#pragma mark -
#pragma mark AppDelegate

- (void)initializeUI
{
    window = [[UIWindow alloc] initWithFrame:
        CGRectOffset(
            [[UIScreen mainScreen] applicationFrame], 0,
            -[[UIApplication sharedApplication] statusBarFrame].size.height)];
    testLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [testLabel setBackgroundColor:[UIColor whiteColor]];
    [testLabel setLineBreakMode:UILineBreakModeWordWrap];
    [testLabel setNumberOfLines:0];
    [self setOutput:@"initializing..."];
    [window addSubview:testLabel];
    [window makeKeyAndVisible];
}

- (void)setOutput:(NSString *)fromOutput
{
    CGSize outputSize = 
            [fromOutput sizeWithFont:[testLabel font] constrainedToSize:
                CGSizeMake([window frame].size.width, CGFLOAT_MAX)
                lineBreakMode:[testLabel lineBreakMode]];

    [testLabel setText:fromOutput];
    [testLabel setFrame:CGRectMake(0, 0, outputSize.width, outputSize.height)];
    [testLabel setCenter:[window center]];
    [testLabel setNeedsLayout];
}

- (void)processOutputWithLocation:(CLLocation *)fromLocation
                          heading:(CLHeading *)fromHeading;
{
    NSString *output = [NSString string];

    if (fromLocation != nil) {
        [currentLocation autorelease];
        currentLocation = [fromLocation retain];
    }
    if (currentLocation != nil)
        output = [output stringByAppendingString:
                [NSString stringWithFormat:
                    @"Altitude: %f Latitude: %f Longitude: %f"
                    @" Course: %f Speed: %f",
                    [currentLocation altitude],
                    [currentLocation coordinate].latitude,
                    [currentLocation coordinate].longitude,
                    [currentLocation course],
                    [currentLocation speed]]];
    if (fromHeading != nil) {
        [currentHeading autorelease];
        currentHeading = [fromHeading retain];
    }
    if (currentHeading != nil)
        output = [output stringByAppendingString:
                [NSString stringWithFormat:@" Heading:%f",
                    [currentHeading trueHeading] > 0 ?
                        [currentHeading trueHeading] :
                        [currentHeading magneticHeading]]];
    [self setOutput:output];
}

- (void)startStandardUpdates
{
    // Create the location manager if this object does not already have one     
    if (locationManager == nil)
        locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager locationServicesEnabled]) {
        [locationManager setDelegate:self];
        [locationManager 
                setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [locationManager setDistanceFilter:kCLDistanceFilterNone];
        [locationManager startUpdatingLocation];
    }
}

- (void)startHeadingEvents
{
    // Create the location manager if this object does not already have one     
    if (locationManager == nil)
        locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager headingAvailable]) {
        locationManager.headingFilter = 2;
        [locationManager startUpdatingHeading];
    }
}

#pragma mark -
#pragma mark <UIApplicationDelegate>

- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)withOptions
{
    [self initializeUI];
    [self startStandardUpdates];
    [self startHeadingEvents];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [locationManager stopUpdatingLocation];
}

#pragma mark -
#pragma mark <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if ([newLocation horizontalAccuracy] < 0)
        return;
    if (-[[newLocation timestamp] timeIntervalSinceNow] < 5.0)
          //&& [newLocation horizontalAccuracy] <=
          //    [locationManager desiredAccuracy])
        [self processOutputWithLocation:newLocation heading:nil];
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    if ([newHeading headingAccuracy] < 0)
        return;
    if (-[[newHeading timestamp] timeIntervalSinceNow] < 1.0)
        [self processOutputWithLocation:nil heading:newHeading];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [self setOutput:[NSString stringWithFormat:@"%@", error]];
    NSLog(@"error");
}
@end
