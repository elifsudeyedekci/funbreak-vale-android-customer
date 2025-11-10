package com.funbreakvale.customer

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🔥 TÜRKÇE KARAKTER SORUNU ÇÖZÜMÜ!
        // Soft input mode'u ayarla
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        
        // Debug log
        println("🔍 MainActivity onCreate - Locale: ${resources.configuration.locale}")
        println("🔍 MainActivity onCreate - Keyboard configured for Turkish input")
    }
}
