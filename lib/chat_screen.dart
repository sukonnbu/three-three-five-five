import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ttff/firebase.dart';
import 'package:photo_view/photo_view.dart';

class ChatScreen extends StatefulWidget {
  final int roomNumber;
  const ChatScreen({super.key, required this.roomNumber});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebase = FirebaseService();
  List<Map<dynamic, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _firebase.initializeUser();
    _setupRealtimeListener();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomNumber != widget.roomNumber) {
      setState(() {
        messages.clear();
      });
      _setupRealtimeListener();
    }
  }

  @override
  void dispose() {
    _firebase.dispose();
    super.dispose();
  }

  void _setupRealtimeListener() {
    _firebase.setupRoomListener(widget.roomNumber, (message) {
      // Check if message already exists in the list
      if (!messages.any((m) =>
          m['timestamp'] == message['timestamp'] &&
          m['sender'] == message['sender'])) {
        setState(() {
          messages.add(message);
          messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
        });
      }
    });
  }

  void _sendTextMessage() {
    _firebase.sendTextMessage(_controller.text, widget.roomNumber);
    _controller.clear();
  }

  Future<void> _sendImageMessage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
              ),
              SizedBox(height: 16),
              Text(
                '이미지 업로드 중...',
                style: TextStyle(
                  fontFamily: "Pat",
                  fontSize: 16,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
      );

      final imageUrl =
          await _firebase.uploadImage(File(image.path), widget.roomNumber);
      _firebase.sendImageMessage(imageUrl, widget.roomNumber);

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();
    } catch (e) {
      // 에러 발생 시 로딩 다이얼로그 닫기
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '이미지 업로드 중 오류가 발생했습니다.',
            style: TextStyle(
              fontFamily: "Pat",
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotifications() async {
    final notifications = await _firebase.getNotifications();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '공지사항',
          style: TextStyle(
            fontFamily: "Pat",
            fontSize: 24,
            color: Colors.green[800],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: notifications.isEmpty
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      '공지사항이 없습니다.',
                      style: TextStyle(
                        fontFamily: "Pat",
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'],
                              style: TextStyle(
                                fontFamily: "Pat",
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              notification['content'],
                              style: TextStyle(
                                fontFamily: "Pat",
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              notification['timestamp'].toString(),
                              style: TextStyle(
                                fontFamily: "Pat",
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '닫기',
              style: TextStyle(
                fontFamily: "Pat",
                fontSize: 18,
                color: Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<dynamic, dynamic> message) {
    CrossAxisAlignment align = CrossAxisAlignment.start;
    TextAlign textalign = TextAlign.start;

    if (message['sender'] == _firebase.uuid) {
      align = CrossAxisAlignment.end;
      textalign = TextAlign.end;
    }

    return MessageItem(
      nickname: message['senderNickname'],
      type: message['type'],
      content:
          message['type'] == 'image' ? message['imageUrl'] : message['text'],
      timestamp: message['timestamp'],
      align: align,
      textalign: textalign,
    );
  }

  Widget MessageItem({
    required String nickname,
    required String type,
    required String content,
    required int timestamp,
    required CrossAxisAlignment align,
    required TextAlign textalign,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.green[200]!,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: align,
              children: [
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[800],
                    fontFamily: "Pat",
                  ),
                ),
                SizedBox(height: 8.0),
                type == 'text'
                    ? Text(
                        content,
                        textAlign: textalign,
                        style: TextStyle(
                          fontFamily: "Pat",
                          fontSize: 22,
                          color: Colors.black87,
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  centerTitle: true,
                                  title: Text(
                                    '이미지 자세히 보기',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontFamily: "Pat",
                                    ),
                                  ),
                                ),
                                body: PhotoView(
                                  imageProvider: NetworkImage(content),
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale: PhotoViewComputedScale.covered * 2,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          content,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: child,
                              );
                            }
                            return CircularProgressIndicator();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Text('Error loading image');
                          },
                        ),
                      ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8.0, 4.0, 0, 0),
            child: Text(
              DateTime.fromMillisecondsSinceEpoch(timestamp)
                  .toString()
                  .substring(5, 19),
              textAlign: textalign,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontFamily: "Pat",
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: Text(
          '질문방 ${widget.roomNumber}',
          style: TextStyle(
            fontFamily: "Pat",
            fontSize: 30,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.notifications),
          onPressed: _showNotifications,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageItem(messages[index]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '질문하고 답하기',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.green[700]!,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: "Pat",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendTextMessage,
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _sendImageMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
