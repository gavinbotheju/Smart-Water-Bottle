import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'Home.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyLoginPage> createState() => MyLoginPageState();
}

class MyLoginPageState extends State<MyLoginPage> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String useremailerror = '';
  String userpassworderror = '';

  updateLoginError(err) {
    setState(() {
      if (err == 'user-not-found') {
        useremailerror += "No user found for that email.";
        userpassworderror = '';
        Fluttertoast.showToast(
          msg: "No user found for that email.",
          toastLength: Toast.LENGTH_SHORT,
          textColor: Colors.black,
          fontSize: 14,
          backgroundColor: Colors.grey[200],
        );
      } else if (err == 'wrong-password') {
        useremailerror = '';
        userpassworderror = "Invalid password.";
        Fluttertoast.showToast(
          msg: "Wrong password provided for that user.",
          toastLength: Toast.LENGTH_SHORT,
          textColor: Colors.black,
          fontSize: 14,
          backgroundColor: Colors.grey[200],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: 350,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("assets/images/login-bg.jpg"),
                ),
              ),
            ),
            Container(
                transform: Matrix4.translationValues(0.0, -100.0, 0.0),
                margin: const EdgeInsets.symmetric(
                    vertical: 0.01, horizontal: 0.01),
                decoration: const BoxDecoration(
                  color: Color(0xFF000033),
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(40.0),
                      topLeft: Radius.circular(40.0)),
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.01,
                      horizontal: MediaQuery.of(context).size.width * 0.10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                        scale: 1,
                      ),
                      const Text(
                        'Login to your account',
                        key: Key('loginLabel'),
                        style: TextStyle(
                          fontSize: 25,
                          color: Color(0xFFfcfcfc),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      TextFormField(
                        controller: emailController,
                        onChanged: (value) {},
                        style: const TextStyle(color: Color(0xFFf5f5f5)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 8.0),
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFf5f5f5)),
                          ),
                          labelText: 'Enter your Email',
                          labelStyle: TextStyle(
                            color: Color(0xFFf5f5f5),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: 35,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              key: const Key('userEmailError'),
                              useremailerror,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        // hidden password
                        onChanged: (value) {},
                        style: const TextStyle(color: Color(0xFFf5f5f5)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 8.0),
                          border: UnderlineInputBorder(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFf5f5f5)),
                          ),
                          labelText: 'Enter your Password',
                          labelStyle: TextStyle(
                            color: Color(0xFFf5f5f5),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: 35,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              key: const Key('userPasswordError'),
                              userpassworderror,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('loginButton'),
                          onPressed: () async {
                            /*Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyHomePage(
                                        title: 'Track',
                                      )),
                            );*/
                            try {
                              final credential = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MyHomePage(
                                      title: 'Track',
                                    )),
                              );
                            } on FirebaseAuthException catch (e) {
                              updateLoginError(e.code);
                            }
                          },
                          // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFfcfcfc),
                            elevation: 10.0,
                            textStyle:
                                const TextStyle(color: Color(0xFF000033)),
                            shape: const StadiumBorder(),
                            /*RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12), // <-- Radius
                                      ),*/
                            //padding: const EdgeInsets.fromLTRB(20, 10, 20, 10)
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000033),
                                letterSpacing: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          ]),
        ),
      ),
    );
  }
}
