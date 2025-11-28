import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  
  // YASAL SÖZLEŞME ONAYLARI - ZORUNLU!
  bool _kvkkAccepted = false;
  bool _userAgreementAccepted = false;
  bool _commercialCommunicationAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Kaydı'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Müşteri Kaydı',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vale hizmeti için kayıt olun',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  enableSuggestions: true,
                  autocorrect: true,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad soyad gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.text,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telefon gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre Tekrar',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre tekrarı gerekli';
                    }
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // YASAL SÖZLEŞMELER - ZORUNLU!
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gavel, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Yasal Sözleşmeler',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // 1. KVKK AYDINLATMA METNİ - ZORUNLU!
                      CheckboxListTile(
                        value: _kvkkAccepted,
                        onChanged: (value) => setState(() => _kvkkAccepted = value ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'KVKK Aydınlatma Metni',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showKVKKDialog(),
                              ),
                              const TextSpan(text: '\'ni okudum, kabul ediyorum. '),
                              const TextSpan(
                                text: '*ZORUNLU',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 2. KULLANICI SÖZLEŞMESİ - ZORUNLU!
                      CheckboxListTile(
                        value: _userAgreementAccepted,
                        onChanged: (value) => setState(() => _userAgreementAccepted = value ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Kullanıcı Sözleşmesi',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showUserAgreementDialog(),
                              ),
                              const TextSpan(text: '\'ni okudum, kabul ediyorum. '),
                              const TextSpan(
                                text: '*ZORUNLU',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 3. TİCARİ ELEKTRONİK İLETİ İZNİ - OPSİYONEL!
                      CheckboxListTile(
                        value: _commercialCommunicationAccepted,
                        onChanged: (value) => setState(() => _commercialCommunicationAccepted = value ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Ticari Elektronik İleti Onayı',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showCommercialDialog(),
                              ),
                              const TextSpan(text: '\'ni kabul ediyorum. '),
                              const TextSpan(
                                text: '(Opsiyonel - Kampanya bildirimleri)',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Register Button - ZORUNLU SÖZLEŞMELER KABUL EDİLMEDEN AKTİF OLMAZ!
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_kvkkAccepted || !_userAgreementAccepted) ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_kvkkAccepted && _userAgreementAccepted) 
                          ? const Color(0xFFFFD700) 
                          : Colors.grey[400],
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            (_kvkkAccepted && _userAgreementAccepted) 
                                ? 'Kayıt Ol' 
                                : 'Zorunlu Sözleşmeleri Kabul Edin',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten hesabınız var mı? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(color: Color(0xFFFFD700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // YASAL SÖZLEŞME KONTROL - ZORUNLU!
    if (!_kvkkAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ KVKK Aydınlatma Metni\'ni kabul etmelisiniz!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (!_userAgreementAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Kullanıcı Sözleşmesi\'ni kabul etmelisiniz!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (success) {
        // KAYIT BAŞARILI - YASAL LOG KAYDET!
        // Customer ID'yi AuthProvider'dan al - register() SUCCESS ise _customerId set edilmiştir!
        final customerId = int.tryParse(authProvider.customerId ?? '0') ?? 0;
        
        print('📋 YASAL LOG: Kayıt başarılı, Customer ID: $customerId');
        print('📊 YASAL LOG DEBUG:');
        print('   authProvider.customerId: ${authProvider.customerId}');
        print('   _kvkkAccepted: $_kvkkAccepted');
        print('   _userAgreementAccepted: $_userAgreementAccepted');
        print('   _commercialCommunicationAccepted: $_commercialCommunicationAccepted');
        
        if (customerId > 0) {
          await _logLegalConsents(customerId);
          print('✅ YASAL LOG: Sözleşmeler loglandı - Customer ID: $customerId');
        } else {
          print('❌ YASAL LOG: Customer ID BULUNAMADI - authProvider.customerId DOLU DEĞİL!');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kayıt başarılı! Giriş yapabilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Kayıt başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // YASAL ONAYLARI LOGLA - MAHKEME DELİLİ!
  Future<void> _logLegalConsents(int customerId) async {
    try {
      // Device bilgilerini topla
      final deviceInfo = await _collectDeviceInfo();
      
      // Konum bilgisi topla (izin varsa)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        print('⚠️ Konum alınamadı: $e');
      }
      
      // Her sözleşme için ayrı log kaydet
      final consentsToLog = [
        if (_kvkkAccepted) {
          'type': 'kvkk',
          'text': _getKVKKText(),
          'summary': 'KVKK Aydınlatma Metni - Kişisel verilerin işlenmesi',
        },
        if (_userAgreementAccepted) {
          'type': 'user_agreement',
          'text': _getUserAgreementText(),
          'summary': 'Kullanıcı Sözleşmesi - Hizmet kullanım şartları',
        },
        if (_commercialCommunicationAccepted) {
          'type': 'commercial_communication',
          'text': _getCommercialText(),
          'summary': 'Ticari Elektronik İleti İzni - Kampanya ve duyurular',
        },
      ];
      
      for (var consent in consentsToLog) {
        print('📝 SÖZLEŞME LOG API ÇAĞRILIYOR:');
        print('   Type: ${consent['type']}');
        print('   User ID: $customerId');
        print('   Text Length: ${(consent['text'] as String).length}');
        
        final response = await http.post(
          Uri.parse('https://admin.funbreakvale.com/api/log_legal_consent.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': customerId,
            'user_type': 'customer',
            'consent_type': consent['type'],
            'consent_text': consent['text'],
            'consent_summary': consent['summary'],
            'consent_version': '1.0',
            'ip_address': deviceInfo['ip_address'],
            'user_agent': deviceInfo['user_agent'],
            'device_fingerprint': deviceInfo['device_fingerprint'],
            'platform': deviceInfo['platform'],
            'os_version': deviceInfo['os_version'],
            'app_version': deviceInfo['app_version'],
            'device_model': deviceInfo['device_model'],
            'device_manufacturer': deviceInfo['device_manufacturer'],
            'latitude': position?.latitude,
            'longitude': position?.longitude,
            'location_accuracy': position?.accuracy,
            'location_timestamp': position != null ? DateTime.now().toIso8601String() : null,
            'language': 'tr',
          }),
        ).timeout(const Duration(seconds: 10));
        
        print('📡 SÖZLEŞME LOG API RESPONSE:');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
        
        final apiData = jsonDecode(response.body);
        if (apiData['success'] == true) {
          print('✅ Sözleşme ${consent['type']} loglandı - Log ID: ${apiData['log_id']}');
        } else {
          print('❌ Sözleşme ${consent['type']} log hatası: ${apiData['message']}');
        }
      }
      
      print('✅ ${consentsToLog.length} sözleşme YASAL OLARAK loglandı - Mahkeme delili kaydedildi!');
    } catch (e) {
      print('⚠️ Yasal log hatası: $e (Kayıt tamamlandı ama log kaydedilemedi)');
    }
  }
  
  // CİHAZ BİLGİLERİNİ TOPLA - BASİT VERSİYON (device_info_plus OLMADAN)
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    // Platform bilgisi - Flutter yerleşik
    final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
    
    // Benzersiz fingerprint - timestamp bazlı
    final fingerprint = DateTime.now().millisecondsSinceEpoch.toString() + 
                       '_' + 
                       (_emailController.text.hashCode.toString());
    
    return {
      'platform': platform,
      'os_version': Platform.operatingSystemVersion, // Android 13 / iOS 17 gibi
      'app_version': '1.0.0',
      'device_model': 'auto', // Backend'den tespit edilebilir
      'device_manufacturer': 'auto',
      'device_fingerprint': fingerprint,
      'user_agent': 'FunBreak Customer App/$platform ${Platform.operatingSystemVersion}',
      'ip_address': 'auto', // Backend otomatik alacak
    };
  }

  // SÖZLEŞME DIALOG'LARI
  void _showKVKKDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KVKK Aydınlatma Metni'),
        content: SingleChildScrollView(
          child: Text(_getKVKKText(), style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _kvkkAccepted = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            child: const Text('Kabul Ediyorum', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  
  void _showUserAgreementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Sözleşmesi'),
        content: SingleChildScrollView(
          child: Text(_getUserAgreementText(), style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _userAgreementAccepted = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            child: const Text('Kabul Ediyorum', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  
  void _showCommercialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticari Elektronik İleti İzni'),
        content: SingleChildScrollView(
          child: Text(_getCommercialText(), style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _commercialCommunicationAccepted = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            child: const Text('Kabul Ediyorum', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  
  // SÖZLEŞME METİNLERİ - YASAL GEÇERLİLİK İÇİN TAM METİN!
  String _getKVKKText() {
    // Kullanıcı bilgileri otomatik doldurulacak (backend log_legal_consent.php'de)
    return '''FUNBREAK VALE - YOLCULAR İÇİN KİŞİSEL VERİLERİN İŞLENMESİ VE KORUNMASINA YÖNELİK AYDINLATMA METNİ

VERİ SORUMLUSU BİLGİLERİ

Ticaret Ünvanı    : FUNBREAK GLOBAL TEKNOLOJİ LİMİTED ŞİRKETİ
Mersis No         : 0388195898700001
Ticaret Sicil No  : 1105910
Adres             : Armağanevler Mah. Ortanca Sk. No: 69 İç Kapı No: 22 Ümraniye/İstanbul
Telefon           : 0533 448 82 53
E-posta           : info@funbreakvale.com
Web Sitesi        : www.funbreakvale.com

════════════════════════════════════════════════════════════════════════════════

GİRİŞ

6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, FunBreak Vale olarak kişisel verilerinizin hangi amaçla işleneceğini, kimlere aktarılacağını, toplama yöntemini ve haklarınızı aşağıda açıklamaktayız.

════════════════════════════════════════════════════════════════════════════════

A. KİŞİSEL VERİ KATEGORİLERİ VE İŞLENME AMAÇLARI

1. KİMLİK BİLGİSİ
   • Ad, Soyad, T.C. Kimlik No, Doğum Tarihi, Profil Fotoğrafı
   • Amaç: Kimlik tespiti, platform güvenliği, vale eşleştirme

2. İLETİŞİM BİLGİSİ
   • Telefon, E-posta, İkametgah, Kayıtlı Adresler
   • Amaç: İletişim, bilgilendirme, tebligat, acil durum

3. FİNANSAL BİLGİ
   • Kart bilgisi (ilk 6+son 2 hane), IBAN, Ödeme geçmişi, İndirim kodları
   • Amaç: Ödeme tahsili, fatura düzenleme, muhasebe

4. YOLCULUK VERİLERİ
   • Alış/Varış noktaları, Rota, GPS konumu, Mesafe, Süre, Bekleme
   • Amaç: Hizmet sunumu, ücretlendirme, takip, güvenlik

5. ARAÇ BİLGİSİ
   • Plaka, Marka/Model, Renk, Yıl, Ruhsat
   • Amaç: Vale'nin doğru aracı tanıması, güvenlik

6. DEĞERLENDİRME BİLGİSİ
   • Puanlar, Yorumlar, Şikayetler
   • Amaç: Hizmet kalitesi, performans değerlendirme

7. LOKASYON BİLGİSİ
   • Canlı GPS konumu (vale çağırırken), Kayıtlı adresler
   • Amaç: Vale eşleştirme, mesafe hesaplama
   • NOT: Yolculuk sırasında Vale'nin konumu takip edilir, Yolcu'nun değil

8. CİHAZ BİLGİSİ
   • Device ID, İşletim sistemi, IP adresi, Tarayıcı
   • Amaç: Teknik destek, güvenlik, uygulama performansı

9. MESAJLAŞMA KAYITLARI
   • Vale ile mesajlar, Destek talepleri, Şikayetler, Köprü arama kayıtları
   • Amaç: Hizmet kalitesi, uyuşmazlık çözümü, delil

10. ÇEREZ VERİLERİ
    • Zorunlu/Fonksiyonel/Analitik/Reklam çerezleri
    • Amaç: Uygulama işlevselliği, kullanıcı deneyimi, pazarlama

════════════════════════════════════════════════════════════════════════════════

B. VERİLERİN TOPLANMA YÖNTEMİ

• Kayıt/Üyelik formları
• Mobil uygulama kullanımı (GPS, mesajlaşma, işlemler)
• Web sitesi (form, çerez)
• Sistem kayıtları (sunucu log, API)
• Müşteri hizmetleri (telefon, e-posta, canlı destek)
• Üçüncü taraf entegrasyonlar (ödeme, SMS, harita)

════════════════════════════════════════════════════════════════════════════════

C. VERİLERİN AKTARILMASI

1. VALE'LERE: Ad-Soyad, Profil Fotoğrafı, Telefon (gizli), Adresler, Puan
2. GRUP ŞİRKETLERİ: Tüm veriler (ortak hizmet, teknik destek, raporlama)
3. HİZMET SAĞLAYICILARA: AWS, SMS, Ödeme, Google Maps, NetGSM, Analytics
4. HUKUK MÜŞAVİRLERİ: Yasal süreç gerektiren veriler
5. KAMU KURUMLAR INA: Emniyet, Mahkeme, Vergi Dairesi (kanuni yükümlülük)
6. YURT DIŞINA: Bulut sunucu, analitik hizmetler (açık rıza ile)

════════════════════════════════════════════════════════════════════════════════

D. HAKLARINIZ (KVKK Madde 11)

• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• İşlenmişse bilgi talep etme
• İşlenme amacını ve uygunluğunu öğrenme
• Aktarıldığı üçüncü kişileri bilme
• Eksik/yanlış verilerin düzeltilmesini isteme
• Verilerin silinmesini/yok edilmesini isteme
• İşlemlerin üçüncü kişilere bildirilmesini isteme
• Otomatik sistemlerle analiz sonucuna itiraz etme
• Kanuna aykırı işlemeden zarar görürse tazminat talep etme

BAŞVURU YÖNTEMİ:
• Yazılı: Armağanevler Mah. Ortanca Sk. No:69/22 Ümraniye/İstanbul
• E-posta: info@funbreakvale.com (güvenli e-imza ile)
• Web: www.funbreakvale.com/kvkk-basvuru
• Mobil: Ayarlar > KVKK > Başvuru Yap

Başvurular 30 gün içinde cevaplanır.

════════════════════════════════════════════════════════════════════════════════

E. SAKLAMA SÜRESİ

• Kimlik/İletişim: Üyelik + 10 yıl
• Finansal: 10 yıl (Vergi Usul Kanunu)
• Yolculuk Kayıtları: 5 yıl
• GPS/Konum: 2 yıl
• Mesajlaşma: 2 yıl
• Değerlendirme: 3 yıl
• Çerezler: 6 ay - 2 yıl

════════════════════════════════════════════════════════════════════════════════

F. VERİ GÜVENLİĞİ

• SSL/TLS şifreleme (256-bit)
• Güvenlik duvarı, yedekleme
• Erişim logları, şifreli saklama
• PCI DSS uyum, 3D Secure
• Personel eğitimi, gizlilik sözleşmeleri

════════════════════════════════════════════════════════════════════════════════

İLETİŞİM

FUNBREAK GLOBAL TEKNOLOJI LIMITED SIRKETI
Armağanevler Mah. Ortanca Sk. No: 69/22 Ümraniye/İstanbul
Tel: 0533 448 82 53 | E-posta: info@funbreakvale.com
Web: www.funbreakvale.com

════════════════════════════════════════════════════════════════════════════════

AÇIK RIZA BEYANI

Bu Aydınlatma Metni'ni okuyup anladığımı, özgür irademle kabul ettiğimi ve kişisel verilerimin işlenmesine ve yurt dışına aktarılmasına izin verdiğimi beyan ederim.

YOLCU BİLGİLERİ (Otomatik Doldurulacak):
• Ad Soyad: [Sisteme kayıtlı bilgi]
• Telefon: [Sisteme kayıtlı bilgi]
• E-posta: [Sisteme kayıtlı bilgi]
• IP Adresi: [Otomatik]
• Cihaz ID: [Otomatik]
• GPS Konum: [Otomatik]
• Tarih/Saat: [Otomatik]

Son Güncelleme: 28 Kasım 2025 | Versiyon: 2.0''';
  }
  
  String _getUserAgreementText() {
    // Kullanıcı bilgileri otomatik doldurulacak (backend log_legal_consent.php'de)
    return '''FUNBREAK VALE - YOLCU (MÜŞTERİ) KULLANIM KOŞULLARI SÖZLEŞMESİ

════════════════════════════════════════════════════════════════════════════════

1. TARAFLAR

İşbu Sözleşme, Armağanevler Mah. Ortanca Sk. No: 69 İç Kapı No: 22 Ümraniye/İstanbul adresinde mukim, 0388195898700001 Mersis numaralı FUNBREAK GLOBAL TEKNOLOJI LIMITED SIRKETI ("FunBreak Vale") ile mobil uygulama üzerinden özel şoför ve vale hizmeti alan ("Yolcu" veya "Müşteri") arasındadır.

════════════════════════════════════════════════════════════════════════════════

2. SÖZLEŞMENİN AMACI VE KONUSU

2.1. Bu Sözleşme, Yolcu için özel şoför ve vale bulma hizmetini sunan FunBreak Vale ile Yolcu arasındaki mobil uygulama kullanımına ilişkin hak ve yükümlülükleri belirtir.

2.2. FunBreak Vale, Yolcu ile Vale (sürücü) arasında aracılık hizmeti sunan bir teknoloji platformudur. FunBreak Vale, Yolcu ile herhangi bir taşıma sözleşmesi yapmamakta olup, aracılık hizmeti sağlamaktadır.

════════════════════════════════════════════════════════════════════════════════

3. KULLANIM KOŞULLARI

3.1. GENEL ŞARTLAR
• Yolcu, mobil uygulama üzerinden kullanıcı adı ve şifresi ile hizmet alabilir
• Vale (sürücü), algoritma ile belirlenir (konum, yoğunluk, performans)
• Vale, Yolcunun aracı ile Yolcuyu belirttiği lokasyona transfer eder
• FunBreak Vale, tüm platform haklarını saklı tutar
• Sözleşme şartları önceden bildirim olmaksızın değiştirilebilir

3.2. GÜVENLİK VE GİZLİLİK
• Yolcu, tersine mühendislik veya kaynak kodu elde etme girişiminde bulunmayacaktır
• Genel ahlaka, kanuna aykırı, hakaret içeren, müstehcen içerik üretilmeyecektir
• İhlal halinde hesap askıya alınabilir veya silinebilir, yasal süreç başlatılabilir

3.3. KAYIT ŞARTLARI
• En az 18 yaşında ve medeni hakları kullanma ehliyetine sahip olmak
• Doğru, kesin ve güncel bilgi vermek
• Bilgilerin eksik/yanlış olması halinde kayıt dondurulabilir veya silinebilir
• Gerekli bilgiler: Ad-Soyad, T.C. Kimlik No, Telefon, E-posta, Ödeme Bilgisi

════════════════════════════════════════════════════════════════════════════════

4. YOLCUNUN HAK VE YÜKÜMLÜLÜKLERİ

4.1. HİZMET ALMA SÜRECİ
a) Yolcu, mobil uygulama üzerinden alış ve varış lokasyonunu seçerek Vale çağırır
b) Sistem tahmini fiyat gösterir (bekleme ve mesafe değişikliği ek ücret doğurabilir)
c) Vale bulunduğunda bildirim gelir, Vale bilgileri gösterilir
d) Yolcu, harita üzerinden Vale'yi canlı takip edebilir (real-time GPS tracking)
e) Yolcu, köprü arama sistemi ile iletişime geçebilir (kişisel numara paylaşılmaz)
f) Yolcu, sistem içi mesajlaşma özelliğini kullanabilir
g) Yolculuk rotası ve bekleme noktaları otomatik kaydedilir
h) Ödeme yapılana kadar yeni yolculuk başlatılamaz
i) Yolcu, yolculuk sonunda Vale'yi 1-5 yıldız puanlayabilir

4.2. YASAK FAALİYETLER
• Suç unsuru oluşturan eylemler
• Virüs, Truva atı, zararlı yazılım
• Mahremiyet ihlali, iftira, müstehcen içerik
• Telif hakkı ve ticari marka ihlalleri
• Sistem dışı Vale ile iletişim (her ihlal için 100.000,00 TL cezai şart)

4.3. ARAÇ VE EŞYA SORUMLULUĞU
• Araç içindeki kişisel eşyalardan Yolcu sorumludur
• Vale'ye bildirilmeyen değerli eşyalardan Vale sorumlu değildir
• Aracın teknik durumu ve bakımından Yolcu sorumludur
• Güncel trafik sigortası Yolcunun sorumluluğundadır
• Araçta yasak madde veya yasa dışı eşya bulunmayacaktır

════════════════════════════════════════════════════════════════════════════════

5. FİYATLANDIRMA VE ÖDEME

5.1. ÜCRET POLİTİKASI
• Mesafe bazlı fiyatlandırma (0-5 km, 5-10 km, vb.)
• Bekleme ücreti: İlk 15 dakika ücretsiz, sonrası 200 TL/15 dakika
• Saatlik paketler: 0-4 saat, 4-8 saat, 8-12 saat
• Tahmini fiyat yolculuk öncesinde gösterilir
• Gerçek fiyat, yolculuk sonunda hesaplanır

5.2. ÖDEME YÖNTEMLERİ
• Kredi/Banka Kartı (3D Secure)
• Havale/EFT
• Kayıtlı Kart ile ödeme

════════════════════════════════════════════════════════════════════════════════

6. İPTAL VE İADE

• Vale atanmadan iptal: ÜCRETSİZ
• Vale atandıktan sonra (45 dakikadan fazla kala): ÜCRETSİZ
• Vale atandıktan sonra (45 dakikadan az kala): Sabit iptal ücreti (1.500 TL)
• Yolculuk başladıktan sonra: Tam ücret tahsil edilir
• Sistemden kaynaklı iptal: ÜCRETSİZ

════════════════════════════════════════════════════════════════════════════════

7. FUNBREAK VALE'NİN HAK VE YÜKÜMLÜLÜKLERİ

• Vale performansını izleme ve değerlendirme hakkı
• Yolculukları inceleme hakkı (güvenlik ve kalite)
• Yolcu şikayetlerini değerlendirme ve gerekirse Vale ile iş ilişkisini sonlandırma
• Platform özelliklerini, yapısını, işlevlerini değiştirme hakkı
• Teknik sorunlar ve üçüncü kişi eylemlerinden sorumluluk kabul etmeme

════════════════════════════════════════════════════════════════════════════════

8. GİZLİLİK VE REKABET YASAĞI

• Sözleşme kapsamında öğrenilen gizli bilgiler üçüncü kişilerle paylaşılamaz
• Ticari sırlar, iş planları, kullanıcı bilgileri gizli tutulmalıdır
• İhlal halinde 100.000,00 TL cezai şart uygulanır

════════════════════════════════════════════════════════════════════════════════

9. KİŞİSEL VERİLERİN KORUNMASI

Yolcu, KVKK Aydınlatma Metni kapsamında kişisel verilerinin:
• Hukuka ve dürüstlük kurallarına uygun işleneceğini
• Belirli, açık ve meşru amaçlar için kullanılacağını
• Ölçülü ve sınırlı işleneceğini
• Gerekli süre kadar muhafaza edileceğini
kabul eder.

════════════════════════════════════════════════════════════════════════════════

10. SÖZLEŞME SÜRESİ VE FESİH

• Sözleşme süresizdir
• FunBreak Vale, önceden bildirmeksizin fesih hakkına sahiptir
• Yolcu, üyeliğini tek taraflı iptal edebilir (borçlar geçerli kalır)
• 90 gün giriş yapmayan üyelerin hakları düşer

FESİH SEBEPLERİ:
a) Sahte bilgi/belge sunulması
b) 30 gün içinde ödenmeyen borç
c) Vale'ye karşı suç teşkil eden eylem
d) Mükerrer şikayet
e) Gizlilik kuralı ihlali
f) Yasaklı faaliyetler

════════════════════════════════════════════════════════════════════════════════

11. MÜCBİR SEBEPLER

FunBreak Vale, kontrolü dışındaki sebeplerden (savaş, terör, deprem, yangın, sel, siber saldırı, server çökmesi, yazılım hatası) dolayı yükümlülüklerini yerine getirememekten sorumlu tutulamaz.

════════════════════════════════════════════════════════════════════════════════

12. DELİL SÖZLEŞMESİ

• FunBreak Vale'nin kayıtları (defter, e-posta, mesaj, SMS, veritabanı, sistem log) 6100 sayılı HMK uyarınca delil kabul edilir
• GPS konum kayıtları, rota takip verileri, bekleme noktaları delil niteliğindedir
• Yolcu bu kayıtlara itiraz etmeyeceğini kabul eder

════════════════════════════════════════════════════════════════════════════════

13. YETKİLİ MAHKEME

İşbu Sözleşmeden doğan uyuşmazlıklarda İstanbul (Çağlayan) Mahkemeleri ve İcra Müdürlükleri yetkilidir.

════════════════════════════════════════════════════════════════════════════════

14. SÖZLEŞME EKLERİ

Yolcu, bu sözleşmeyi onaylamakla aşağıdaki ekleri de kabul eder:
a. Kişisel Verilerin Korunmasına Dair Aydınlatma Metni
b. Açık Rıza Beyanı
c. Ticari Elektronik İleti Onayı
d. Gizlilik Politikası
e. İptal ve İade Koşulları

════════════════════════════════════════════════════════════════════════════════

15. YÜRÜRLÜK

• Yolcu, bu sözleşmeyi okuduğunu, anladığını ve kabul ettiğini beyan eder
• Sözleşme, elektronik onay ile yürürlüğe girer
• Sözleşme, Türkiye Cumhuriyeti yasalarına tabidir

════════════════════════════════════════════════════════════════════════════════

ŞİRKET BİLGİLERİ

FUNBREAK GLOBAL TEKNOLOJI LIMITED SIRKETI
Mersis No: 0388195898700001 | Ticaret Sicil: 1105910
Adres: Armağanevler Mah. Ortanca Sk. No: 69/22 Ümraniye/İstanbul
Tel: 0533 448 82 53 | E-posta: info@funbreakvale.com
Web: www.funbreakvale.com

════════════════════════════════════════════════════════════════════════════════

YOLCU (MÜŞTERİ) BİLGİLERİ (Otomatik Doldurulacak):

• Ad Soyad: [Sisteme kayıtlı bilgi]
• T.C. Kimlik No: [Sisteme kayıtlı bilgi]
• Telefon: [Sisteme kayıtlı bilgi]
• E-posta: [Sisteme kayıtlı bilgi]
• IP Adresi: [Otomatik]
• Cihaz ID: [Otomatik]
• GPS Konum: [Otomatik]
• Tarih/Saat: [Otomatik]

Son Güncelleme: 28 Kasım 2025 | Versiyon: 2.0''';
  }
  
  String _getCommercialText() {
    // Kullanıcı bilgileri otomatik doldurulacak (backend log_legal_consent.php'de)
    return '''FUNBREAK VALE - TİCARİ ELEKTRONİK İLETİ ONAYI

════════════════════════════════════════════════════════════════════════════════

YASAL DAYANAK

6698 sayılı Kişisel Verilerin Korunması Kanunu, 6563 Sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun ve 15 Temmuz 2015 tarihli Resmi Gazete'de yayınlanan 29417 sayılı Ticari İletişim ve Ticari Elektronik İletiler Hakkında Yönetmelik kapsamında FUNBREAK GLOBAL TEKNOLOJI LIMITED SIRKETI olarak ticari elektronik ileti onayınızı almak istiyoruz.

════════════════════════════════════════════════════════════════════════════════

TİCARİ ELEKTRONİK İLETİ NEDİR?

Telefon, faks, e-posta, SMS, anlık bildirimler (push notification) gibi vasıtalarla elektronik ortamda gerçekleştirilen ve ticari amaçlarla gönderilen veri, ses ve görüntü içerikli iletilerdir.

════════════════════════════════════════════════════════════════════════════════

GÖNDERİLEBİLECEK İLETİ TÜRLERİ

1. KAMPANYA VE PROMOSYON
   • İndirim kodları ve kuponlar
   • Özel kampanyalar ve fırsatlar
   • Sezonluk promosyonlar
   • Sadakat programı avantajları

2. BİLGİLENDİRME
   • Yeni özellik duyuruları
   • Uygulama güncellemeleri
   • Hizmet geliştirmeleri
   • Fiyat değişiklikleri

3. KUTLAMA VE TEMENNİ
   • Resmi bayramlar (29 Ekim, 23 Nisan, 19 Mayıs, 30 Ağustos)
   • Dini bayramlar (Ramazan, Kurban)
   • Yeni yıl kutlamaları
   • Doğum günü kutlamaları

4. HATIRLATMA
   • Rezervasyon hatırlatmaları
   • Ödeme hatırlatmaları
   • Hesap bildirimleri

5. KİŞİSELLEŞTİRİLMİŞ ÖNERİLER
   • Kullanım alışkanlıklarına göre öneriler
   • Size özel fırsatlar
   • Sık kullanılan güzergahlar için teklifler

════════════════════════════════════════════════════════════════════════════════

RED VE GERİ ÇEKME HAKKI

Dilediğiniz zaman, hiçbir gerekçe belirtmeksizin ticari elektronik iletileri almayı ÜCRETSİZ olarak reddedebilirsiniz:

1. Mobil Uygulama: Ayarlar > Bildirim Tercihleri > Ticari İletiler (Kapat)
2. E-posta: Gelen iletilerdeki "Abonelikten Çık" linki
3. SMS: İçerikteki "RET" veya "IPTAL" kodunu gönderme
4. Müşteri Hizmetleri: info@funbreakvale.com veya 0533 448 82 53

Onay geri çekme talebi en geç 3 iş günü içinde işleme alınır.

════════════════════════════════════════════════════════════════════════════════

ONAY METNİ

6698 sayılı KVKK, 6563 sayılı Kanun ve ilgili yönetmelikler gereğince gerekli bilgilendirmenin tarafıma yapıldığını, işbu metni okuyup anladığımı kabul ediyorum.

FunBreak Vale web sayfası ve mobil uygulama kayıtları, dijital pazarlama, sosyal medya, iş ortakları ve bunlarla sınırlı olmamak üzere her türlü kanallar aracılığıyla; telefon, çağrı merkezleri, e-posta, SMS, push notification gibi vasıtalarla ticari amaçlı veri, ses ve görüntü içerikli iletilerin gönderilmesine muvafakat ediyorum.

════════════════════════════════════════════════════════════════════════════════

ÖNEMLİ NOTLAR

⚠️ Bu onay OPSİYONELDİR. Onay vermemeniz FunBreak Vale hizmetlerinden yararlanmanızı engellemez.

⚠️ İŞLEMSEL BİLDİRİMLER (yolculuk durumu, ödeme onayı, güvenlik uyarıları) bu onaydan bağımsızdır ve her durumda gönderilir.

════════════════════════════════════════════════════════════════════════════════

ŞİRKET BİLGİLERİ

FUNBREAK GLOBAL TEKNOLOJI LIMITED SIRKETI
Mersis No: 0388195898700001 | Ticaret Sicil: 1105910
Adres: Armağanevler Mah. Ortanca Sk. No: 69/22 Ümraniye/İstanbul
Tel: 0533 448 82 53 | E-posta: info@funbreakvale.com
Web: www.funbreakvale.com

════════════════════════════════════════════════════════════════════════════════

YOLCU (MÜŞTERİ) BİLGİLERİ (Otomatik Doldurulacak):

• Ad Soyad: [Sisteme kayıtlı bilgi]
• Telefon: [Sisteme kayıtlı bilgi]
• E-posta: [Sisteme kayıtlı bilgi]
• IP Adresi: [Otomatik]
• Cihaz ID: [Otomatik]
• GPS Konum: [Otomatik]
• Tarih/Saat: [Otomatik]

Son Güncelleme: 28 Kasım 2025 | Versiyon: 2.0''';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
 