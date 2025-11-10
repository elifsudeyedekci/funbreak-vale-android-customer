import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';
import 'services/advanced_notification_service.dart'; // GELİŞMİŞ BİLDİRİM SERVİSİ!
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/pricing_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/location_pricing_provider.dart';
import 'providers/admin_management_provider.dart';
import 'providers/admin_api_provider.dart';  // KRİTİK IMPORT EKSİK!
import 'providers/waiting_time_provider.dart';
import 'providers/rating_provider.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/dynamic_contact_service.dart';
import 'services/session_service.dart';

// GLOBAL NAVIGATOR KEY - BILDIRIM FEEDBACK İÇİN
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// BACKGROUND MESSAGE HANDLER - UYGULAMA KAPALI
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase'i başlat
  await Firebase.initializeApp();
  
  print('📱 === MÜŞTERİ BACKGROUND BİLDİRİM ===');
  print('   📋 Title: ${message.notification?.title}');
  print('   💬 Body: ${message.notification?.body}');
  print('   📊 Data: ${message.data}');
  print('   🏷️ Type: ${message.data['type'] ?? 'bilinmeyen'}');
  print('🔔 UYGULAMA KAPALI - System notification düştü!');
  
  // RIDE STARTED - YOLCULUK BAŞLATILDI!
  if (message.data['type'] == 'ride_started') {
    print('🚗 === MÜŞTERİ BACKGROUND: YOLCULUK BAŞLATILDI ===');
    print('   🆔 Ride ID: ${message.data['ride_id']}');
    print('   💬 Mesaj: ${message.data['message']}');
    print('📲 MÜŞTERİ: Bildirim alındı - uygulama açıldığında status güncellenecek!');
  }
  
  print('✅ MÜŞTERİ Background handler tamamlandı');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // BACKGROUND MESSAGE HANDLER KAYDET - MODERN YAKLAŞIM!
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // GELİŞMİŞ BİLDİRİM SERVİSİ BAŞLAT - TIMEOUT İLE HIZLI!
    await AdvancedNotificationService.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        print('⚡ Bildirim servisi timeout - arka planda devam ediyor');
      },
    );
    
    print('Firebase + Gelişmiş bildirim sistemi başlatıldı');
  } catch (e) {
    print('Firebase init hatası: $e');
  }

  // Session servisini başlat - TIMEOUT İLE HIZLI!
  await SessionService.initializeSession().timeout(
    const Duration(seconds: 2),
    onTimeout: () {
      print('⚡ Session servisi timeout - default session kullanılıyor');
    },
  );
  
  // FCM TOKEN KAYDETME - UYGULAMA AÇILDIĞINDA OTOMATIK!
  try {
    await _initializeFirebaseMessaging().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚡ FCM setup timeout - arka planda devam edecek');
      },
    );
    print('✅ FCM token kaydetme tamamlandı');
  } catch (e) {
    print('⚠️ FCM setup hatası (devam ediliyor): $e');
  }
  
  runApp(const MyApp());
}

Future<void> _initializeFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Topic'lere subscribe ol
  await messaging.subscribeToTopic('funbreak_customers');
  await messaging.subscribeToTopic('funbreak_all');
  print('Firebase topic\'lere subscribe olundu');
  
  // Foreground mesajları dinle
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📱 === MÜŞTERİ FOREGROUND BİLDİRİM ALINDI ===');
    print('   📋 Title: ${message.notification?.title}');
    print('   💬 Body: ${message.notification?.body}');
    print('   📊 Data: ${message.data}');
    print('   🏷️ Type: ${message.data['type'] ?? 'bilinmeyen'}');

    // DRIVER ASSIGNED GOTO RIDE - MANUEL ATAMA SONRASI OTOMATİK YOLCULUK EKRANI!
    if (message.data['type'] == 'driver_assigned_goto_ride') {
      print('🚗 === DRIVER ASSIGNED - OTOMATİK YOLCULUK EKRANI AÇILIYOR ===');
      final rideId = message.data['ride_id'];
      print('🆔 Ride ID: $rideId');

      // Otomatik olarak aktif yolculuk ekranına git
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamed(
          navigatorKey.currentContext!,
          '/modern_active_ride',
          arguments: {
            'rideDetails': {
              'ride_id': rideId,
              'customer_name': message.data['customer_name'] ?? 'Müşteri',
              'pickup_address': message.data['pickup_address'] ?? 'Alış konumu',
              'destination_address': message.data['destination_address'] ?? 'Varış konumu',
              'estimated_price': message.data['estimated_price'] ?? '0',
              'driver_name': message.data['driver_name'] ?? 'Vale Görevlisi',
              'vehicle_plate': message.data['vehicle_plate'] ?? 'Vale Aracı',
              'status': 'accepted',
            },
            'isFromBackend': true,
          },
        );
        print('✅ Otomatik yolculuk ekranı açıldı - Manuel atama!');
      }
    }
    
    // RIDE STARTED - YOLCULUK BAŞLATILDI BİLDİRİMİ!
    if (message.data['type'] == 'ride_started') {
      print('🚗 === MÜŞTERİ: YOLCULUK BAŞLATILDI BİLDİRİMİ ALINDI ===');
      print('   🆔 Ride ID: ${message.data['ride_id']}');
      print('   💬 Message: ${message.data['message']}');
      print('📲 MÜŞTERİ: Aktif yolculuk ekranı status\'ü otomatik güncellenecek!');
      
      // Status güncelleme bildirimi ekrana düşürülebilir (SnackBar veya notification)
      // Aktif yolculuk ekranındaki polling bu değişikliği 3 saniyede yakalayacak
    }
  });
  
  // Background mesajları dinle
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📱 Background mesaj açıldı: ${message.notification?.title}');
    print('📊 Data: ${message.data}');

    // DRIVER ASSIGNED GOTO RIDE - UYGULAMA KAPALIYKEN TIKLANDIĞINDA OTOMATİK YOLCULUK EKRANI!
    if (message.data['type'] == 'driver_assigned_goto_ride') {
      print('🚗 === BACKGROUND DRIVER ASSIGNED - OTOMATİK YOLCULUK EKRANI AÇILIYOR ===');
      final rideId = message.data['ride_id'];
      print('🆔 Ride ID: $rideId');

      // Uygulama açıldığında otomatik olarak aktif yolculuk ekranına git
      // Bu kod ana uygulamada çalışacak
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamed(
            navigatorKey.currentContext!,
            '/modern_active_ride',
            arguments: {
              'rideDetails': {
                'ride_id': rideId,
                'customer_name': message.data['customer_name'] ?? 'Müşteri',
                'pickup_address': message.data['pickup_address'] ?? 'Alış konumu',
                'destination_address': message.data['destination_address'] ?? 'Varış konumu',
                'estimated_price': message.data['estimated_price'] ?? '0',
                'driver_name': message.data['driver_name'] ?? 'Vale Görevlisi',
                'vehicle_plate': message.data['vehicle_plate'] ?? 'Vale Aracı',
                'status': 'accepted',
              },
              'isFromBackend': true,
            },
          );
          print('✅ Background otomatik yolculuk ekranı açıldı!');
        }
      });
    }
  });
  
  // FCM token al ve kaydet
  String? token = await messaging.getToken();
  print('Müşteri FCM Token: $token');

  // FCM TOKEN'I HEMEN DATABASE'E KAYDET!
  if (token != null && token.isNotEmpty) {
    await _saveCustomerFCMToken(token);
  }
}

// MÜŞTERİ FCM TOKEN KAYDETME - ŞOFÖR GİBİ ÇALIŞIYOR!
Future<void> _saveCustomerFCMToken(String fcmToken) async {
  try {
    print('💾 MÜŞTERİ FCM Token database\'e kaydediliyor...');

    final prefs = await SharedPreferences.getInstance();
    
    // Customer ID'yi farklı formatlardan al - admin_user_id SADECE STRING!
    int? customerId;
    
    // 1. İlk önce STRING olarak dene (admin_user_id STRING olarak kayıtlı!)
    final customerIdStr = prefs.getString('admin_user_id') ??  // ← ASIL KEY (STRING!)
                          prefs.getString('customer_id') ?? 
                          prefs.getString('user_id');
    
    if (customerIdStr != null && customerIdStr.isNotEmpty) {
      customerId = int.tryParse(customerIdStr);
    }
    
    // 2. Bulunamadıysa INT olarak dene (sadece customer_id ve user_id)
    if (customerId == null) {
      customerId = prefs.getInt('customer_id') ?? prefs.getInt('user_id');
    }
    
    print('🔍 MÜŞTERİ FCM: Session keys: ${prefs.getKeys()}');
    print('🔍 MÜŞTERİ FCM: admin_user_id: ${prefs.getString('admin_user_id')}');
    print('🔍 MÜŞTERİ FCM: customer_id: ${prefs.getString('customer_id')}');
    print('🔍 MÜŞTERİ FCM: Final userId: $customerId');

    if (customerId == null || customerId <= 0) {
      print('❌ MÜŞTERİ FCM: Customer ID bulunamadı - FCM token kaydedilemedi');
      print('⚠️ MÜŞTERİ FCM: Lütfen önce giriş yapın!');
      return;
    }

    print('💾 MÜŞTERİ FCM: Token backend\'e kaydediliyor - Customer ID: $customerId');
    print('📱 Token: ${fcmToken.substring(0, 20)}...');

    final response = await http.post(
      Uri.parse('https://admin.funbreakvale.com/api/update_fcm_token.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': customerId,
        'user_type': 'customer',
        'fcm_token': fcmToken,
      }),
    ).timeout(const Duration(seconds: 10));

    print('📡 MÜŞTERİ FCM Token API Response: ${response.statusCode}');
    print('📋 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('📊 API Success: ${data['success']}');
      print('💬 Message: ${data['message']}');

      if (data['success'] == true) {
        print('✅ MÜŞTERİ FCM Token database\'e başarıyla kaydedildi!');
        print('🔔 Artık bildirimler gelecek!');
      } else {
        print('❌ MÜŞTERİ FCM Token kaydetme hatası: ${data['message']}');
      }
    } else {
      print('❌ MÜŞTERİ FCM Token kaydetme HTTP hatası: ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    print('❌ MÜŞTERİ FCM Token kaydetme hatası: $e');
    print('📚 Stack trace: $stackTrace');
  }
}

// Basit ve hızlı izin sistemi
Future<void> requestPermissions() async {
  try {
    // Bildirim izni
    await Permission.notification.request();
    
    // Konum izni
    await Permission.location.request();
    
    print('Izinler istendi');
  } catch (e) {
    print('Izin hatası: $e');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => PricingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => LocationPricingProvider()),
        ChangeNotifierProvider(create: (_) => AdminManagementProvider()),
        ChangeNotifierProvider(create: (_) => AdminApiProvider()),  // KRİTİK EKSİK!
        ChangeNotifierProvider(create: (_) => WaitingTimeProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey, // GLOBAL FEEDBACK İÇİN!
            title: 'FunBreak Vale',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              primarySwatch: Colors.amber,
              primaryColor: const Color(0xFFFFD700),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFFFD700),
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Color(0xFFFFD700),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFFD700)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFD700),
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFFFFD700),
                secondary: const Color(0xFFFFD700),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              primarySwatch: Colors.amber,
              primaryColor: const Color(0xFFFFD700),
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Color(0xFFFFD700),
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.black,
                selectedItemColor: Color(0xFFFFD700),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.grey[900],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFD700),
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFFFFD700),
                secondary: const Color(0xFFFFD700),
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: languageProvider.currentLocale,
            home: const SplashScreen(), // NORMAL SPLASH - PERSİSTENCE KONTROL EKLE!
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
  
  // BİLDİRİM ÖNEMİ DIALOG'U
  Future<void> _showNotificationImportanceDialog(int attempt) async {
    print('📱 MÜŞTERİ: Bildirim önemi dialog gösteriliyor - Deneme #$attempt');
    await Future.delayed(Duration(milliseconds: 1000));
  }

  // İZİN DIALOG'U
  Future<void> _showPermissionDialog() async {
    print('⚙️ MÜŞTERİ: İzin ayarları dialog gösteriliyor');
    await openAppSettings();
  }
  
  // PERSİSTENCE KONTROL SPLASH SCREEN'DE YAPILACAK!
}