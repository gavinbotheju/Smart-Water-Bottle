import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/Home.dart';
import 'package:http/http.dart' as http;

import 'History.dart';
import 'Login.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyProfilePage> createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {

  // Initial Selected Value
  String dropdownvalue = 'Male';
  var items = [
    'Male',
    'Female',
    'Prefer not to say',
  ];

  TextEditingController dateInput = TextEditingController();

  final DatabaseReference databaseRef = FirebaseDatabase.instance.reference();

  String? data;
  String? userfname, userlname, useremail, usergender, userdob, usergoal;

  @override
  void initState() {
    //dateInput.text = "2001-05-15"; //set the initial value of text field
    fetchData();
    super.initState();
  }

  void fetchData() {
    databaseRef.child('user/firstName').onValue.listen((event) {
      setState(() {
        userfname = event.snapshot.value.toString();
      });
    });
    databaseRef.child('user/lastName').onValue.listen((event) {
      setState(() {
        userlname = event.snapshot.value.toString();
      });
    });
    databaseRef.child('user/email').onValue.listen((event) {
      setState(() {
        useremail = event.snapshot.value.toString();
      });
    });
    databaseRef.child('user/gender').onValue.listen((event) {
      setState(() {
        usergender = event.snapshot.value.toString();
      });
    });
    databaseRef.child('user/dateOfBirth').onValue.listen((event) {
      setState(() {
        userdob = event.snapshot.value.toString();
        dateInput.text = userdob!;
      });
    });
    databaseRef.child('user/goal').onValue.listen((event) {
      setState(() {
        usergoal = event.snapshot.value.toString();
      });
    });
  }

  Future<void> updateData() async {
    try {
      await databaseRef.child('user').update({
        'firstName': userfname,
        'lastName': userlname,
        'email': useremail,
        'gender': dropdownvalue,
        'dateOfBirth': dateInput.text,
        'goal': usergoal,
      });
      Fluttertoast.showToast(
        msg: "Profile Updated",
        toastLength: Toast.LENGTH_SHORT,
        textColor: Colors.black,
        fontSize: 14,
        backgroundColor: Colors.grey[300],
      );
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Error Updating Data",
        toastLength: Toast.LENGTH_SHORT,
        textColor: Colors.black,
        fontSize: 14,
        backgroundColor: Colors.grey[300],
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget bigCircle = Container(
      width: 100.0,
      height: 100.0,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: usergender == "Male"?
                const Image(
                  image: AssetImage("assets/images/male.png"),
                ): usergender == "Female"?
                      const Image(
                        image: AssetImage("assets/images/female.png"),
                ): const Icon(
                    Icons.person,
                    size: 80.0,
                    color: Color(0xFF000033),
                  )
      /*child: const Icon(
        Icons.person,
        size: 80.0,
        color: Color(0xFF000033),
      ),*/
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: RefreshIndicator(
            color: const Color(0xFF000033),
            child: SingleChildScrollView(
              //physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 350,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage("assets/images/profile-bg.jpg"),
                    ),
                  ),
                ),
                Container(
                    transform: Matrix4.translationValues(0.0, -250.0, 0.0),
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
                          horizontal: MediaQuery.of(context).size.width * 0.15),
                      child: userfname == null || userlname == null || useremail == null
                          ? const Center(
                          heightFactor: 10,
                          child: CircularProgressIndicator())
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(
                            height: 20,
                          ),
                          bigCircle,
                          const SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            initialValue: userfname,
                            onChanged: (value) {
                              userfname = value;
                            },
                            style:
                            const TextStyle(color: Color(0xFFf5f5f5)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Color(0xFFf5f5f5)),
                              ),
                              labelText: 'First Name',
                              labelStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextFormField(
                            initialValue: userlname,
                            onChanged: (value) {
                              userlname = value;
                            },
                            style:
                            const TextStyle(color: Color(0xFFf5f5f5)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Color(0xFFf5f5f5)),
                              ),
                              labelText: 'Last Name',
                              labelStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextFormField(
                            initialValue: useremail,
                            onChanged: (value) {
                              useremail = value;
                            },
                            style:
                            const TextStyle(color: Color(0xFFf5f5f5)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Color(0xFFf5f5f5)),
                              ),
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextFormField(
                            initialValue: usergoal,
                            onChanged: (value) {
                              usergoal = value.toString();
                            },
                            style:
                            const TextStyle(color: Color(0xFFf5f5f5)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Color(0xFFf5f5f5)),
                              ),
                              labelText: 'Set a Goal',
                              labelStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                              suffixText: 'ml',
                              suffixStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          DropdownButtonFormField(
                            dropdownColor: const Color(0xFF000033).withOpacity(0.8),
                            value: usergender,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            style: const TextStyle(
                              color: Color(0xFFf5f5f5),
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFf5f5f5)),
                              ),
                              labelText: 'Gender',
                              labelStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                            ),
                            items: items.map((String items) {
                              return DropdownMenuItem(
                                value: items,
                                child: Text(items, /*style: const TextStyle(color: Colors.black),*/),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownvalue = newValue!;
                              });
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextFormField(
                            style:
                            const TextStyle(color: Color(0xFFf5f5f5)),
                            controller: dateInput,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Color(0xFFf5f5f5)),
                              ),
                              labelText: "Date of Birth",
                              labelStyle: TextStyle(
                                color: Color(0xFFf5f5f5),
                              ),
                            ),
                            readOnly: true,
                            //set it true, so that user will not able to edit text
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1950),
                                  //DateTime.now() - not to allow to choose before today.
                                  lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF000033), // header background color
                                        onPrimary: Color(0xFFf5f5f5), // header text color
                                        onSurface: Color(0xFF000033), // body text color
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF000033), // button text color
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pickedDate != null) {
                                String formattedDate =
                                DateFormat('yyyy-MM-dd')
                                    .format(pickedDate);
                                setState(() {
                                  dateInput.text =
                                      formattedDate; //set output date to TextField value.
                                });
                              } else {}
                            },
                          ),

                        ],
                      ),
                    )),
              ]),
            ),
            onRefresh: () {
              return Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  //txt = 'Page Refreshed';
                  Fluttertoast.showToast(
                    msg: "Page Refreshed",
                    toastLength: Toast.LENGTH_SHORT,
                    textColor: Colors.black,
                    fontSize: 14,
                    backgroundColor: Colors.grey[300],
                  );
                });
              });
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              /*print(userfname);
              print(userlname);
              print(useremail);
              print(dropdownvalue);
              print(dateInput);*/
              updateData();
            },
            tooltip: 'Save',
            child: const Icon(
              Icons.save,
              color: Color(0xFF000033),
            ),
          ),
          drawer: Drawer(
              child: Container(
                color: const Color(0xFF000033),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      //padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 30.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFF000033),
                          image: DecorationImage(
                            fit: BoxFit.scaleDown,
                            scale: 2,
                            image: AssetImage(
                              "assets/images/logo.png",
                            ),
                          ),
                        ),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          child: const Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 17,
                              letterSpacing: 3,
                              color: Color(0xFFF5F5F5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )),
                    const SizedBox(
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                    ),
                    ListTile(
                      selected: true,
                      leading: const Icon(Icons.person, color: Color(0xFF2ea5e4)),
                      title: const Text(
                        ' Profile',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2ea5e4)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      selected: false,
                      leading: const Icon(Icons.track_changes, color: Colors.white),
                      title: const Text(
                        ' Track',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyHomePage(
                                title: 'Track',
                              )),
                        );
                      },
                    ),
                    ListTile(
                      selected: false,
                      leading: const Icon(Icons.history, color: Colors.white),
                      title: const Text(
                        ' Records',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyHistoryPage(
                                title: 'Records',
                              )),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text(
                        ' LogOut',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onTap: () async {
                        //Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyLoginPage(
                                title: '',
                              )),
                        );
                        //await FirebaseAuth.instance.signOut();
                      },
                    ),
                  ],
                ),
              )),
      ),

    );
  }
}
