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
        self.lastFar = [[NSDate alloc] init];
        
        self.beaconDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addRegion:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    
    @try {
        
        

        NSArray* arguments = command.arguments;
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[arguments objectAtIndex:1]];
        NSString* identifier = [arguments objectAtIndex:0];
        NSLog(@"added region.. %@", [arguments objectAtIndex:1]);
       
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
        
        switch (foundBeacon.proximity) {
            case CLProximityImmediate:
            {
                NSTimeInterval secs = [self.lastImmediate timeIntervalSinceNow];
                
                if (secs < -6) {
                    [self sendIbeaconEvent:foundBeacon forRegion:region];
                    
                    self.lastImmediate = [[NSDate alloc] init];
                }
            }
            case CLProximityNear:
            case CLProximityFar:
            {
                NSTimeInterval secs = [self.lastFar timeIntervalSinceNow];
                
                if (secs < -60) {
                    [self sendIbeaconEvent:foundBeacon forRegion:region];
                    
                    self.lastFar = [[NSDate alloc] init];
                }
            }
            default:
                break;
        }
    }
    
}

- (void)sendIbeaconEvent:(CLBeacon *)foundBeacon forRegion:(CLRegion *) region
{
    NSLog(@"Sending event");
    // You can retrieve the beacon data from its properties
    NSString *uuid = foundBeacon.proximityUUID.UUIDString;
    NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
    NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
    
    NSMutableDictionary *inner = [[NSMutableDictionary alloc] init];
    
    [inner setObject: [uuid lowercaseString] forKey:@"uuid"];
    [inner setObject: major forKey:@"major"];
    [inner setObject: minor forKey:@"minor"];
    [inner setObject: [self regionText:foundBeacon] forKey:@"range"];
    [inner setObject:region.identifier forKey:@"identifier"];
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [result setObject:inner forKey:@"ibeacon"];
    
    NSLog(@"%@", [result JSONString]);
    
    NSString *jsStatement = [NSString stringWithFormat:@"cordova.fireDocumentEvent('ibeacon', %@);", [result JSONString]];
    
    [self.commandDelegate evalJs:jsStatement];
}

- (NSString *)regionText:(CLBeacon *)beacon
{
    switch (beacon.proximity) {
        case CLProximityFar:
            return @"far";
        case CLProximityImmediate:
            return @"immediate";
        case CLProximityNear:
            return @"near";
        default:
            return @"unknown";
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"hello %@", region.identifier);
    [self.locationManager startRangingBeaconsInRegion: self.beaconDict[region.identifier]];
}

- (void)locationManager: (CLLocationManager *)manager
       didFailWithError: (NSError *)error
{
    [manager stopUpdatingLocation];
    NSLog(@"error%@",error);
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"please check your network connection or that you are not in airplane mode" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [alert show];
//            [alert release];
        }
            break;
        case kCLErrorDenied:{
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"user has denied to use current Location " delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [alert show];
//            [alert release];
        }
            break;
        default:
        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"unknown network error" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [alert show];
//            [alert release];
        }
            break;
    }

}

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