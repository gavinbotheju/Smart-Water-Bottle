import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'Pallette.dart';
import 'SplashScreen.dart';

//FirebaseAuth auth = FirebaseAuth.instance;
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.getInitialMessage();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydr8',
      theme: ThemeData(
          primarySwatch: Palette.kToDark, //Colors.blue,
          appBarTheme: const AppBarTheme(
            color: Color(0xFF000033),
          ),
          scaffoldBackgroundColor: const Color(0xFF000033)), //381ce4
      //home: const MyHomePage(title: ''),
      home: const SplashScreen(),
    );
  }
}
