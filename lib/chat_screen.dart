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
      if (image != null) {
        final imageUrl =
            await _firebase.uploadImage(File(image.path), widget.roomNumber);
        _firebase.sendImageMessage(imageUrl, widget.roomNumber);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    }
  }

  Widget _buildMessageItem(Map<dynamic, dynamic> message) {
    CrossAxisAlignment align = CrossAxisAlignment.start;
    TextAlign textalign = TextAlign.start;

    if (message['sender'] == _firebase.uuid) {
      align = CrossAxisAlignment.end;
      textalign = TextAlign.end;
    }

    if (message['type'] == 'image') {
      return Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(
              message['senderNickname'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: "Pat",
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          '자세히 보기',
                          style: TextStyle(
                            fontSize: 26,
                            color: Colors.black,
                            fontFamily: "Pat",
                          ),
                        ),
                      ),
                      body: PhotoView(
                        imageProvider: NetworkImage(message['imageUrl']),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      ),
                    ),
                  ),
                );
              },
              child: Image.network(
                message['imageUrl'],
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) {
                  return Text('Error loading image');
                },
              ),
            ),
            Text(
              DateTime.fromMillisecondsSinceEpoch(message['timestamp'])
                  .toString(),
              textAlign: textalign,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: "Pat",
              ),
            ),
          ],
        ),
      );
    } else {
      return ListTile(
        title: Column(
          crossAxisAlignment: align,
          children: [
            Text(
              message['senderNickname'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: "Pat",
              ),
            ),
            Text(
              message['text'],
              textAlign: textalign,
              style: TextStyle(
                fontFamily: "Pat",
                fontSize: 22,
              ),
            ),
          ],
        ),
        subtitle: Text(
          DateTime.fromMillisecondsSinceEpoch(message['timestamp']).toString(),
          textAlign: textalign,
          style: TextStyle(
            fontFamily: "Pat",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          // TODO: User Settings
          ),
      appBar: AppBar(
        title: Text(
          '질문방 ${widget.roomNumber}',
          style: TextStyle(
            fontFamily: "Pat",
            fontSize: 30,
          ),
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
                      hintText: '질문하기',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontFamily: "Pat"),
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
