import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref('messages');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Map<String, String> _userNicknames = {};
  StreamSubscription? _messageSubscription;

  String _uuid = "Unknown";
  String _nickname = "Unknown";

  Future<void> initializeUser() async {
    await _getOrCreateUuid();
    await _registerUser();
  }

  Future<void> _getOrCreateUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUuid = prefs.getString('device_uuid');

    if (storedUuid == null) {
      const uuid = Uuid();
      storedUuid = uuid.v4();
      await prefs.setString('device_uuid', storedUuid);
    }

    _uuid = storedUuid;
  }

  Future<void> _registerUser() async {
    final userDoc = await _firestore.collection('users').doc(_uuid).get();

    if (!userDoc.exists) {
      final usersCount = await _firestore.collection('users').count().get();
      final nextNumber = (usersCount.count ?? 0) + 1;

      await _firestore.collection('users').doc(_uuid).set({
        'uuid': _uuid,
        'nickname': '삼붕이 $nextNumber',
      });
    }

    final userData = await _firestore.collection('users').doc(_uuid).get();
    _nickname = userData.data()?['nickname'] ?? 'Unknown';
  }

  Future<String> getUserNickname(String uuid) async {
    if (_userNicknames.containsKey(uuid)) {
      return _userNicknames[uuid]!;
    }

    final userDoc = await _firestore.collection('users').doc(uuid).get();
    if (userDoc.exists) {
      final nickname = userDoc.data()?['nickname'] ?? 'Unknown';
      _userNicknames[uuid] = nickname;
      return nickname;
    }
    return 'Unknown';
  }

  String get uuid => _uuid;
  String get nickname => _nickname;

  DatabaseReference get messagesRef => _database;

  Future<String> uploadImage(File image, int roomNumber) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref =
        _storage.ref().child('chat_images/room_$roomNumber/$fileName');
    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void sendTextMessage(String text, int roomNumber) {
    if (text.isNotEmpty) {
      _database.push().set({
        'type': 'text',
        'room': roomNumber.toString(),
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sender': _uuid,
        'senderNickname': _nickname,
      });
    }
  }

  void sendImageMessage(String imageUrl, int roomNumber) {
    _database.push().set({
      'type': 'image',
      'room': roomNumber.toString(),
      'imageUrl': imageUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sender': _uuid,
      'senderNickname': _nickname,
    });
  }

  void setupRoomListener(
      int roomNumber, Function(Map<dynamic, dynamic>) onMessage) {
    // Cancel any existing subscription
    _messageSubscription?.cancel();

    // Set up new listener for the specific room with timestamp ordering
    _messageSubscription = _database
        .orderByChild('room')
        .equalTo(roomNumber.toString())
        .onChildAdded
        .listen((event) async {
      final message = event.snapshot.value as Map<dynamic, dynamic>;
      final senderNickname = await getUserNickname(message['sender']);
      onMessage({
        ...message,
        'senderNickname': senderNickname,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'timestamp': data['timestamp'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}
