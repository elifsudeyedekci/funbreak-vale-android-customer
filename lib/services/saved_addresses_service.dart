import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAddressesService {
  static const String _savedAddressesKey = 'saved_addresses';
  static const String _favoriteAddressesKey = 'favorite_addresses';
  
  // Kayıtlı adresleri al
  static Future<List<SavedAddress>> getSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString(_savedAddressesKey);
      
      if (addressesJson == null) {
        print('Kayıtlı adres bulunamadı');
        return [];
      }
      
      final List<dynamic> addressesList = json.decode(addressesJson);
      List<SavedAddress> addresses = addressesList
          .map((json) => SavedAddress.fromJson(json))
          .toList();
      
      // Tarihe göre sırala (en yeni önce)
      addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('${addresses.length} kayıtlı adres yüklendi');
      return addresses;
    } catch (e) {
      print('Kayıtlı adres yükleme hatası: $e');
      return [];
    }
  }
  
  // Adres kaydet
  static Future<bool> saveAddress(SavedAddress address) async {
    try {
      final addresses = await getSavedAddresses();
      
      // Aynı adres var mı kontrol et
      bool exists = addresses.any((addr) => 
        addr.latitude == address.latitude && 
        addr.longitude == address.longitude
      );
      
      if (exists) {
        print('Bu adres zaten kayıtlı');
        return false;
      }
      
      addresses.insert(0, address); // En başa ekle
      
      // Maksimum 50 adres tut
      if (addresses.length > 50) {
        addresses.removeRange(50, addresses.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(addresses.map((addr) => addr.toJson()).toList());
      
      bool success = await prefs.setString(_savedAddressesKey, addressesJson);
      
      if (success) {
        print('Adres kaydedildi: ${address.name}');
      }
      
      return success;
    } catch (e) {
      print('Adres kaydetme hatası: $e');
      return false;
    }
  }
  
  // Adres sil
  static Future<bool> deleteAddress(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      
      addresses.removeWhere((addr) => addr.id == addressId);
      
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(addresses.map((addr) => addr.toJson()).toList());
      
      bool success = await prefs.setString(_savedAddressesKey, addressesJson);
      
      if (success) {
        print('Adres silindi: $addressId');
      }
      
      return success;
    } catch (e) {
      print('Adres silme hatası: $e');
      return false;
    }
  }
  
  // Adres güncelle
  static Future<bool> updateAddress(SavedAddress updatedAddress) async {
    try {
      final addresses = await getSavedAddresses();
      
      int index = addresses.indexWhere((addr) => addr.id == updatedAddress.id);
      
      if (index == -1) {
        print('Güncellenecek adres bulunamadı');
        return false;
      }
      
      addresses[index] = updatedAddress;
      
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(addresses.map((addr) => addr.toJson()).toList());
      
      bool success = await prefs.setString(_savedAddressesKey, addressesJson);
      
      if (success) {
        print('Adres güncellendi: ${updatedAddress.name}');
      }
      
      return success;
    } catch (e) {
      print('Adres güncelleme hatası: $e');
      return false;
    }
  }
  
  // Favori adresleri al
  static Future<List<SavedAddress>> getFavoriteAddresses() async {
    try {
      final addresses = await getSavedAddresses();
      return addresses.where((addr) => addr.isFavorite).toList();
    } catch (e) {
      print('Favori adres yükleme hatası: $e');
      return [];
    }
  }
  
  // Favori durumunu değiştir
  static Future<bool> toggleFavorite(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      
      int index = addresses.indexWhere((addr) => addr.id == addressId);
      
      if (index == -1) {
        print('Adres bulunamadı');
        return false;
      }
      
      addresses[index] = addresses[index].copyWith(
        isFavorite: !addresses[index].isFavorite
      );
      
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(addresses.map((addr) => addr.toJson()).toList());
      
      bool success = await prefs.setString(_savedAddressesKey, addressesJson);
      
      if (success) {
        print('Favori durumu değiştirildi: ${addresses[index].name}');
      }
      
      return success;
    } catch (e) {
      print('Favori değiştirme hatası: $e');
      return false;
    }
  }
  
  // Son kullanılan adresleri al
  static Future<List<SavedAddress>> getRecentAddresses({int limit = 10}) async {
    try {
      final addresses = await getSavedAddresses();
      
      // Son kullanım tarihine göre sırala
      addresses.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      
      return addresses.take(limit).toList();
    } catch (e) {
      print('Son kullanılan adres yükleme hatası: $e');
      return [];
    }
  }
  
  // Adres kullanıldığını işaretle
  static Future<bool> markAddressAsUsed(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      
      int index = addresses.indexWhere((addr) => addr.id == addressId);
      
      if (index == -1) {
        return false;
      }
      
      addresses[index] = addresses[index].copyWith(
        lastUsedAt: DateTime.now(),
        usageCount: addresses[index].usageCount + 1
      );
      
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(addresses.map((addr) => addr.toJson()).toList());
      
      return await prefs.setString(_savedAddressesKey, addressesJson);
    } catch (e) {
      print('Adres kullanım işaretleme hatası: $e');
      return false;
    }
  }
  
  // Tüm adresleri temizle
  static Future<bool> clearAllAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool success = await prefs.remove(_savedAddressesKey);
      
      if (success) {
        print('Tüm kayıtlı adresler temizlendi');
      }
      
      return success;
    } catch (e) {
      print('Adres temizleme hatası: $e');
      return false;
    }
  }
  
  // Adres ara
  static Future<List<SavedAddress>> searchAddresses(String query) async {
    try {
      if (query.isEmpty) {
        return await getSavedAddresses();
      }
      
      final addresses = await getSavedAddresses();
      final lowercaseQuery = query.toLowerCase();
      
      return addresses.where((addr) =>
        addr.name.toLowerCase().contains(lowercaseQuery) ||
        addr.address.toLowerCase().contains(lowercaseQuery) ||
        (addr.description?.toLowerCase().contains(lowercaseQuery) ?? false)
      ).toList();
    } catch (e) {
      print('Adres arama hatası: $e');
      return [];
    }
  }
}

// Kayıtlı adres modeli
class SavedAddress {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final AddressType type;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final int usageCount;
  
  SavedAddress({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.type,
    this.isFavorite = false,
    required this.createdAt,
    required this.lastUsedAt,
    this.usageCount = 0,
  });
  
  // JSON'dan oluştur
  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      description: json['description'],
      type: AddressType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AddressType.other,
      ),
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsedAt: DateTime.parse(json['lastUsedAt']),
      usageCount: json['usageCount'] ?? 0,
    );
  }
  
  // JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'type': type.toString(),
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'usageCount': usageCount,
    };
  }
  
  // Kopyala ve değiştir
  SavedAddress copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    AddressType? type,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }
  
  @override
  String toString() {
    return 'SavedAddress(name: $name, address: $address, type: $type)';
  }
}

// Adres türleri
enum AddressType {
  home,     // Ev
  work,     // İş
  other,    // Diğer
  hotel,    // Otel
  airport,  // Havalimanı
  hospital, // Hastane
  school,   // Okul
  shopping, // Alışveriş
}

// Adres türü uzantıları
extension AddressTypeExtension on AddressType {
  String get displayName {
    switch (this) {
      case AddressType.home:
        return 'Ev';
      case AddressType.work:
        return 'İş';
      case AddressType.hotel:
        return 'Otel';
      case AddressType.airport:
        return 'Havalimanı';
      case AddressType.hospital:
        return 'Hastane';
      case AddressType.school:
        return 'Okul';
      case AddressType.shopping:
        return 'Alışveriş';
      case AddressType.other:
        return 'Diğer';
    }
  }
  
  String get icon {
    switch (this) {
      case AddressType.home:
        return '🏠';
      case AddressType.work:
        return '🏢';
      case AddressType.hotel:
        return '🏨';
      case AddressType.airport:
        return '✈️';
      case AddressType.hospital:
        return '🏥';
      case AddressType.school:
        return '🏫';
      case AddressType.shopping:
        return '🛒';
      case AddressType.other:
        return '📍';
    }
  }
}
