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
import android.text.format.Time;

import java.util.Collection;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;

import com.radiusnetworks.ibeacon.IBeacon;
import com.radiusnetworks.ibeacon.IBeaconData;
import com.radiusnetworks.ibeacon.IBeaconConsumer;
import com.radiusnetworks.ibeacon.IBeaconDataNotifier;
import com.radiusnetworks.ibeacon.IBeaconManager;
import com.radiusnetworks.ibeacon.client.DataProviderException;
import com.radiusnetworks.ibeacon.MonitorNotifier;
import com.radiusnetworks.ibeacon.Region;
import com.radiusnetworks.ibeacon.RangeNotifier;

/**
 * This calls out to the ZXing barcode reader and returns the result.
 *
 * @sa https://github.com/apache/cordova-android/blob/master/framework/src/org/apache/cordova/CordovaPlugin.java
 */
public class YoikIBeacon extends CordovaPlugin implements IBeaconConsumer, MonitorNotifier, RangeNotifier, IBeaconDataNotifier {
    public static final int REQUEST_CODE = 0x0ba7c0de;

    private static final String TAG = "YoikIBeacon";    

    private static final String ACTION_ADDREGION = "addRegion";

    private IBeaconManager iBeaconManager;

    private Time lastImmediate;

    private CallbackContext callbackContext;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        // your init code here
        Log.d(TAG, "starting");

        final Activity activity = cordova.getActivity();
        final YoikIBeacon that = this;

        this.lastImmediate = new Time();
        this.lastImmediate.setToNow();

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                
                iBeaconManager = IBeaconManager.getInstanceForApplication(activity);
                iBeaconManager.bind(that);
            }
        });
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
     * @param data            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return                Whether the action was valid.
     *
     * @sa https://github.com/apache/cordova-android/blob/master/framework/src/org/apache/cordova/CordovaPlugin.java
     */
    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) {
        this.callbackContext = callbackContext;

        Log.d(TAG, "execute " + action);

        if (action.equals(ACTION_ADDREGION)) {
            addRegion(data, callbackContext);            
        } else if (action.equals("anotheraction")) {
            
        } else {
            return false;
        }
        return true;
    }

    private void addRegion(JSONArray data, CallbackContext callbackContext) {
   
        Log.d(TAG, "START IT!");

        final JSONArray data2 = data;
        final CallbackContext callbackContext2 = callbackContext;

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    iBeaconManager.startMonitoringBeaconsInRegion(new Region(data2.optString(0), data2.optString(1), null, null));
                    callbackContext2.success();

                } catch (RemoteException e) {   
                    callbackContext2.error("Could not add region");
                }  
            }
        });
            
    }

    private void init(CallbackContext callbackContext) {
        Log.d(TAG, "Enabling plugin");

        callbackContext.success();
    }

    @Override 
    public void onDestroy() {
        super.onDestroy();
        iBeaconManager.unBind(this);
    }

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
        Log.d(TAG, "HERE!");
        return cordova.getActivity().bindService(intent, connection, mode);
    }

    @Override
    public void onIBeaconServiceConnect() {
        iBeaconManager.setMonitorNotifier(this);        
        
        Log.d(TAG, "START IT - OLD!");
    }

    @Override
    public void didEnterRegion(Region region) {
           
        Log.d(TAG, "I just saw an iBeacon for the first time!");

        try {
            iBeaconManager.startRangingBeaconsInRegion(region);
            iBeaconManager.setRangeNotifier(this);

            JSONObject obj = new JSONObject();
                
            obj.put("identifier", region.getUniqueId());
            
            JSONObject result = new JSONObject();
            result.put("ibeacon", obj);
            
            
            final String jsStatement = String.format("cordova.fireDocumentEvent('ibeaconEnter', %s);", result.toString());

            cordova.getActivity().runOnUiThread(
                new Runnable() { 
                    @Override
                     public void run() {
                         webView.loadUrl("javascript:" + jsStatement);
                     }
                }
            );

        } catch (JSONException e) {
            e.printStackTrace();
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void didExitRegion(Region region) {
        
        Log.d(TAG, "I no longer see an iBeacon");

        try {
            iBeaconManager.startRangingBeaconsInRegion(region);

            JSONObject obj = new JSONObject();
                
            obj.put("identifier", region.getUniqueId());
            
            JSONObject result = new JSONObject();
            result.put("ibeacon", obj);
            
            
            final String jsStatement = String.format("cordova.fireDocumentEvent('ibeaconExit', %s);", result.toString());

            cordova.getActivity().runOnUiThread(
                new Runnable() { 
                    @Override
                     public void run() {
                         webView.loadUrl("javascript:" + jsStatement);
                     }
                }
            );

        } catch (JSONException e) {
            e.printStackTrace();
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void didDetermineStateForRegion(int state, Region region) {
        // logToDisplay("I have just switched from seeing/not seeing iBeacons: "+state);
        Log.d(TAG, "I have just switched from seeing/not seeing iBeacons: "+state);
    }


    @Override
    public void didRangeBeaconsInRegion(Collection<IBeacon> iBeacons, Region region) {
        try {
            for (IBeacon iBeacon: iBeacons) {
                if (iBeacon.getAccuracy() < 0.015) {       
                    Log.d(TAG, "Found One: "+iBeacon.getAccuracy() + " " + iBeacon.getProximityUuid()+" "+iBeacon.getMajor()+" "+iBeacon.getMinor());

                    Time now = new Time();
                    now.setToNow();

                    if ((now.toMillis(false) - this.lastImmediate.toMillis(false)) > 6000) {

                        JSONObject obj = new JSONObject();                
                        obj.put("uuid", iBeacon.getProximityUuid());
                        obj.put("major", iBeacon.getMajor());
                        obj.put("minor", iBeacon.getMinor());
                        obj.put("range", "immediate");
                        obj.put("identifier", region.getUniqueId());

                        JSONObject result = new JSONObject();
                        result.put("ibeacon", obj);

                        final String jsStatement = String.format("cordova.fireDocumentEvent('ibeacon', %s);", result.toString());

                        cordova.getActivity().runOnUiThread(
                            new Runnable() { 
                                @Override
                                 public void run() {
                                     webView.loadUrl("javascript:" + jsStatement);
                                 }
                            }
                        );

                        this.lastImmediate.setToNow();
                    }

                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        } 
    }

    @Override
    public void iBeaconDataUpdate(IBeacon iBeacon, IBeaconData iBeaconData, DataProviderException e) {
        if (e != null) {
            Log.d(TAG, "data fetch error:"+e);
        }
        if (iBeaconData != null) {
            String displayString = iBeacon.getProximityUuid()+" "+iBeacon.getMajor()+" "+iBeacon.getMinor()+"\n"+"Welcome message:"+iBeaconData.get("welcomeMessage");
            
        }
    }
    
}
