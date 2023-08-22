import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/Profile.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:weekday_selector/weekday_selector.dart';

import 'Home.dart';
import 'Login.dart';

class MyHistoryPage extends StatefulWidget {
  const MyHistoryPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHistoryPage> createState() => MyHistoryPageState();
}

class MyHistoryPageState extends State<MyHistoryPage> {

  final DatabaseReference databaseRef = FirebaseDatabase.instance.reference();
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('readings');

  String? data;

  // List of water volumes for this week
  //List<double> waterVolumesDB = [750, 500, 630, 775, 585, 800, 900];
  List<double> waterVolumesDB = [];

  @override
  void initState() {
    super.initState();
    retrieveData();
  }

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

  Future<void> convertData(Object dataObject) async {
    String dataString = dataObject.toString();

    final dataList = jsonStringToMap(dataString);

    // Selecting Today's data
    DateTime today = DateTime.now();
    int weekday = today.weekday;
    DateTime beginningOfWeek = today.subtract(Duration(days: weekday - 1));

    //print(beginningOfWeek);

    List<dynamic> parsedList = dataList.map((jsonString) => json.decode(jsonString)).toList();

    /**************************************************************************/
    // Filter the list to get objects for this week
    List<dynamic> weekData = parsedList.where((obj) {
      int timestamp = int.parse(obj['timestamp']);
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return dateTime.year == beginningOfWeek.year &&
          dateTime.month > beginningOfWeek.month &&
          dateTime.day <= beginningOfWeek.day;
    }).toList();

    //print(weekData);

    // Sum the waterVolume attribute for each date
    Map<String, double> sumByDate = {};

    for (var data in weekData) {
      if (sumByDate.containsKey(data['date'])) {
        sumByDate[data['date']] = sumByDate[data['date']]! + double.parse(data['waterVolume']);
      } else {
        sumByDate[data['date']] = double.parse(data['waterVolume']);
      }
    }

    List<Map<String, dynamic>> outputList = sumByDate.entries.map((entry) {
      return {
        'date': entry.key,
        'waterVolumeSum': entry.value,
      };
    }).toList();

    // Printing the output list
    for (var item in outputList) {
      //print(item['waterVolumeSum']);
      waterVolumesDB.add(item['waterVolumeSum']);
    }

    /**************************************************************************/

  }

  void retrieveData() {
    _databaseReference.onValue.listen((event) {
      setState(() {
        data = event.snapshot.value.toString();

        final dataObject = event.snapshot.value;
        convertData(dataObject!);
      });
    });

  }

  @override
  Widget build(BuildContext context) {

    double totalConsumption = 0.0;
    double avgWeeklyConsumption = 0.0;

    // Current Date
    DateTime now = DateTime.now();
    // Current day (eg: Mon->0, Tue->1)
    int weekdayNumber = now.weekday - 2;

    // List of water volumes for this week
    List<double> waterVolumes = waterVolumesDB;

    final List<WeeklyData> weeklyData = [];

    for(int i=0; i<=weekdayNumber; i++){
      for(int j=0; j<waterVolumes.length; j++) {
        if(i == 0){
          weeklyData.add(WeeklyData("Mon", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        } else if(i == 1){
          weeklyData.add(WeeklyData("Tue", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        } else if(i == 2){
          weeklyData.add(WeeklyData("Wed", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        } else if(i == 3){
          weeklyData.add(WeeklyData("Thu", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        } else if(i == 4){
          weeklyData.add(WeeklyData("Fri", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        } else if(i == 5){
          weeklyData.add(WeeklyData("Sat", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        } else if(i == 6){
          weeklyData.add(WeeklyData("Sun", waterVolumes[i]));
          totalConsumption += waterVolumes[i];
          break;
        }
      }
    }

    List<bool> value = [];

    for (int i=0; i<7; i++){
      if(i == 7){
        break;
      } else if(i > weekdayNumber){
        value.add(true);
      } else {
        value.add(false);
      }
    }

    bool lastValue = value.removeLast();
    value.insert(0, lastValue);

    avgWeeklyConsumption = totalConsumption / (weekdayNumber + 1);

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                            majorGridLines: const MajorGridLines(width: 0)
                        ),
                        title: ChartTitle(
                          text: 'Your Weekly Consumption',
                          textStyle: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        series: <ChartSeries>[
                          LineSeries<WeeklyData, String>(
                              dataSource: weeklyData,
                              xValueMapper: (WeeklyData weekly, _) => weekly.week,
                              yValueMapper: (WeeklyData weekly, _) => weekly.consumption,
                              dataLabelSettings: const DataLabelSettings(isVisible: true,
                                textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10
                                ),))
                        ]),

                    const SizedBox(
                      height: 70,
                    ),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Your Daily Average\n",
                            style: TextStyle(
                              fontSize: 25,
                              letterSpacing: 2,
                              color: Color(0xFFF5F5F5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 40,
                          ),
                        ],
                      ),
                    ),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_drop_rounded, color: Color(0xFF1b95e0), size: 45,),
                          Text(
                            "${avgWeeklyConsumption.toStringAsFixed(2)}ml",
                            style: const TextStyle(
                              fontSize: 45,
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
                  selected: true,
                  leading: const Icon(Icons.history, color: Color(0xFF2ea5e4)),
                  title: const Text(
                    ' Records',
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
          ))),
    );
  }
}

class WeeklyData {
  WeeklyData(this.week, this.consumption);
  final String week;
  final double consumption;
}
