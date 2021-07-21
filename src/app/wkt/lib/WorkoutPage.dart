import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:wkt/Components.dart';

import 'Requester.dart';

class WorkoutPage extends StatefulWidget {
  WorkoutPage({Key? key}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class Machine {
  final String name;
  final int reps;
  final int sets;

  Machine({
    required this.name,
    required this.reps,
    required this.sets,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      name: json['name'],
      reps: json['reps'],
      sets: json['sets'],
    );
  }
}

class _WorkoutPageState extends State<WorkoutPage> {
  String wktName = "";
  List<Machine> availableMachines = [];
  List<String> completedMachines = <String>[];

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
        child: Scaffold(
      appBar: LocalAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            Text(
              wktName,
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w600),
            ),
            ...genMachineCards()
          ],
        ),
      ),
    ));
  }

  List<Widget> genMachineCards() {
    List<Widget> cards = [];
    availableMachines.forEach((e) {
      cards.add(Card(
        child: Padding(
          padding: EdgeInsets.all(2),
          child: ListTile(
              title: Text(e.name),
              subtitle: Text(
                '${e.sets} sets of ${e.reps} reps',
                style: const TextStyle(fontWeight: FontWeight.w300),
              ),
              onTap: () async {
                if (!completedMachines.contains(e.name)) {
                  final bool = await showDialog(
                      context: context,
                      builder: (context) =>
                          MachineSelector(m: e, workout: wktName));
                  print(bool);
                  if (bool) {
                    setState(() {
                      completedMachines.add(e.name);
                    });
                  }
                }
              },
              trailing: completedMachines.contains(e.name)
                  ? Icon(Icons.check_box)
                  : Icon(Icons.check_box_outline_blank)),
        ),
      ));
    });
    return cards;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      context.loaderOverlay.show();
      initComponent();
    });
  }

  void initComponent() async {
    setState(() {
      wktName = ModalRoute.of(context)!.settings.arguments.toString();
    });
    final workouts = await Requester.makeGetRequest('/workout');
    setState(() {
      workouts!['workouts'][wktName].forEach((e) {
        availableMachines.add(Machine.fromJson(e));
      });
    });
    availableMachines.forEach((element) {
      print(element.name);
    });
    context.loaderOverlay.hide();
  }
}
