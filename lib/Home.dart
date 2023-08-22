import 'dart:async';
import 'dart:convert';
import 'package:cron/cron.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:mobile_app/History.dart';
import 'package:mobile_app/Profile.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:http/http.dart' as http;

import 'Login.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  final DatabaseReference databaseRef = FirebaseDatabase.instance.reference();
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('readings');
  final DatabaseReference _databaseReferenceUser = FirebaseDatabase.instance.ref().child('user');

  String? data;
  int batteryPercentage = 100;

  late double usergoal = 1500;
  late double userconsumed;
  late double userAverageSum;
  late double userAverageSumHours;
  late double userconsumedLast2Hours;

  // Water Consumed Today
  late Map<String, double> dataMapRemainingWater = <String, double>{};

  // Water Consumed Last 2 Hours
  late Map<String, double> dataMapWaterLevel = <String, double>{};

  String? mtoken = " ";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    retrieveData();

    requestPermission();
    getToken();
    initInfo();
  }

  /// ********************Push Notification Functions***************************
  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAA4Z7203g:APA91bExCpbQvt9-pSodRFgw92jnr4xmtHcC8DNKA7FdrPtc8PI8Y6YWWIIxo3piySHwamccEy5mGg6N6iEnYxGcS1oBE8lCiHZNVSoidsv35_UX4In3ccw1lBaraGtzz1438SRZADfY',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            "notification": <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "dbfood"
            },
            "to": token,
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("error push notification");
      }
    }
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accpeted permission');
    }
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;
        print("My token is $mtoken");
      });
      saveToken(token!);
    });
  }

  void saveToken(String token) async {
    try {
      await databaseRef.child('user').update({
        'token': token,
      });
      print("Token Saved");
    } catch (error) {
      print("Token was not saved. $error");
    }
  }

  /// ************************Initialization Function***************************
  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationsSettings =
        InitializationSettings(android: androidInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationsSettings,
        onDidReceiveNotificationResponse: (NotificationResponse payLoad) async {
      try {
        if (payLoad != null /*&& payLoad.isNotEmpty*/) {
        } else {}
      } catch (e) {}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("....................onMessage....................");
      print(
          "onMessage: ${message.notification?.title}/${message.notification?.body}");

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'dbfood', 'dbfood', importance: Importance.high,
        styleInformation: bigTextStyleInformation,
        priority: Priority.high,
        playSound: false,
        //sound: const RawResourceAndroidNotificationSound('notification'),
      );
      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
          message.notification?.body, platformChannelSpecifics,
          payload: message.data['body']);
    });
  }

  /// ****************Converting retrieved json data to Map type****************
  jsonStringToMap(String data) {
    String trimmedData = data.substring(1, data.length - 1);
    //print("Trimmed: $trimmedData");

    // Extract values between curly braces
    RegExp regExp = RegExp(r'{(.*?)}');
    Iterable<Match> matches = regExp.allMatches(trimmedData);

    List<String> jsonList = [];

    // Iterate over matches and print the values
    for (Match match in matches) {
      String? matchValue = match.group(1);
      //print(matchValue);

      List<String>? keyValuePairs = matchValue?.split(",");

      String? formattedData = keyValuePairs?.map((pair) {
        List<String> parts = pair.split(":");
        String key = parts[0].trim();
        String value = parts[1].trim();
        return '"$key": "$value"';
      }).join(", ");

      //print(formattedData);

      String enclosedJsonString = '{${formattedData!}}';
      //print(enclosedJsonString);

      jsonList.add(enclosedJsonString);
    }

    List<dynamic> parsedList =
        jsonList.map((jsonString) => json.decode(jsonString)).toList();

    // Sort the list of JSON objects by timestamp in ascending order
    parsedList.sort((a, b) =>
        int.parse(a['timestamp']).compareTo(int.parse(b['timestamp'])));

    // Convert the sorted list back to a List<String>
    List<String> sortedJsonList =
        parsedList.map((jsonObject) => json.encode(jsonObject)).toList();

    return sortedJsonList;
  }

  /// ****************************All Calculations******************************
  Future<void> convertData(Object dataObject) async {
    String dataString = dataObject.toString();

    final dataList = jsonStringToMap(dataString);

    // Get the last battery percentage from last element
    Map<String, dynamic> jsonLastElement = jsonDecode(dataList.last);
    batteryPercentage = int.parse(jsonLastElement['batteryPercentage']);

    // Selecting Today's data
    DateTime today = DateTime.now();
    int currentTimestamp = today.millisecondsSinceEpoch ~/ 1000;

    List<dynamic> parsedList = dataList.map((jsonString) => json.decode(jsonString)).toList();


    /**************************************************************************/
    /**************************Daily Consumption*******************************/
    // Filter the list to get objects with today's date
    List<dynamic> todayData = parsedList.where((obj) {
      int timestamp = int.parse(obj['timestamp']);
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return dateTime.year == today.year &&
          dateTime.month == today.month &&
          dateTime.day == today.day;
    }).toList();

    // Sum the waterVolume attribute for today's date
    int sum = 0;
    for (var obj in todayData) {
      int waterVolume = int.parse(obj['waterVolume']);
      sum += waterVolume;
    }
    /**************************************************************************/


    /**************************************************************************/
    /************************2 Hourly Goal*************************************/
    // Calculate the timestamp for 2 hours ago
    int twoHoursAgoTimestamp = currentTimestamp - (2 * 60 * 60);

    // Filter the data points within the last 2 hours
    List<dynamic> filteredDataForLast2Hours = todayData
        .where((data) => int.parse(data['timestamp']) > twoHoursAgoTimestamp)
        .toList();

    // Sum the waterVolume attribute for last 2 hours
    int sumLast2Hours = 0;
    bool horizontalFlag = false;

    for (var obj in filteredDataForLast2Hours) {
      int waterVolume = int.parse(obj['waterVolume']);
      sumLast2Hours += waterVolume;

      // Flag if bottle is horizontal in Last 2 Hours
      if (obj['horizontal'] == 'true'){
        horizontalFlag = true;
      }
    }
    /**************************************************************************/

    setState(() {
      userconsumed = sum.toDouble();
      userconsumedLast2Hours = sumLast2Hours.toDouble();
    });

    // Water Consumed Today
    dataMapRemainingWater = {
      "Consumed": userconsumed, // Consumed amount of water
      "Remaining": usergoal - userconsumed, // Remaining amount of water
    };

    // 2 Hourly Goal
    dataMapWaterLevel = {
      "Consumed": userconsumedLast2Hours,
      // Remaining amount of water
      "Remaining": (usergoal / 12) - userconsumedLast2Hours,
      // Consumed amount of water (8am to 8pm)
    };

    /***************************************************************************/
    /****************************Sending Notifications**************************/
    final cron = Cron();

    // Notifications every 2 hours (60 mins x 2)
    cron.schedule(Schedule.parse('*/120 * * * *'), () async {

      retrieveData();
      // Notification if bottle is kept horizontal in Last 2 Hours
      if (horizontalFlag == true){
        sendPushMessage(mtoken!, "Please keep the bottle in vertical position.", "Hydr8");
      } else {
        sendPushMessage(mtoken!, "Reminder! Stay Hydrated.", "Hydr8");
      }
    });

    // Notification when landing on page
    sendPushMessage(mtoken!, "Reminder! Stay Hydrated.", "Hydr8");

    // Notification if water NOT consumed in Last 2 Hours
    if(sumLast2Hours == 0){
      print("Send push notification");
      //String token = "ddJzOPgeQPm4nUlv5Fc-SR:APA91bEeg1-Mo_4a6b_Dq6j4LusbJukdhF73He8QQFDfoGoUpHgFiQiBx9JG2B1XTXhTv-XHF8I2Jwbk8fPmXQmtVCZHKnzg8aWa_3ZtluSsRqzO8APdiPJz4xuSHu5wKV5rzdBCyei8";
      sendPushMessage(mtoken!, "Reminder! Stay Hydrated.", "Hydr8");
    }

    // Notification when battery < 20
    if (batteryPercentage < 20) {
      print("Low battery. Send push notification");
      sendPushMessage(mtoken!,
          "Your device is running out of battery. Please recharge.", "Hydr8");
    }

    /***************************************************************************/
  }

  /// ********************Retrieving Data from Database*************************
  void retrieveData() {
    _databaseReferenceUser.child('goal').onValue.listen((event) {
      setState(() {
        usergoal = double.parse(event.snapshot.value.toString());
      });
    });

    _databaseReference.onValue.listen((event) {
      setState(() {
        data = event.snapshot.value.toString();

        final dataObject = event.snapshot.value;
        convertData(dataObject!);
      });
    });
  }

  // Water Consumed Today
  final colorListRemainingWater = <Color>[
    const Color(0xFF1b95e0),
    //Colors.grey,
    Colors.white.withOpacity(0.5)
  ];

  // Water Consumed Last 2 Hours
  final colorListWaterLevel = <Color>[
    const Color(0xFF1b95e0),
    //Colors.grey,
    Colors.white.withOpacity(0.5)
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            title:
                Text(widget.title, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: RefreshIndicator(
            color: const Color(0xFF000033),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                //height: 1500,
                margin: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.04, //0.04
                    horizontal: MediaQuery.of(context).size.width * 0.04),
                child: data == null ||
                        dataMapRemainingWater == {} ||
                        dataMapWaterLevel == {}
                    ? const Center(
                        heightFactor: 10, child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[

                          // Water Consumed Today
                          PieChart(
                            dataMap: dataMapRemainingWater,
                            animationDuration: const Duration(milliseconds: 800),
                            chartLegendSpacing: 32,
                            chartRadius: MediaQuery.of(context).size.width / 2.5,
                            colorList: colorListRemainingWater,
                            initialAngleInDegree: -90,
                            chartType: ChartType.ring,
                            //ringStrokeWidth: 15,
                            centerText: "Daily\nGoal\n(ml)",
                            centerTextStyle: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
                            legendOptions: const LegendOptions(
                              showLegends: false,
                              showLegendsInRow: true,
                              legendPosition: LegendPosition.bottom,
                              //legendShape: _BoxShape.circle,
                              legendTextStyle: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            chartValuesOptions: const ChartValuesOptions(
                              showChartValueBackground: false,
                              showChartValues: true,
                              chartValueStyle: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              showChartValuesInPercentage: false,
                              showChartValuesOutside: true,
                              decimalPlaces: 0,
                            ),
                          ),

                          const SizedBox(
                            height: 50,
                          ),

                          // Water Consumed every 2 hours
                          PieChart(
                              dataMap: dataMapWaterLevel,
                              animationDuration: const Duration(milliseconds: 800),
                              chartLegendSpacing: 32,
                              chartRadius: MediaQuery.of(context).size.width / 2.5,
                              colorList: colorListWaterLevel,
                              initialAngleInDegree: -90,
                              chartType: ChartType.ring,
                              //ringStrokeWidth: 15,
                              centerText: "2 Hourly\nGoal\n(ml)",
                              centerTextStyle: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
                              legendOptions: const LegendOptions(
                                showLegendsInRow: true,
                                legendPosition: LegendPosition.bottom,
                                showLegends: true,
                                //legendShape: _BoxShape.circle,
                                legendTextStyle: TextStyle( color: Colors.white,),
                              ),
                              chartValuesOptions: const ChartValuesOptions(
                                showChartValueBackground: false,
                                chartValueStyle: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                showChartValues: true,
                                showChartValuesInPercentage: false,
                                showChartValuesOutside: true,
                                decimalPlaces: 0,
                              ),
                              // gradientList: ---To add gradient colors---
                              // emptyColorGradient: ---Empty Color gradient---
                            ),

                          const SizedBox(
                            height: 40,
                          ),

                          // Battery Level
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                        width: 5.0, color: Colors.white),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8.0)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      width: 70.0,
                                      height: 30.0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Container(
                                            color: 33 <= batteryPercentage
                                                ? Colors.green
                                                : Colors.red,
                                            width: 20,
                                            height: 30,
                                          ),
                                          Container(
                                            color: 33 <= batteryPercentage
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: 20,
                                            height: 30,
                                          ),
                                          Container(
                                            color: 66 < batteryPercentage
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: 20,
                                            height: 30,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  " ${batteryPercentage.toString()}%",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    letterSpacing: 2,
                                    color: Color(0xFFF5F5F5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
              ),
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
                    decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                  ),
                ),
                ListTile(
                  selected: false,
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text(
                    ' Profile',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyProfilePage(
                                title: 'Profile',
                              )),
                    );
                  },
                ),
                ListTile(
                  selected: true,
                  leading:
                      const Icon(Icons.track_changes, color: Color(0xFF2ea5e4)),
                  title: const Text(
                    ' Track',
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
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ))),
    );
  }
}
