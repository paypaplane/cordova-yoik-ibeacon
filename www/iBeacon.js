/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var argscheck = require('cordova/argscheck'),
    exec = require('cordova/exec'),
    Constants = require('./iBeaconConstants');
    // XXX: commented out
    //CameraPopoverHandle = require('./CameraPopoverHandle');

var iBeaconExports = {};

// Tack on the iBeacon Constants to the base plugin.
for (var key in Constants) {
    iBeaconExports[key] = Constants[key];
}

iBeaconExports.addRegion = function(successCallback, errorCallback, options) {
    argscheck.checkArgs('fFO', 'iBeacon.addRegion', arguments);
    options = options || {};
    var getValue = argscheck.getValue;

    var identifier = getValue(options.identifier, 'defaultRegion');
    var uuid = getValue(options.destinationType, '');

    var args = [identifier, uuid];

    exec(successCallback, errorCallback, "iBeacon", "addRegion", args);
};


// cameraExport.cleanup = function(successCallback, errorCallback) {
//     exec(successCallback, errorCallback, "Camera", "cleanup", []);
// };

module.exports = iBeaconExports;