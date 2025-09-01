package com.example.cinema_app

import android.util.Log
import androidx.annotation.NonNull
import com.kbzbank.payment.KBZPay
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import org.json.JSONException
import org.json.JSONObject
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter_kpay"
    private val sendChannel = "kpay_flutter"
    private val TAG = "kpay"
    private var mOrderInfo: String? = null
    private var mMerchantCode = ""
    private var mAppId = ""
    private var mSignKey = ""
    private var mSign = ""
    private val mSignType = "SHA256"
    private var mTitle = ""
    private var mAmount = "0"
    private var mPrepayId = ""
    private var mMerchantOrderId = ""

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startPay") {
                Log.d(TAG, "call")
                val map = call.arguments<HashMap<String?, Any?>>()!!
                try {
                    val params = JSONObject(map)
                    Log.v("startPay", params.toString())
                    if (params.has("prepay_id") && params.has("merch_code") && params.has("appid")
                        && params.has("sign_key")
                    ) {
                        mPrepayId = params.getString("prepay_id")
                        mMerchantCode = params.getString("merch_code")
                        mAppId = params.getString("appid")
                        mSignKey = params.getString("sign_key")
                        startPay()
                        result.success("payStatus " + 0)
                    } else {
                        result.error("parameter error", "parameter error", null)
                    }
                } catch (e: JSONException) {
                    e.printStackTrace()
                }
            }
            else {
                result.notImplemented()
            }

        }

         methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sendChannel)
    }






    private fun startPay() {
        buildOrderInfo()
        Log.d(TAG, mOrderInfo!!)
        Log.d(TAG, mSign)
        KBZPay.startPay(this@MainActivity, mOrderInfo, mSign, mSignType)
    }

    companion object{
        var methodChannel : MethodChannel? = null
    }


    private fun buildOrderInfo() {
        // prepayId由服务器下单得到
        val prepayId = mPrepayId
        Log.d(TAG, prepayId)
        val nonceStr = createRandomStr()
        val timestamp = createTimestamp()
        mOrderInfo = "appid=" + mAppId +
                "&merch_code=" + mMerchantCode +
                "&nonce_str=" + nonceStr +
                "&prepay_id=" + prepayId +
                "&timestamp=" + timestamp
        mSign = SHA.getSHA256Str("$mOrderInfo&key=$mSignKey")
    }

    private fun createRandomStr(): String {
        val random = Random()
        return java.lang.Long.toString(Math.abs(random.nextLong()))
    }

    private fun createTimestamp(): String {
        val cal = Calendar.getInstance()
        val time = (cal.timeInMillis / 1000).toDouble()
        val d = java.lang.Double.valueOf(time)
        return Integer.toString(d.toInt())
    }
}
