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

#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVShared.h>


// simple object to keep track of beacon info
@interface YoikIBeaconData : NSObject {}

@property (nonatomic, strong) NSString* uuid;
@property (assign) NSInteger* major;
@property (assign) NSInteger* minor;
@property (nonatomic, strong) NSString* identifier;

@end

@interface YoikIBeacon : CDVPlugin <CLLocationManagerDelegate>{
    // @private BOOL __locationStarted;
    // @private BOOL __highAccuracyEnabled;
    YoikIBeaconData* beaconData;
}

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (strong, nonatomic) NSMutableDictionary *beaconDict;

@property (strong) YoikIBeaconData* beaconData;

- (BOOL)hasIBeaconSupport;

- (void)addRegion:(CDVInvokedUrlCommand*)command;

- (void)locationManager:(CLLocationManager*)manager
       didFailWithError:(NSError*)error;

- (void)getHeading:(CDVInvokedUrlCommand*)command;
- (void)returnHeadingInfo:(NSString*)callbackId keepCallback:(BOOL)bRetain;
- (void)watchHeadingFilter:(CDVInvokedUrlCommand*)command;
- (void)stopHeading:(CDVInvokedUrlCommand*)command;
- (void)startHeadingWithFilter:(CLLocationDegrees)filter;
- (void)locationManager:(CLLocationManager*)manager
       didUpdateHeading:(CLHeading*)heading;

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager*)manager;

@end