import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../services/customer_cards_api.dart';
import 'card_payment_screen.dart'; // ✅ Modern kart ekleme ekranı

// ÖDEME YÖNTEMLERİ EKRANI - VakıfBank 3D Secure Entegreli!
// @version 2.0.0
// @date 2025-11-27
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final CustomerCardsApi _cardsApi = CustomerCardsApi();
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // KARTLARI BACKEND'DEN YÜK
  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    final cards = await _cardsApi.getCards();
    
    setState(() {
      _savedCards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Ödeme Yöntemleri',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add, color: Color(0xFFFFD700)),
            tooltip: 'Yeni Kart Ekle',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                  ),
                ),
              )
            : Column(
          children: [
            // BİLGİLENDİRME KARTI
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Güvenli Ödeme Sistemi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kartlarınız 256-bit SSL şifreleme ile korunur. Yolculuk sonunda otomatik ödeme alınır.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // KAYITLI KARTLAR LİSTESİ
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Kayıtlı Kartlarım',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_savedCards.length} Kart',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Kart listesi
                  if (_savedCards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.credit_card_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz kayıtlı kartınız yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yeni kart eklemek için + butonuna tıklayın',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _savedCards.map((card) => _buildCardItem(card, themeProvider)).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // YENİ KART EKLE BUTONU
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddCardDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Yeni Kart Ekle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // KART İTEM WİDGETİ
  Widget _buildCardItem(Map<String, dynamic> card, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: card['isDefault'] 
              ? const BorderSide(color: Color(0xFFFFD700), width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCardColor(card['cardType']),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCardIcon(card['cardType']),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            card['cardNumber'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card['cardHolder'],
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Son Kullanma: ${card['expiryDate']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  if (card['isDefault']) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Varsayılan',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            itemBuilder: (context) => [
              if (!card['isDefault'])
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                      SizedBox(width: 8),
                      Text('Varsayılan Yap'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Sil'),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleCardAction(card, value.toString()),
          ),
        ),
      ),
    );
  }

  // KART AKSİYONLARI
  void _handleCardAction(Map<String, dynamic> card, String action) {
    switch (action) {
      case 'default':
        _setDefaultCard(card);
        break;
      case 'delete':
        _deleteCard(card);
        break;
    }
  }

  // VARSAYILAN KART YAPMA - BACKEND ÇAĞRISI
  void _setDefaultCard(Map<String, dynamic> card) async {
    final success = await _cardsApi.updateCard(
      cardId: card['id'],
      setDefault: true,
    );
    
    if (success) {
      setState(() {
        // Tüm kartların varsayılan durumunu kaldır
        for (var c in _savedCards) {
          c['isDefault'] = false;
        }
        // Seçilen kartı varsayılan yap
        card['isDefault'] = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card['cardNumber']} varsayılan kart olarak ayarlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('✅ Varsayılan kart değiştirildi: ${card['cardNumber']}');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Varsayılan kart ayarlanamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // KART DÜZENLEME
  void _editCard(Map<String, dynamic> card) {
    print('✏️ Kart düzenleniyor: ${card['cardNumber']}');
    _showAddCardDialog(editingCard: card);
  }

  // KART SİLME - BACKEND ÇAĞRISI
  void _deleteCard(Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Text('${card['cardNumber']} kartını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await _cardsApi.deleteCard(card['id']);
              
              if (success) {
                setState(() {
                  _savedCards.remove(card);
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kart başarıyla silindi'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                
                print('🗑️ Kart silindi: ${card['cardNumber']}');
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kart silinemedi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // YENİ KART EKLEME - MODERN EKRANA YÖNLENDİR!
  void _showAddCardDialog({Map<String, dynamic>? editingCard}) async {
    // ✅ YENİ KART EKLEME - MODERN CardPaymentScreen'E GİT!
    if (editingCard == null) {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('user_id') ?? '0';
      
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CardPaymentScreen(
            rideId: 0, // Sadece kart kaydetme modu
            customerId: int.tryParse(customerId) ?? 0,
            amount: 0.01, // Minimum doğrulama tutarı
            paymentType: 'card_save', // Sadece kart kaydetme
            savedCardId: null,
          ),
        ),
      );
      
      // Kart eklendiyse listeyi yenile
      if (result == true) {
        _loadCards();
      }
      return;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ESKİ KART DÜZENLEME - MEVCUT DIALOG (sadece düzenleme için)
    // ═══════════════════════════════════════════════════════════════
    final cardNumberController = TextEditingController();
    final cardHolderController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    
    // Düzenleme modundaysa mevcut bilgileri doldur
    cardHolderController.text = editingCard['cardHolder'];
    expiryController.text = editingCard['expiryDate'];
    // Kart numarası güvenlik nedeniyle düzenlenemez

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // KART NUMARASI
              if (editingCard == null) ...[
                TextField(
                  controller: cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Kart Numarası',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: Icon(Icons.credit_card, color: Color(0xFFFFD700)),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberInputFormatter(),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // KART SAHİBİ
              TextField(
                controller: cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Kart Sahibi',
                  hintText: 'AD SOYAD',
                  prefixIcon: Icon(Icons.person, color: Color(0xFFFFD700)),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              
              // SON KULLANMA TARİHİ VE CVV
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Son Kullanma',
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFFFFD700)),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateInputFormatter(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (editingCard == null) ...[
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: Icon(Icons.security, color: Color(0xFFFFD700)),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscureText: true,
                      ),
                    ),
                  ],
                ],
              ),
              
                              const SizedBox(height: 16),
              
              // GÜVENLİK BİLGİSİ - 3D Secure
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '3D Secure ile Korumalı',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Kartınız VakıfBank 3D Secure ile doğrulanır\n'
                      '• 0.01 ₺ doğrulama ücreti çekilir ve anında iade edilir\n'
                      '• Kart bilgileriniz AES-256 ile şifrelenir',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _saveCard(
              editingCard,
              cardNumberController.text,
              cardHolderController.text,
              expiryController.text,
              cvvController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
            ),
            child: Text(editingCard != null ? 'Güncelle' : 'Kaydet'),
          ),
        ],
      ),
    );
  }

  // KART KAYDETME - VakıfBank 3D Secure ile Doğrulama
  void _saveCard(Map<String, dynamic>? editingCard, String cardNumber, String cardHolder, String expiry, String cvv) async {
    // Basit validasyon
    if (editingCard == null && cardNumber.replaceAll(' ', '').length < 16) {
      _showError('Geçerli bir kart numarası girin');
      return;
    }
    
    if (cardHolder.trim().length < 3) {
      _showError('Kart sahibi adını girin');
      return;
    }
    
    if (expiry.length < 5) {
      _showError('Geçerli son kullanma tarihi girin');
      return;
    }
    
    if (editingCard == null && cvv.length < 3) {
      _showError('Geçerli CVV kodu girin');
      return;
    }

    // KART KAYDETME/GÜNCELLEME
    if (editingCard != null) {
      // Düzenleme modu - sadece varsayılan yapılabilir
      final success = await _cardsApi.updateCard(
        cardId: editingCard['id'],
        cardHolder: cardHolder.toUpperCase(),
      );
      
      if (success) {
        setState(() {
          editingCard['cardHolder'] = cardHolder.toUpperCase();
        });
        
        print('✅ Kart güncellendi: ${editingCard['cardNumber']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kart bilgileri güncellendi'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          _showError('Kart güncellenemedi');
        }
        return;
      }
      Navigator.pop(context);
    } else {
      // ═══════════════════════════════════════════════════════════════
      // YENİ KART EKLEME - 3D SECURE DOĞRULAMA
      // 0.01 TL çekilir, doğrulanırsa kaydedilir, sonra iade edilir
      // ═══════════════════════════════════════════════════════════════
      
      Navigator.pop(context); // Dialog'u kapat
      
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFFD700)),
              const SizedBox(height: 16),
              const Text('Kart doğrulanıyor...'),
              const SizedBox(height: 8),
              Text(
                '0.01 ₺ doğrulama ücreti çekilecek ve hemen iade edilecek',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      
      try {
        final result = await _cardsApi.addCard(
          cardNumber: cardNumber,
          cardHolder: cardHolder.toUpperCase(),
          expiryDate: expiry,
          cvv: cvv,
        );
        
        // Loading'i kapat
        if (mounted) Navigator.pop(context);
        
        if (result != null && result['success'] == true) {
          if (result['requires_3d'] == true && result['acs_html'] != null) {
            // 3D Secure sayfasını göster
            print('🔐 3D Secure doğrulama gerekli');
            _show3DSecureWebView(result['acs_html']);
          } else {
            // Direkt başarılı (3D Secure yok)
            _loadCards(); // Kartları yenile
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Kart başarıyla doğrulandı ve kaydedildi'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            _showError(result?['message'] ?? 'Kart doğrulanamadı');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Loading'i kapat
          _showError('Bir hata oluştu: $e');
        }
      }
    }
  }
  
  // 3D SECURE WEBVIEW GÖSTER
  void _show3DSecureWebView(String acsHtml) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Kart Doğrulama'),
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kart doğrulama iptal edildi'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
          body: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onPageStarted: (url) {
                    print('📄 3D Secure sayfa: $url');
                  },
                  onNavigationRequest: (request) {
                    // Deep link kontrolü - doğrulama tamamlandı
                    if (request.url.contains('funbreakvale://') || 
                        request.url.contains('card_verification_callback.php')) {
                      // Doğrulama tamamlandı
                      Navigator.pop(context);
                      _loadCards(); // Kartları yenile
                      
                      if (request.url.contains('success=true')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Kart başarıyla doğrulandı ve kaydedildi!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Kart doğrulanamadı'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              )
              ..loadHtmlString(acsHtml),
          ),
        ),
      ),
    );
  }

  // HATA GÖSTERME
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // KART TİPİ ALGILA
  String _detectCardType(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');
    
    if (number.startsWith('4')) return 'visa';
    if (number.startsWith('5') || number.startsWith('2')) return 'mastercard';
    if (number.startsWith('3')) return 'amex';
    
    return 'unknown';
  }

  // KART RENGİ
  Color _getCardColor(String cardType) {
    switch (cardType) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'amex':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // KART İKONU
  IconData _getCardIcon(String cardType) {
    switch (cardType) {
      case 'visa':
      case 'mastercard':
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
}

// KART NUMARASI FORMATLAYICI
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// SON KULLANMA TARİHİ FORMATLAYICI
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
