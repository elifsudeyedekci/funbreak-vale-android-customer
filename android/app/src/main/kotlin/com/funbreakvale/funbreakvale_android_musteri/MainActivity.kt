package com.funbreakvale.funbreakvale_android_musteri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import java.util.Locale

class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // 🇹🇷 TÜRKÇE LOCALE'İ BAŞTAN AYARLA
        setLocaleToTurkish()
        super.onCreate(savedInstanceState)
    }
    
    override fun attachBaseContext(newBase: Context) {
        // 🇹🇷 Context oluşturulmadan önce Türkçe locale ayarla
        super.attachBaseContext(updateBaseContextLocale(newBase))
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 🇹🇷 TÜRKÇE KLAVYE VE KARAKTER DESTEĞİ
        setLocaleToTurkish()
    }
    
    private fun setLocaleToTurkish() {
        val locale = Locale("tr", "TR")
        Locale.setDefault(locale)
        
        val config = Configuration(resources.configuration)
        config.setLocale(locale)
        resources.updateConfiguration(config, resources.displayMetrics)
    }
    
    private fun updateBaseContextLocale(context: Context): Context {
        val locale = Locale("tr", "TR")
        Locale.setDefault(locale)
        
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        
        return context.createConfigurationContext(config)
    }
}
