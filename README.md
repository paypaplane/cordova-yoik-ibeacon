cordova-yoik-ibeacon
===============

A very incomplete, not entirely bug free iBeacon plugin.

# Watch a region/UUID
    cordova.plugins.iBeacon.addRegion(
        // Success Callback
        function() {
            console.log('added successfully') ;
        }, 
        // Error Callback
        function() { 
            console.log('oh no! error');
        }, 
        // Params
        { 
            identifier: 'com.mydomain.ibeacon.myregion', 
            uuid: 'MY-UUID'
        }
    );

# Events

## ibeacon
Called when in immediate proximity

    {
        // event data
        ibeacon: {
            uuid: 'MY-UUID',
            major: 1,
            minor: 1,
            range: 'immediate',
            identifier: 'com.mydomain.ibeacon.myregion'
        }
    }

## ibeaconEnter
Called when a region is entered. 

    {
        // event data
        ibeacon: {
            identifier: 'com.mydomain.ibeacon.myregion'
        }
    }

## ibeaconExit
Called when a region is exited.

    {
        // event data
        ibeacon: {
            identifier: 'com.mydomain.ibeacon.myregion'
        }
    }
