package net.yoik.cordova.plugins.ibeacon;


import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Intent;
import android.content.Context;
import android.util.Log;
import android.os.RemoteException;
import android.content.ServiceConnection;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import com.radiusnetworks.ibeacon.IBeaconConsumer;
import com.radiusnetworks.ibeacon.IBeaconManager;
import com.radiusnetworks.ibeacon.MonitorNotifier;
import com.radiusnetworks.ibeacon.Region;

/**
 * This calls out to the ZXing barcode reader and returns the result.
 *
 * @sa https://github.com/apache/cordova-android/blob/master/framework/src/org/apache/cordova/CordovaPlugin.java
 */
public class YoikIBeacon extends CordovaPlugin implements IBeaconConsumer {
    public static final int REQUEST_CODE = 0x0ba7c0de;

    // private static final String SCAN = "scan";

    // private static final String LOG_TAG = "BarcodeScanner";

    private CallbackContext callbackContext;

    /**
     * Constructor.
     */
    public YoikIBeacon() {
    }

    /**
     * Executes the request.
     *
     * This method is called from the WebView thread. To do a non-trivial amount of work, use:
     *     cordova.getThreadPool().execute(runnable);
     *
     * To run on the UI thread, use:
     *     cordova.getActivity().runOnUiThread(runnable);
     *
     * @param action          The action to execute.
     * @param args            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return                Whether the action was valid.
     *
     * @sa https://github.com/apache/cordova-android/blob/master/framework/src/org/apache/cordova/CordovaPlugin.java
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        this.callbackContext = callbackContext;

        if (action.equals("asdf")) {
            JSONObject obj = args.optJSONObject(0);
            if (obj != null) {
                // String type = obj.optString(TYPE);
                // String data = obj.optString(DATA);

                // // If the type is null then force the type to text
                // if (type == null) {
                //     type = TEXT_TYPE;
                // }

                // if (data == null) {
                //     callbackContext.error("User did not specify data to encode");
                //     return true;
                // }

                // encode(type, data);
            } else {
                callbackContext.error("User did not specify data to encode");
                return true;
            }
        } else if (action.equals("scan")) {
            //scan();
        } else {
            return false;
        }
        return true;
    }

    // /**
    //  * Starts an intent to scan and decode a barcode.
    //  */
    // public void scan() {
    //     Intent intentScan = new Intent(SCAN_INTENT);
    //     intentScan.addCategory(Intent.CATEGORY_DEFAULT);

    //     this.cordova.startActivityForResult((CordovaPlugin) this, intentScan, REQUEST_CODE);
    // }

    // /**
    //  * Called when the barcode scanner intent completes.
    //  *
    //  * @param requestCode The request code originally supplied to startActivityForResult(),
    //  *                       allowing you to identify who this result came from.
    //  * @param resultCode  The integer result code returned by the child activity through its setResult().
    //  * @param intent      An Intent, which can return result data to the caller (various data can be attached to Intent "extras").
    //  */
    // @Override
    // public void onActivityResult(int requestCode, int resultCode, Intent intent) {
    //     if (requestCode == REQUEST_CODE) {
    //         if (resultCode == Activity.RESULT_OK) {
    //             JSONObject obj = new JSONObject();
    //             try {
    //                 obj.put(TEXT, intent.getStringExtra("SCAN_RESULT"));
    //                 obj.put(FORMAT, intent.getStringExtra("SCAN_RESULT_FORMAT"));
    //                 obj.put(CANCELLED, false);
    //             } catch (JSONException e) {
    //                 Log.d(LOG_TAG, "This should never happen");
    //             }
    //             //this.success(new PluginResult(PluginResult.Status.OK, obj), this.callback);
    //             this.callbackContext.success(obj);
    //         } else if (resultCode == Activity.RESULT_CANCELED) {
    //             JSONObject obj = new JSONObject();
    //             try {
    //                 obj.put(TEXT, "");
    //                 obj.put(FORMAT, "");
    //                 obj.put(CANCELLED, true);
    //             } catch (JSONException e) {
    //                 Log.d(LOG_TAG, "This should never happen");
    //             }
    //             //this.success(new PluginResult(PluginResult.Status.OK, obj), this.callback);
    //             this.callbackContext.success(obj);
    //         } else {
    //             //this.error(new PluginResult(PluginResult.Status.ERROR), this.callback);
    //             this.callbackContext.error("Unexpected error");
    //         }
    //     }
    // }

    private IBeaconManager iBeaconManager = IBeaconManager.getInstanceForApplication(cordova.getActivity());

    private void init(CallbackContext callbackContext) {
        Log.d("GRANT", "Enabling plugin");

        // startNfc();
        // if (!recycledIntent()) {
        //     parseMessage();
        // }
        callbackContext.success();
    }

    // @Override 
    // public void onDestroy(boolean multitasking) {
    //     // super.onDestroy(multitasking);
    //     iBeaconManager.unBind(this);
    // }
    @Override 
    public void onPause(boolean multitasking) {
        super.onPause(multitasking);
        if (iBeaconManager.isBound(this)) iBeaconManager.setBackgroundMode(this, true);
    }
    @Override 
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
        if (iBeaconManager.isBound(this)) iBeaconManager.setBackgroundMode(this, false);
    }

    public Context getApplicationContext() {
        return cordova.getActivity().getApplicationContext();
    }

    public void unbindService(ServiceConnection connection) {
        cordova.getActivity().unbindService(connection);
    }

    public boolean bindService(Intent intent, ServiceConnection connection, int mode) {
        Log.d("GRANT", "HERE!");
        return cordova.getActivity().bindService(intent, connection, mode);
    }

    @Override
    public void onIBeaconServiceConnect() {
        iBeaconManager.setMonitorNotifier(new MonitorNotifier() {
        @Override
        public void didEnterRegion(Region region) {
          // logToDisplay("I just saw an iBeacon for the first time!");       
            Log.d("GRANT", "I just saw an iBeacon for the first time!");
        }

        @Override
        public void didExitRegion(Region region) {
            // logToDisplay("I no longer see an iBeacon");
            Log.d("GRANT", "I no longer see an iBeacon");
        }

        @Override
        public void didDetermineStateForRegion(int state, Region region) {
            // logToDisplay("I have just switched from seeing/not seeing iBeacons: "+state);
            Log.d("GRANT", "I have just switched from seeing/not seeing iBeacons: "+state);
        }


        });

        try {
            Log.d("GRANT", "START IT!");
            iBeaconManager.startMonitoringBeaconsInRegion(new Region("2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6", null, null, null));
        } catch (RemoteException e) {   }
    }

    
}
