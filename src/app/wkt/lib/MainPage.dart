import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Components.dart';
import 'Requester.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageStorageBucket bucket = PageStorageBucket();
  String todaysWorkout = 'none';
  Map<String, dynamic>? availableWorkouts;

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
        child: Scaffold(
            appBar: LocalAppBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final wktNewName =
                    await prompt(context, title: Text("Name new workout"));
                if (wktNewName == null || !(wktNewName is String)) return;
                await Requester.makePostRequest(
                    '/workout', {"name": wktNewName, "exercises": []});
                initComponent();
                navToWktScreen(wktNewName);
              },
              child: Icon(Icons.add),
            ),
            body: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView(
                children: [
                  Text(genGreeting(),
                      textAlign: TextAlign.left,
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.w600)),
                  Text(
                    "Today's workout is $todaysWorkout",
                    style: TextStyle(
                        fontSize: 25,
                        color: Color.fromRGBO(45, 45, 45, 1),
                        fontWeight: FontWeight.w300),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: () => navToWktScreen(todaysWorkout),
                        child: Row(
                          children: [
                            Text("Start this workout"),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.send),
                            )
                          ],
                          mainAxisAlignment: MainAxisAlignment.center,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "Alternatively, start one of these",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                  ),
                  ...genWktCards()
                ],
              ),
            )));
  }

  String genGreeting() {
    var timeNow = DateTime.now().hour;
    if (timeNow <= 12) {
      return 'Good morning';
    } else if ((timeNow > 12) && (timeNow <= 16)) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  List<Widget> genWktCards() {
    List<Widget> wktCards = [];
    if (availableWorkouts == null) return [];
    availableWorkouts!.forEach((k, v) {
      wktCards.add(Card(
        child: Column(
          children: [
            ListTile(
              title: Text(k),
              onTap: () => navToWktScreen(k),
              onLongPress: () async {
                if (await confirm(context,
                    title: Text("Are you sure you want to delete $k?"),
                    content: Text(
                        "Machine data will remain, but the workout cannot be recovered"))) {
                  await Requester.makeDeleteRequest('/workout', {"name": k});
                  initComponent();
                }
              },
            )
          ],
        ),
      ));
    });
    return wktCards;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      initComponent();
    });
  }

  void initComponent() async {
    final wktDay = await Requester.makeGetRequest("/workout");
    if (wktDay == null) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (Route<dynamic> route) => false);
      return;
    }
    setState(() {
      todaysWorkout = wktDay['todaysWorkout'];
      availableWorkouts = wktDay['workouts'];
    });
  }

  navToWktScreen(String workoutName) {
    Navigator.pushNamed(context, '/workouts', arguments: workoutName);
  }
}
