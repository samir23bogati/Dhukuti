package com.dhukuti.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15+ edge-to-edge without deprecated Window color APIs.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
