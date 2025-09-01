package com.kbzbank.payment.sdk.callback;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.example.cinema_app.MainActivity;
import com.example.cinema_app.R;
import com.kbzbank.payment.KBZPay;

import org.w3c.dom.Text;

import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;

public class CallbackResultActivity extends Activity {
    private TextView statusText;
    private ImageView statusIcon;
    private static EventChannel.EventSink sink;
    private Timer myTimer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();
        setContentView(R.layout.layout);
        statusText = findViewById(R.id.status);
        statusIcon = findViewById(R.id.imageView);
        myTimer = new Timer();
        int result = intent.getIntExtra(KBZPay.EXTRA_RESULT, 0);
        if (result == KBZPay.COMPLETED) {
            Log.d("KBZPay", "pay success!");
            statusText.setText("အောင်မြင်ပါသည်။");
            statusIcon.setImageResource(R.drawable.ic_done);
            if(MainActivity.Companion.getMethodChannel() != null){
                MainActivity.Companion.getMethodChannel().invokeMethod("status", "success");
            }

            myTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    finish();
                }

            }, 0, 1000);


        } else {
            String failMsg = intent.getStringExtra(KBZPay.EXTRA_FAIL_MSG);
            Log.d("KBZPay", "pay fail, fail reason = " + failMsg);
            Map status = new HashMap();
            status.put("status",result);
            statusText.setText("မအောင်မြင်ပါ။");
            statusIcon.setImageResource(R.drawable.ic_error);
            statusText.setOnClickListener(view -> {
            });
            if(MainActivity.Companion.getMethodChannel() != null){
                MainActivity.Companion.getMethodChannel().invokeMethod("status", "error");
            }
            myTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    finish();
                }

            }, 0, 1000);
        }

    }

}
