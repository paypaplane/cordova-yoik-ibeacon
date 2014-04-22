/*
The MIT License (MIT)

Copyright (c) 2014 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

#import "YoikIBeacon.h"
#import <Cordova/CDVJSON.h>


#pragma mark Constants

// #define kPGLocationErrorDomain @"kPGLocationErrorDomain"
// #define kPGLocationDesiredAccuracyKey @"desiredAccuracy"
// #define kPGLocationForcePromptKey @"forcePrompt"
// #define kPGLocationDistanceFilterKey @"distanceFilter"
// #define kPGLocationFrequencyKey @"frequency"


#pragma mark -
#pragma mark YoikIBeaconData

@implementation YoikIBeaconData

@synthesize uuid, major, minor, identifier;
- (YoikIBeaconData*)init
{
    self = (YoikIBeaconData*)[super init];
    if (self) {
        self.uuid = nil;
        self.major = nil;
        self.minor = nil;
        self.identifier = nil;
    }
    return self;
}

@end

#pragma mark -
#pragma mark YoikIBeacon

@implementation YoikIBeacon

@synthesize locationManager, beaconData;

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
//    self = (CDVCompass*)[super initWithWebView:(UIWebView*)theWebView];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object
        // __locationStarted = NO;
        // __highAccuracyEnabled = NO;
        self.beaconData = nil;
        
        self.lastImmediate = [[NSDate alloc] init];
        
        self.beaconDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)hasHeadingSupport
{
    BOOL headingInstancePropertyAvailable = [self.locationManager respondsToSelector:@selector(headingAvailable)]; // iOS 3.x
    BOOL headingClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(headingAvailable)]; // iOS 4.x

    if (headingInstancePropertyAvailable) { // iOS 3.x
        return [(id)self.locationManager headingAvailable];
    } else if (headingClassPropertyAvailable) { // iOS 4.x
        return [CLLocationManager headingAvailable];
    } else { // iOS 2.x
        return NO;
    }
}

- (void)addRegion:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    
    @try {

        NSArray* arguments = command.arguments;
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[arguments objectAtIndex:1]];
        NSString* identifier = [arguments objectAtIndex:0];
        
       
        CLBeaconRegion *myRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
        
        [self.beaconDict setObject:myRegion forKey:identifier];
        [self.locationManager startMonitoringForRegion: myRegion];
        
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    }
    @catch (NSException * e) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}


#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    NSLog(@"Entered region..%@", region.identifier);
    [self.locationManager startRangingBeaconsInRegion: self.beaconDict[region.identifier]];
    
    NSMutableDictionary *inner = [[NSMutableDictionary alloc] init];
    [inner setObject:region.identifier forKey:@"identifier"];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [result setObject:inner forKey:@"ibeacon"];
    
    
    NSString *jsStatement = [NSString stringWithFormat:@"cordova.fireDocumentEvent('ibeaconenter', %@);", [result JSONString]];
    [self.commandDelegate evalJs:jsStatement];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{
    NSLog(@"Exited region..%@", region.identifier);
    [self.locationManager stopRangingBeaconsInRegion: self.beaconDict[region.identifier]];
    
    NSMutableDictionary *inner = [[NSMutableDictionary alloc] init];
    [inner setObject:region.identifier forKey:@"identifier"];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [result setObject:inner forKey:@"ibeacon"];
    
    NSString *jsStatement = [NSString stringWithFormat:@"cordova.fireDocumentEvent('ibeaconexit', %@);", [result JSONString]];
    [self.commandDelegate evalJs:jsStatement];
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
    
    // Beacon found!
    if (beacons.count > 0) {
       
        CLBeacon *foundBeacon = [beacons firstObject];
        
        if (foundBeacon.proximity == CLProximityUnknown) {
            //        self.distanceLabel.text = @"Unknown";
        } else if (foundBeacon.proximity == CLProximityImmediate) {
            
           
            NSTimeInterval secs = [self.lastImmediate timeIntervalSinceNow];
            
            if (secs < -6) {
                
                // You can retrieve the beacon data from its properties
                NSString *uuid = foundBeacon.proximityUUID.UUIDString;
                NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
                NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
                
                NSMutableDictionary *inner = [[NSMutableDictionary alloc] init];
                
                [inner setObject:uuid forKey:@"uuid"];
                [inner setObject:major forKey:@"major"];
                [inner setObject:minor forKey:@"minor"];
                [inner setObject:@"immediate" forKey:@"range"];
                [inner setObject:region.identifier forKey:@"identifier"];
                
                NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
                [result setObject:inner forKey:@"ibeacon"];

                self.lastImmediate = [[NSDate alloc] init];
                
                NSString *jsStatement = [NSString stringWithFormat:@"cordova.fireDocumentEvent('ibeacon', %@);", [result JSONString]];
                
                [self.commandDelegate evalJs:jsStatement];
            }
            
        } else if (foundBeacon.proximity == CLProximityNear) {
            //        self.distanceLabel.text = @"Near";
        } else if (foundBeacon.proximity == CLProximityFar) {
            //        self.distanceLabel.text = @"Far";
        }
    }
    
    
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"hello %@", region.identifier);
    [self.locationManager startRangingBeaconsInRegion: self.beaconDict[region.identifier]];
}


/*

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    NSLog(@"locationManager::didFailWithError %@", [error localizedFailureReason]);

    // Compass Error
    if ([error code] == kCLErrorHeadingFailure) {
        CDVHeadingData* hData = self.headingData;
        if (hData) {
            if (hData.headingStatus == HEADINGSTARTING) {
                // heading error during startup - report error
                for (NSString* callbackId in hData.headingCallbacks) {
                    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:0];
                    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                }

                [hData.headingCallbacks removeAllObjects];
            } // else for frequency watches next call to getCurrentHeading will report error
            if (hData.headingFilter) {
                CDVPluginResult* resultFilter = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:0];
                [self.commandDelegate sendPluginResult:resultFilter callbackId:hData.headingFilter];
            }
            hData.headingStatus = HEADINGERROR;
        }
    }

    [self.locationManager stopUpdatingLocation];
    __locationStarted = NO;
}
*/

- (void)dealloc
{
    self.locationManager.delegate = nil;
    self.beaconDict = nil;
}

- (void)onReset
{
//    [self.locationManager stopUpdatingHeading];
    self.beaconDict = nil;
}

@end