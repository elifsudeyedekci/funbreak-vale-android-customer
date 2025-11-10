import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// GELİŞMİŞ BİLDİRİM SERVİSİ - MÜŞTERİ UYGULAMASI!
class AdvancedNotificationService {
  static const String baseUrl = 'https://admin.funbreakvale.com/api';
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static FirebaseMessaging? _messaging;
  
  // MÜŞTERİ BİLDİRİM TÜRLERİ
  static const Map<String, NotificationConfig> _customerNotifications = {
    'driver_found': NotificationConfig(
      title: '🎯 Vale Bulundu!',
      channelId: 'ride_updates',
      priority: 'high',
      sound: 'notification.wav',
    ),
    'driver_departed': NotificationConfig(
      title: '🚗 Vale Yola Çıktı',
      channelId: 'ride_updates',
      priority: 'normal',
      sound: 'default',
    ),
    'driver_approaching_5km': NotificationConfig(
      title: '📍 Vale Yaklaşıyor',
      channelId: 'location_updates',
      priority: 'high',
      sound: 'notification.wav',
    ),
    'driver_approaching_2km': NotificationConfig(
      title: '📍 Vale Çok Yakın',
      channelId: 'location_updates',
      priority: 'high',
      sound: 'notification.wav',
    ),
    'driver_approaching_500m': NotificationConfig(
      title: '🏃‍♂️ Vale Neredeyse Geldi',
      channelId: 'location_updates',
      priority: 'high',
      sound: 'notification.wav',
    ),
    'driver_arrived': NotificationConfig(
      title: '✋ Vale Geldi!',
      channelId: 'ride_updates',
      priority: 'high',
      sound: 'notification.wav',
    ),
    'ride_started': NotificationConfig(
      title: '▶️ Yolculuk Başladı',
      channelId: 'ride_updates',
      priority: 'normal',
      sound: 'default',
    ),
    'ride_completed': NotificationConfig(
      title: '✅ Yolculuk Tamamlandı',
      channelId: 'ride_updates',
      priority: 'normal',
      sound: 'notification.wav',
    ),
    'payment_processed': NotificationConfig(
      title: '💳 Ödeme İşlendi',
      channelId: 'payment_updates',
      priority: 'normal',
      sound: 'default',
    ),
    // new_campaign kaldırıldı - zaten mevcut kampanya sistemi çalışıyor!
  };
  
  // SERVİS BAŞLATMA
  static Future<void> initialize() async {
    try {
      print('🔔 Gelişmiş bildirim servisi başlatılıyor...');
      
      // Local notifications setup
      const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings = InitializationSettings(android: android);
      
      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Android notification channels
      await _createNotificationChannels();
      
      // Firebase Messaging setup
      _messaging = FirebaseMessaging.instance;
      
      // Permission iste
      await _requestPermissions();
      
      // Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      
      // App açılışında notification handler
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
      
      // Token güncelleme
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
      
      // Topic'lere subscribe
      await _subscribeToTopics();
      
      print('✅ Gelişmiş bildirim servisi hazır!');
      
    } catch (e) {
      print('❌ Bildirim servisi başlatma hatası: $e');
    }
  }
  
  // ANDROID BİLDİRİM KANALLARI
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'ride_updates',
        'Yolculuk Güncellemeleri',
        description: 'Vale durumu ve yolculuk güncellemeleri',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'location_updates', 
        'Konum Güncellemeleri',
        description: 'Vale konum ve mesafe bildirimleri',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'payment_updates',
        'Ödeme Bildirimleri', 
        description: 'Ödeme ve fatura bilgileri',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      // campaigns kanalı kaldırıldı - mevcut sistem kullanılıyor
    ];
    
    for (final channel in channels) {
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    print('✅ ${channels.length} bildirim kanalı oluşturuldu');
  }
  
  // İZİN İSTEME
  static Future<void> _requestPermissions() async {
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('🔔 Bildirim izni durumu: ${settings.authorizationStatus}');
  }
  
  // TOPIC SUBSCRIBE
  static Future<void> _subscribeToTopics() async {
    try {
      await _messaging!.subscribeToTopic('funbreak_customers');
      print('✅ Müşteri topic\'ine subscribe oldu');
    } catch (e) {
      print('❌ Topic subscribe hatası: $e');
    }
  }
  
  // BACKGROUND MESSAGE HANDLER
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('🔔 Background mesaj alındı: ${message.messageId}');
    await _showLocalNotification(message);
  }
  
  // FOREGROUND MESSAGE HANDLER
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground mesaj alındı: ${message.notification?.title}');
    await _showLocalNotification(message);
  }
  
  // NOTIFICATION TAP HANDLER
  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    print('🔔 Bildirime tıklandı: ${response.payload}');
    
    // Payload'a göre sayfa yönlendirme yapılabilir
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      await _handleNotificationAction(data);
    }
  }
  
  // MESSAGE OPENED APP HANDLER
  static Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    print('🔔 Mesajdan uygulama açıldı: ${message.messageId}');
    await _handleNotificationAction(message.data);
  }
  
  // TOKEN REFRESH HANDLER
  static Future<void> _onTokenRefresh(String token) async {
    print('🔔 FCM Token yenilendi: ${token.substring(0, 20)}...');
    // Backend'e token güncelleme gönder
    await _updateTokenOnServer(token);
  }
  
  // LOCAL BİLDİRİM GÖSTER
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'ride_updates',
          'Yolculuk Güncellemeleri',
          channelDescription: 'Vale durumu ve yolculuk güncellemeleri',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification'),
          icon: '@mipmap/ic_launcher',
        ),
      );
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(message.data),
      );
    }
  }
  
  // BİLDİRİM AKSİYON HANDLER
  static Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    final type = data['notification_type'] ?? '';
    
    print('🔔 Bildirim aksiyonu: $type');
    
    // Bildirim türüne göre sayfa yönlendirme
    switch (type) {
      case 'driver_found':
      case 'driver_approaching':
      case 'driver_arrived':
        // Ana sayfaya git (harita göster)
        break;
      case 'ride_completed':
        // Geçmiş yolculuklara git  
        break;
      case 'payment_processed':
        // Ödeme geçmişine git
        break;
        // new_campaign kaldırıldı
    }
  }
  
  // SUNUCUYA TOKEN GÜNCELLE
  static Future<void> _updateTokenOnServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '0';
      
      final response = await http.post(
        Uri.parse('$baseUrl/update_fcm_token.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'user_type': 'customer',
          'fcm_token': token,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ FCM Token sunucuya güncellendi');
      }
    } catch (e) {
      print('❌ Token güncelleme hatası: $e');
    }
  }
  
  // MANUEl BİLDİRİM GÖNDER
  static Future<bool> sendNotification({
    required String notificationType,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '0';
      
      final config = _customerNotifications[notificationType];
      if (config == null) {
        print('❌ Bilinmeyen bildirim türü: $notificationType');
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/send_advanced_notification.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'user_type': 'customer',
          'notification_type': notificationType,
          'title': config.title,
          'message': _formatMessage(config.title, data),
          'data': data,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('❌ Manuel bildirim gönderim hatası: $e');
      return false;
    }
  }
  
  // MESAJ FORMATLAMA
  static String _formatMessage(String template, Map<String, dynamic> data) {
    String message = template;
    
    // Template'deki değişkenleri data ile değiştir
    data.forEach((key, value) {
      message = message.replaceAll('{$key}', value.toString());
    });
    
    return message;
  }
  
  // BİLDİRİM GEÇMİŞİ ÇEK
  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '0';
      
      final response = await http.get(
        Uri.parse('$baseUrl/get_notification_history.php?user_id=$userId&user_type=customer'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Bildirim geçmişi çekme hatası: $e');
      return [];
    }
  }
}

// BİLDİRİM KONFİGÜRASYON SINIFI
class NotificationConfig {
  final String title;
  final String channelId;
  final String priority;
  final String sound;
  
  const NotificationConfig({
    required this.title,
    required this.channelId,
    required this.priority,
    required this.sound,
  });
}
