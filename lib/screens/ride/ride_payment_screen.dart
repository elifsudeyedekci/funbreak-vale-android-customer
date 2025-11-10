import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard için!
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/admin_api_provider.dart';

// MÜŞTERİ ÖDEME VE PUANLAMA EKRANI!
class RidePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> rideDetails;
  final Map<String, dynamic> rideStatus;
  
  const RidePaymentScreen({
    Key? key, 
    required this.rideDetails,
    required this.rideStatus,
  }) : super(key: key);
  
  @override
  State<RidePaymentScreen> createState() => _RidePaymentScreenState();
}

class _RidePaymentScreenState extends State<RidePaymentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  
  // PUANLAMA KALDIRILDI - ANA EKRANDA YAPILACAK!
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;
  
  // Trip calculations - HEPSİ DEFAULT VALUE İLE BAŞLASIN!
  double _basePrice = 0.0;
  double _waitingFee = 0.0;
  double _totalPrice = 0.0;
  int _waitingMinutes = 0;
  double _distance = 0.0;
  
  // Panel pricing settings
  double _waitingFeePerInterval = 200.0; // Varsayılan: Her 15 dakika ₺200
  int _waitingFreeMinutes = 15; // İlk 15 dakika ücretsiz
  int _waitingIntervalMinutes = 15; // 15 dakikalık aralıklar
  
  // ÖDEME YÖNTEMİ VE İNDİRİM KODU - ÖDEME EKRANINA EKLENDİ!
  String _selectedPaymentMethod = 'card'; // card, cash, havale_eft
  final TextEditingController _discountCodeController = TextEditingController();
  double _discountAmount = 0.0;
  bool _discountApplied = false;
  
  // SAATLİK PAKET BİLGİSİ
  String _hourlyPackageLabel = '';
  
  @override
  void initState() {
    super.initState();
    
    // ÖNCELİKLE ride status'tan verileri al
    _waitingMinutes = widget.rideStatus['waiting_minutes'] ?? 0;
    _distance = (widget.rideStatus['current_km'] as num?)?.toDouble() ?? 0.0;
    
    // BASE PRICE (bekleme hariç!) - Backend'den base_price_only gelecek
    final basePriceOnly = widget.rideDetails['base_price_only'] ?? widget.rideDetails['estimated_price'];
    if (basePriceOnly != null) {
      _basePrice = (basePriceOnly as num).toDouble();
    }
    
    _initializeAnimation();
    
    // Panel'den ayarları çek ve HESAPLA - async ama UI beklemeden gösterilsin
    _fetchPanelPricingAndCalculate();
    
    // İlk hesaplama (varsayılan değerlerle - panel gelince güncellenecek)
    _calculateTripDetails();
  }
  
  void _initializeAnimation() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    
    _animController.forward();
  }
  
  // YENİ: PANEL'DEN FİYATLANDIRMA AYARLARINI ÇEK VE HESAPLA!
  Future<void> _fetchPanelPricingAndCalculate() async {
    try {
      // Panel'den fiyatlandırma ayarlarını çek
      final response = await http.get(
        Uri.parse('https://admin.funbreakvale.com/api/get_pricing_settings.php'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['pricing'] != null) {
          final pricing = data['pricing'];
          
          setState(() {
            _waitingFeePerInterval = double.tryParse(pricing['waiting_fee_per_interval']?.toString() ?? '200') ?? 200.0;
            _waitingFreeMinutes = int.tryParse(pricing['waiting_fee_free_minutes']?.toString() ?? '15') ?? 15;
            _waitingIntervalMinutes = int.tryParse(pricing['waiting_interval_minutes']?.toString() ?? '15') ?? 15;
          });
          
          print('✅ MÜŞTERİ ÖDEME: Panel ayarları çekildi - İlk $_waitingFreeMinutes dk ücretsiz, sonra her $_waitingIntervalMinutes dk ₺$_waitingFeePerInterval');
        }
      }
    } catch (e) {
      print('⚠️ MÜŞTERİ ÖDEME: Panel ayar çekme hatası, varsayılan kullanılıyor: $e');
      // Varsayılan değerler zaten set edildi
    }
    
    // Hesaplamayı yap
    _calculateTripDetails();
  }
  
  void _calculateTripDetails() {
    // ✅ estimated_price (bekleme dahil olabilir), waiting hesapla, base = estimated - waiting
    final estimatedPrice = double.tryParse(widget.rideDetails['estimated_price']?.toString() ?? '0') ?? 0.0;
    _waitingMinutes = widget.rideStatus['waiting_minutes'] ?? 0;
    _distance = double.tryParse(widget.rideStatus['total_distance']?.toString() ?? '0') ?? 
                (estimatedPrice / 200 * 10); // Tahmini km
    
    // SAATLİK PAKET KONTROLÜ - GECELİKTE BEKLEME YOK!
    final serviceType = widget.rideStatus['service_type'] ?? widget.rideDetails['service_type'] ?? 'vale';
    final isHourlyPackage = (serviceType == 'hourly');
    
    // SAATLİK PAKET BİLGİSİNİ BELİRLE
    if (isHourlyPackage) {
      final rideDurationHours = widget.rideStatus['ride_duration_hours'];
      if (rideDurationHours != null) {
        final hours = double.tryParse(rideDurationHours.toString()) ?? 0.0;
        final estimatedPrice = double.tryParse(widget.rideDetails['estimated_price']?.toString() ?? '0') ?? 0.0;
        
        // Fiyata göre paket belirle
        if (estimatedPrice == 3000) {
          _hourlyPackageLabel = '0-4 Saat Paketi';
        } else if (estimatedPrice == 4500) {
          _hourlyPackageLabel = '4-8 Saat Paketi';
        } else if (estimatedPrice == 6000) {
          _hourlyPackageLabel = '8-12 Saat Paketi';
        } else if (estimatedPrice == 18000) {
          _hourlyPackageLabel = '12-20 Saat Paketi';
        } else if (estimatedPrice == 26000) {
          _hourlyPackageLabel = '20-50 Saat Paketi';
        } else {
          _hourlyPackageLabel = 'Saatlik Paket (${hours.toStringAsFixed(1)} saat)';
        }
      } else {
        _hourlyPackageLabel = 'Saatlik Paket';
      }
    }
    
    // ✅ BEKLEME ÜCRETİNİ HESAPLA!
    _waitingFee = 0.0;
    if (!isHourlyPackage && _waitingMinutes > _waitingFreeMinutes) {
      final chargeableMinutes = _waitingMinutes - _waitingFreeMinutes;
      final intervals = (chargeableMinutes / _waitingIntervalMinutes).ceil();
      _waitingFee = intervals * _waitingFeePerInterval;
      print('💳 MÜŞTERİ ÖDEME: Bekleme ücreti - $_waitingMinutes dk (ücretsiz: $_waitingFreeMinutes dk) → $intervals aralık × ₺$_waitingFeePerInterval = ₺${_waitingFee.toStringAsFixed(2)}');
    } else if (isHourlyPackage) {
      _waitingFee = 0.0;
      print('📦 MÜŞTERİ ÖDEME: SAATLİK PAKET - Bekleme ücreti İPTAL!');
    }
    
    // ✅ BASE = estimated - waiting, TOTAL = estimated (bekleme zaten dahil!)
    _basePrice = estimatedPrice - _waitingFee;
    _totalPrice = estimatedPrice;
    
    print('💳 MÜŞTERİ ÖDEME: Base: ₺${_basePrice.toStringAsFixed(2)}, Bekleme: ₺${_waitingFee.toStringAsFixed(2)}, Mesafe: ${_distance.toStringAsFixed(1)}km, TOPLAM: ₺${_totalPrice.toStringAsFixed(2)}');
    
    // setState ile UI güncelle
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.white,
        title: const Text('💳 Ödeme ve Puanlama', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success header
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 60),
                    const SizedBox(height: 12),
                    const Text(
                      '🎉 YOLCULUK TAMAMLANDI!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hedefinize güvenle ulaştınız',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Trip summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗺️ Yolculuk Özeti',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSummaryRow('📍 Nereden', widget.rideDetails['pickup_address'] ?? ''),
                  const SizedBox(height: 8),
                  _buildSummaryRow('🎯 Nereye', widget.rideDetails['destination_address'] ?? ''),
                  const SizedBox(height: 8),
                  _buildSummaryRow('📏 Mesafe', '${_distance.toStringAsFixed(1)} km'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('⏱️ Süre', _getRideDuration()),
                  const SizedBox(height: 8),
                  _buildSummaryRow('🕐 Tamamlama', _getCompletionTime()),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💳 Ödeme Detayları',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildPaymentRow('🚗 Yolculuk Ücreti', '₺${_basePrice.toStringAsFixed(2)}'),
                  if (_waitingMinutes > _waitingFreeMinutes && _hourlyPackageLabel.isEmpty)
                    _buildPaymentRow('⏰ Bekleme Ücreti', '₺${_waitingFee.toStringAsFixed(2)} ($_waitingMinutes dk)', subtitle: 'İlk $_waitingFreeMinutes dk ücretsiz, sonrası her $_waitingIntervalMinutes dk ₺${_waitingFeePerInterval.toStringAsFixed(0)}'),
                  if (_waitingMinutes <= _waitingFreeMinutes && _waitingMinutes > 0 && _hourlyPackageLabel.isEmpty)
                    _buildPaymentRow('⏰ Bekleme (Ücretsiz)', '$_waitingMinutes dakika', isFree: true),
                  if (_hourlyPackageLabel.isNotEmpty)
                    _buildPaymentRow('📦 $_hourlyPackageLabel', 'Paket fiyatına dahil', subtitle: 'Saatlik pakette bekleme ücreti alınmaz'),
                  if (_discountApplied && _discountAmount > 0)
                    _buildPaymentRow('🎁 İndirim', '-₺${_discountAmount.toStringAsFixed(2)}', subtitle: 'Kod: ${_discountCodeController.text}'),
                  const Divider(thickness: 2),
                  _buildPaymentRow('TOPLAM', '₺${(_totalPrice - _discountAmount).toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ÖDEME YÖNTEMİ SEÇİMİ!
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💳 Ödeme Yöntemi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Kredi Kartı
                  RadioListTile<String>(
                    value: 'card',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                    title: const Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Kredi/Banka Kartı'),
                      ],
                    ),
                    subtitle: const Text('Anında öde', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  
                  // NAKİT SEÇENEĞİ KALDIRILDI!
                  
                  // Havale/EFT
                  RadioListTile<String>(
                    value: 'havale_eft',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                    title: const Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Havale/EFT'),
                      ],
                    ),
                    subtitle: const Text('Otomatik banka kontrolü', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  
                  // HAVALE SEÇİLDİYSE IBAN GÖSTER!
                  if (_selectedPaymentMethod == 'havale_eft') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                '🏦 Havale/EFT Bilgileri',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '⚠️ ÖNEMLİ UYARI:',
                            style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Havale/EFT gönderirken GÖNDERİCİ kısmında kayıtlı adınız ve soyadınız olmalıdır. Farklı bir isimden gönderilen ödemeler kabul edilmeyecektir!',
                            style: TextStyle(fontSize: 13, color: Colors.red, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Banka Hesap Bilgileri:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildIBANRow('Banka', 'Yapı Kredi Bankası'),
                          _buildIBANRow('Hesap Sahibi', 'FunBreak Vale Hizmetleri Ltd.'),
                          _buildIBANCopyRow('IBAN', 'TR33 0006 7010 0000 0079 2947 95'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ℹ️ Otomatik Kontrol Sistemi:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ödemenizi yaptıktan sonra sistem otomatik olarak banka hesabımızı kontrol edecek. Ödemeniz geldiğinde otomatik onaylanacaktır.',
                                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // İNDİRİM KODU!
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.discount, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        '🎁 İndirim Kodu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountCodeController,
                          decoration: InputDecoration(
                            hintText: 'İndirim kodunuz varsa girin',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.confirmation_number),
                            enabled: !_discountApplied,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _discountApplied ? null : _applyDiscountCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Uygula', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  
                  if (_discountApplied) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '✅ İndirim uygulandı: ₺${_discountAmount.toStringAsFixed(2)} indirim!',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentCompleted 
                    ? Colors.green[600] 
                    : const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isProcessingPayment 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('💳 Ödeme işleniyor...'),
                      ],
                    )
                  : _paymentCompleted
                    ? const Text(
                        '✅ ÖDEME TAMAMLANDI',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : Text(
                        '💳 ₺${_totalPrice.toStringAsFixed(2)} ÖDE',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentRow(String label, String value, {bool isTotal = false, bool isFree = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? const Color(0xFFFFD700) : Colors.black87,
                ),
              ),
              Text(
                isFree ? 'Ücretsiz' : value,
                style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  color: isTotal 
                    ? const Color(0xFFFFD700)
                    : isFree 
                      ? Colors.green[600]
                      : Colors.black87,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
  
  // İNDİRİM KODU UYGULA
  Future<void> _applyDiscountCode() async {
    final code = _discountCodeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Lütfen bir indirim kodu girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Backend'den indirim kodu doğrula
      final response = await http.post(
        Uri.parse('https://admin.funbreakvale.com/api/validate_discount_code.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'total_amount': _totalPrice,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['discount_amount'] != null) {
          setState(() {
            _discountAmount = double.tryParse(data['discount_amount'].toString()) ?? 0.0;
            _discountApplied = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ İndirim kodu uygulandı: ₺${_discountAmount.toStringAsFixed(2)} indirim!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Geçersiz indirim kodu');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ İndirim kodu hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // PUANLAMA FONKSİYONLARI KALDIRILDI!
  
  Future<void> _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });
    
    try {
      final adminApi = AdminApiProvider();
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('user_id') ?? '0';
      
      // 1. Ödeme işle
      final finalAmount = _totalPrice - _discountAmount; // İndirim düşülmüş tutar!
      
      final paymentResult = await adminApi.completePayment(
        customerId: customerId,
        rideId: widget.rideDetails['ride_id'].toString(),
        amount: finalAmount,
        paymentMethod: _selectedPaymentMethod, // SEÇİLEN ÖDEME YÖNTEMİ!
      );
      
      if (paymentResult['success'] != true) {
        throw Exception(paymentResult['message'] ?? 'Ödeme hatası');
      }
      
      // 2. ✅ YOLCULUK PERSISTENCE'INI TEMİZLE - ÖDEME DÖNGÜSÜNÜ ENGELLE!
      // Backend'den customer_active_rides tablosunu temizle (ayrı endpoint gerekebilir)
      // Şimdilik app-side temizlik yeterli
      await prefs.remove('customer_current_ride');
      await prefs.remove('active_ride_id');
      await prefs.remove('active_ride_status');
      await prefs.remove('pending_payment_ride_id');
      print('✅ Müşteri aktif yolculuk persistence temizlendi - Ödeme döngüsü engellendi!');
      
      setState(() {
        _paymentCompleted = true;
        _isProcessingPayment = false;
      });
      
      // ÖNCE PUANLAMA EKRANI AÇ!
      // Puanlama ana ekranda yapılacak - burada atlandı
      
      // Sonra başarı mesajı ve ana ekrana git
      _showPaymentSuccessAndGoHome();
      
      print('✅ Ödeme ve puanlama tamamlandı');
      
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ödeme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      print('❌ Ödeme hatası: $e');
    }
  }
  
  // MODERN PUANLAMA DİALOGU - ANA EKRANDA KULLANILACAK!
  // NOT: Bu fonksiyon artık kullanılmıyor, ana ekranda modern kart gösterilecek
  
  void _showPaymentSuccessAndGoHome() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('💳 Ödeme Başarılı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 16),
            Text(
              '₺${_totalPrice.toStringAsFixed(2)} başarıyla tahsil edildi.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '✨ Ana ekranda şoförünüzü puanlayabilirsiniz.',
              style: TextStyle(fontSize: 14, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Güvenli yolculuklar dileriz! 🚗✨',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog kapat
                _saveRatingReminderAndGoHome();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Ana Sayfaya Dön ve Puanla', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
  
  // PUANLAMA HATIRLATMASI KAYDET VE ANA EKRANA GİT
  Future<void> _saveRatingReminderAndGoHome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Puanlama bilgisini kaydet - Ana ekranda kart gösterilecek
      await prefs.setString('pending_rating_ride_id', widget.rideDetails['ride_id'].toString());
      await prefs.setString('pending_rating_driver_id', widget.rideDetails['driver_id'].toString());
      await prefs.setString('pending_rating_driver_name', widget.rideDetails['driver_name'] ?? 'Şoförünüz');
      await prefs.setString('pending_rating_customer_id', widget.rideDetails['customer_id'].toString());
      await prefs.setBool('has_pending_rating', true);
      
      print('✅ Puanlama hatırlatması kaydedildi - Ana ekranda kart gösterilecek');
    } catch (e) {
      print('⚠️ Puanlama hatırlatma kaydetme hatası: $e');
    }
    
    // Ana sayfaya git
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }
  
  // IBAN SATIRI - KOPYALAMA İLE!
  Widget _buildIBANCopyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.blue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $label kopyalandı: $value'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Kopyala',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // NORMAL IBAN SATIRI (Kopyasız)
  Widget _buildIBANRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ✅ BACKEND'DEN SÜRE HESAPLA (Sunucu saatine göre)
  String _getRideDuration() {
    final rideDurationHours = widget.rideStatus['ride_duration_hours'];
    if (rideDurationHours != null) {
      final hours = double.tryParse(rideDurationHours.toString()) ?? 0.0;
      final totalMinutes = (hours * 60).round();
      
      if (totalMinutes >= 60) {
        final h = totalMinutes ~/ 60;
        final m = totalMinutes % 60;
        return '$h saat ${m > 0 ? "$m dakika" : ""}';
      } else {
        return '$totalMinutes dakika';
      }
    }
    
    // Fallback: Bekleme süresine +20 dakika ekle (eski yöntem)
    return '${(_waitingMinutes + 20).toString()} dakika';
  }
  
  // ✅ BACKEND'DEN TAMAMLANMA SAATİNİ AL (Sunucu saatine göre)
  String _getCompletionTime() {
    // 🔥 ÖNCELİK: Backend sunucu saatini kullan (completed_at)
    final completedAt = widget.rideStatus['completed_at'] ?? widget.rideDetails['completed_at'];
    if (completedAt != null && completedAt.toString().isNotEmpty) {
      // Backend'den gelen format: '2025-01-31 14:25:30' -> '2025-01-31 14:25'
      final timeStr = completedAt.toString();
      if (timeStr.length >= 16) {
        return timeStr.substring(0, 16);
      }
      return timeStr;
    }
    
    // Fallback: Şu anki saat (SADECE backend verisi yoksa)
    print('⚠️ Backend completed_at verisi yok - telefon saati kullanılıyor (istenmeyen durum)');
    return DateTime.now().toString().substring(0, 16);
  }

  @override
  void dispose() {
    _animController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }
}

