package com.example.cinema_app.com.kbzbank.payment.sdk;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import com.google.android.gms.common.api.Result;

import org.json.JSONObject;

import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class FlutterKBZPayPlugin implements  FlutterPlugin, ActivityAware {
    private static EventChannel.EventSink sink;
    /**
     * Plugin registration.
     */

    private Context context;
    private Activity activity;



    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        // TODO: your plugin is now attached to an Activity
        this.activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.context = applicationContext;
        final EventChannel eventchannel = new EventChannel(messenger, "flutter_kbz_pay/pay_status");
        eventchannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                SetSink(eventSink);
            }

            @Override
            public void onCancel(Object o) {

            }
        });
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        context = null;
    }



    public static void SetSink(EventChannel.EventSink eventSink) {
        sink = eventSink;
    }

    public static void sendPayStatus(int status, String orderId) {
        HashMap<String, Object> map = new HashMap();
        map.put("status", status);
        map.put("orderId", orderId);
        sink.success(map);
    }


}
