import 'dart:async';
import 'package:flutter/material.dart';
import 'Login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 5), // 5 seconds
            () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MyLoginPage(title: ''))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000033),
      //child: FlutterLogo(size: MediaQuery.of(context).size.height)
      child: Column(
        key: const Key('splashScreenImage'),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/images/logo.png',
            height: 200,
            scale: 1,
            // color: Color.fromARGB(255, 15, 147, 59),
          ),
        ],
      ),
    );
  }
}
