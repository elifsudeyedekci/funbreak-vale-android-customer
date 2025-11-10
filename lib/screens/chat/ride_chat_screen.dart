import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

// MÜŞTERİ MESAJLAŞMA EKRANI - SESLİ MESAJ VE RESİM DESTEĞİ!
class RideChatScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final bool isDriver;

  const RideChatScreen({
    Key? key,
    required this.rideId,
    required this.driverName,
    required this.isDriver,
  }) : super(key: key);

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isRecording = false;
  
  // GERÇEK SES KAYDI İÇİN - FLUTTER SOUND!
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _messagePollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _loadChatHistory();
    _startRealTimeMessaging(); // GERÇEK ZAMANLI SİSTEM!
  }
  
  Future<void> _initializeAudio() async {
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    
    await _audioRecorder!.openRecorder();
    await _audioPlayer!.openPlayer();
    
    print('🎤 Ses kayıt sistemi başlatıldı');
  }

  Future<void> _loadChatHistory() async {
    print('💬 Chat geçmişi yükleniyor - Ride: ${widget.rideId}');
    
    try {
      final response = await http.post(
        Uri.parse('https://admin.funbreakvale.com/api/get_ride_messages.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ride_id': widget.rideId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['messages'] != null) {
          final apiMessages = List<Map<String, dynamic>>.from(data['messages']);
          
          setState(() {
            _messages.clear();
            for (var apiMessage in apiMessages) {
              _messages.add({
                'id': apiMessage['id'].toString(),
                'message': apiMessage['message_content'] ?? '',
                'sender_type': apiMessage['sender_type'] ?? 'customer', // DOĞRU ALAN!
                'timestamp': DateTime.tryParse(apiMessage['created_at'] ?? '') ?? DateTime.now(),
                'type': apiMessage['message_type'] ?? 'text',
                'audioPath': apiMessage['file_path'],
                'duration': apiMessage['duration']?.toString() ?? '0',
              });
            }
            
            print('🔍 MÜŞTERİ: Mesaj parse debug:');
            for (var msg in _messages.take(3)) {
              print('   📨 ID: ${msg['id']}, Sender: ${msg['sender_type']}, Message: ${msg['message']}');
            }
          });
          
          print('✅ Chat geçmişi yüklendi: ${_messages.length} mesaj');
        }
      }
    } catch (e) {
      print('❌ Chat geçmişi yüklenirken hata: $e');
    }
  }
  
  // GERÇEK ZAMANLI MESAJ SİSTEMİ
  void _startRealTimeMessaging() {
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadChatHistory(); // Her 3 saniyede yeni mesajları çek
    });
    
    print('🔄 Gerçek zamanlı mesajlaşma başlatıldı');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                widget.driverName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isDriver ? 'Müşteri' : widget.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Yolculuk Mesajlaşması',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mesajlar listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Mesaj gönderme alanı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Fotoğraf gönder
                IconButton(
                  onPressed: _sendPhoto,
                  icon: const Icon(Icons.photo_camera, color: Color(0xFFFFD700)),
                ),
                
                // Sesli mesaj
                IconButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : const Color(0xFFFFD700),
                  ),
                ),
                
                // Metin mesaj alanı
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    keyboardType: TextInputType.multiline, // 🔥 Türkçe karakter desteği
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(color: Colors.black87),
                    cursorColor: Colors.black87,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                
                // Gönder butonu
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Color(0xFFFFD700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    // MÜŞTERİ: widget.isDriver = false, yani ben 'customer'ım
    final myType = widget.isDriver ? 'driver' : 'customer';
    final isMe = message['sender_type'] == myType;
    final messageTime = message['timestamp'] as DateTime;
    
    print('🔍 MÜŞTERİ Bubble: sender_type=${message['sender_type']}, myType=$myType, isMe=$isMe');
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFD700) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['type'] == 'image')
              GestureDetector(
                onTap: () => _showFullImage(message['message']),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: File(message['message']).existsSync()
                      ? Image.file(
                          File(message['message']),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  Text('Fotoğraf yüklenemedi', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 40, color: Colors.grey),
                              Text('Fotoğraf', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                  ),
                ),
              )
            else if (message['type'] == 'audio')
              GestureDetector(
                onTap: () => _playAudioMessage(message['audioPath'] ?? ''),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : const Color(0xFFFFD700)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white : const Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow, 
                          color: isMe ? const Color(0xFFFFD700) : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎵 Sesli Mesaj',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '⏱️ ${message['duration'] ?? '0:05'}',
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                message['message'],
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            
            const SizedBox(height: 4),
            
            Text(
              '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'message': text,
          'sender_type': widget.isDriver ? 'driver' : 'customer', // DOĞRU ALAN!
          'timestamp': DateTime.now(),
          'type': 'text',
        });
      });
      _messageController.clear();
      
      // API'ye mesaj gönder
      await _sendMessageToAPI(text, 'text');
      print('💬 MÜŞTERİ Mesaj gönderildi: $text');
    }
  }

  Future<void> _sendPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('📸 Fotoğraf çekildi: ${image.path}');
        
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'message': image.path,
            'sender_type': widget.isDriver ? 'driver' : 'customer', // DOĞRU ALAN!
            'timestamp': DateTime.now(),
            'type': 'image',
          });
        });
        
        // API'ye gönder
        await _sendMessageToAPI(image.path, 'image');
        print('📸 Fotograf API gonderildi');
      }
    } catch (e) {
      print('❌ Fotograf hatasi: $e');
    }
  }
  
  Future<void> _sendMessageToAPI(String message, String type) async {
    try {
      // SharedPreferences'tan user bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final customerId = int.tryParse(prefs.getString('admin_user_id') ?? '0') ?? 0;
      final rideId = int.tryParse(widget.rideId) ?? 0;
      
      if (customerId == 0 || rideId == 0) {
        print('❌ Geçersiz customer_id ($customerId) veya ride_id ($rideId)');
        return;
      }
      
      final response = await http.post(
        Uri.parse('https://admin.funbreakvale.com/api/send_ride_message.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ride_id': rideId,
          'sender_type': 'customer',
          'sender_id': customerId,
          'message_type': type,
          'message_content': message,
          'file_path': type != 'text' ? message : null,
          'duration': type == 'audio' ? 5 : 0, // TODO: Gerçek süre
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ MÜŞTERİ: Mesaj API\'ye gönderildi (${data['message_id']})');
        } else {
          print('❌ MÜŞTERİ: API hatası: ${data['message']}');
        }
      } else {
        print('❌ MÜŞTERİ: HTTP hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ MÜŞTERİ: Mesaj gönderme hatası: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Mikrofon izni gerekli!')),
        );
        return;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      _currentRecordingPath = '${audioDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder!.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacMP4,
      );
      
      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
      });
      
      print('🎤 GERÇEK SES KAYDI BAŞLATILDI: $_currentRecordingPath');
    } catch (e) {
      print('❌ Ses kayıt başlatma hatası: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) return;
    
    try {
      await _audioRecorder!.stopRecorder();
      
      final recordingDuration = _recordingStartTime != null 
        ? DateTime.now().difference(_recordingStartTime!).inSeconds
        : 0;
      
      final audioFile = File(_currentRecordingPath!);
      final fileSize = await audioFile.length();
      
      setState(() {
        _isRecording = false;
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'message': 'Sesli mesaj (${recordingDuration}s)',
          'sender': widget.isDriver ? 'driver' : 'customer',
          'timestamp': DateTime.now(),
          'type': 'audio',
          'duration': '0:${recordingDuration.toString().padLeft(2, '0')}',
          'audioPath': _currentRecordingPath,
          'fileSize': fileSize,
        });
      });
      
      await _sendAudioMessage(_currentRecordingPath!, recordingDuration);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎤 ${recordingDuration}s sesli mesaj gönderildi!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('❌ Ses kayıt durdurma hatası: $e');
      setState(() => _isRecording = false);
    }
  }
  
  // GERÇEK SES MESAJI GÖNDERME
  Future<void> _sendAudioMessage(String audioPath, int duration) async {
    try {
      print('🎤 Ses dosyası API\'ye gönderiliyor: $audioPath');
      print('   ⏱️ Süre: ${duration}s');
      await _sendMessageToAPI(audioPath, 'audio');
    } catch (e) {
      print('❌ Ses mesajı gönderme hatası: $e');
    }
  }
  
  // GERÇEK SES MESAJI OYNATMA
  Future<void> _playAudioMessage(String audioPath) async {
    try {
      if (await File(audioPath).exists()) {
        await _audioPlayer!.startPlayer(fromURI: audioPath);
        print('🔊 Ses mesajı oynatılıyor: $audioPath');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Ses mesajı oynatılıyor...'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Ses dosyası bulunamadı: $audioPath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ses dosyası bulunamadı')),
        );
      }
    } catch (e) {
      print('❌ Ses oynatma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ses oynatma hatası: $e')),
      );
    }
  }
  
  // FOTOĞRAF TAM EKRAN GÖSTERME
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: File(imagePath).existsSync()
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 80, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Fotoğraf yüklenemedi',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder?.closeRecorder();
    _audioPlayer?.closePlayer();
    _messagePollingTimer?.cancel(); // TIMER'I DURDUR
    super.dispose();
  }
  
  // Duplicate timer kaldırıldı
}
