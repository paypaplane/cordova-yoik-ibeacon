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


#pragma mark -
#pragma mark YoikIBeacon

@implementation YoikIBeacon

static int NIGH_PROXIMITY = -30;

@synthesize locationManager;

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object

        self.lastNigh = [[NSDate alloc] init];
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

        if (foundBeacon.rssi >= NIGH_PROXIMITY && foundBeacon.rssi < 0) {
            NSLog(@"%ld - %ld", (long)foundBeacon.rssi, (long)foundBeacon.major);

            NSTimeInterval secs = [self.lastNigh timeIntervalSinceNow];

            if (secs < -6) {
                [self sendIbeaconEvent:foundBeacon forRegion:region forRange:@"nigh"];

                self.lastNigh = [[NSDate alloc] init];
            }

        } else {
            switch (foundBeacon.proximity) {
                case CLProximityNear:
                case CLProximityFar:
                {
                    NSTimeInterval secs = [self.lastFar timeIntervalSinceNow];

                    if (secs < -60) {
                        [self sendIbeaconEvent:foundBeacon forRegion:region forRange:[self regionText:foundBeacon]];

                        self.lastFar = [[NSDate alloc] init];
                    }
                }
                    break;
                default:
                    break;
            }
        }
    }

}

- (void)sendIbeaconEvent:(CLBeacon *)foundBeacon forRegion:(CLRegion *) region forRange:(NSString *) range
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
    [inner setObject: range forKey:@"range"];
    [inner setObject:region.identifier forKey:@"identifier"];

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [result setObject:inner forKey:@"ibeacon"];

    NSLog(@"%@", [result JSONString]);

    NSString *jsStatement = [NSString stringWithFormat:@"cordova.fireDocumentEvent('ibeacon', %@);", [result JSONString]];

    [self.commandDelegate evalJs:jsStatement];
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
}

- (void)dealloc
{
    self.locationManager.delegate = nil;
    self.beaconDict = nil;
}

- (void)onReset
{
    self.beaconDict = nil;
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

@end