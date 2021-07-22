import 'package:flutter/material.dart';
import 'MainPage.dart';
import 'WorkoutPage.dart';
import 'LoginPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final PageStorageBucket bucket = PageStorageBucket();
    return MaterialApp(
        title: 'wkt',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
        ),
        routes: {
          '/login': (ctx) => LoginPage(),
          '/': (ctx) => MainPage(),
          '/workouts': (ctx) => WorkoutPage(bucket: bucket)
        },
        initialRoute: '/login');
  }
}
