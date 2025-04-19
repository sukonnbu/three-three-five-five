import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ttff/chat_screen.dart';
import 'package:ttff/update_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    ChatScreen(roomNumber: 1),
    ChatScreen(roomNumber: 2),
    ChatScreen(roomNumber: 3),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 업데이트 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3-3 오래 고민하지 말고 오늘 해결하자',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.dark(
          primary: Colors.green[800]!,
          secondary: Colors.green[700]!,
          surface: Colors.green[100]!,
          onPrimary: Colors.green,
          onSecondary: Colors.green,
          onSurface: Colors.green[900]!,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[900],
          foregroundColor: Colors.green[100],
        ),
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.green[900],
          indicatorColor: Colors.green[800],
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(
              color: Colors.white,
              fontFamily: "Pat",
            ),
          ),
          iconTheme: WidgetStateProperty.all(
            IconThemeData(
              color: Colors.green[300],
            ),
          ),
        ),
      ),
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: "룸 1",
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: "룸 2",
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: "룸 3",
            ),
          ],
        ),
      ),
    );
  }
}
