import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:wkt/Components.dart';
import 'package:intl/intl.dart';

import 'Requester.dart';

class WorkoutPage extends StatefulWidget {
  final PageStorageBucket bucket;
  WorkoutPage({Key? key, required this.bucket}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState(bucket: bucket);
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
  PageStorageBucket bucket;
  List<Machine> availableMachines = [];
  List<String> completedMachines = <String>[];
  List<Widget> machineCards = [];

  _WorkoutPageState({required this.bucket});

  List<String> getCurrentCompletedMachines() {
    var state = bucket.readState(context, identifier: wktName);
    if (!(state is List<String>)) {
      bucket.writeState(context, <String>[], identifier: wktName);
      return [];
    } else {
      return state;
    }
  }

  void addToCompletedMachines(String machine) {
    var state = bucket.readState(context, identifier: wktName);
    if (!(state is List<String>)) {
      bucket.writeState(context, <String>[machine], identifier: wktName);
    } else {
      state.add(machine);
      bucket.writeState(context, state, identifier: wktName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
        child: Scaffold(
      appBar: LocalAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final dialogReturnValue = await showDialog(
              context: context,
              builder: (ctx) {
                return MachineAddDialog();
              });
          if (dialogReturnValue != null) {
            await Requester.makePostRequest('/workout/machine',
                {'workout': wktName, 'machine': dialogReturnValue});
            initComponent();
          }
        },
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            Text(
              wktName,
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w600),
            ),
            ...machineCards
          ],
        ),
      ),
    ));
  }

  Future<List<Widget>> genMachineCards() async {
    List<Widget> cards = [];
    for (var e in availableMachines) {
      var stats;
      try {
        stats = await Requester.makeGetRequest('/stats/machine',
            query: {'machine': e.name});
        if (stats['status'] == 'error') {
          stats = null;
        }
      } catch (e) {
        stats = null;
      }
      cards.add(Card(
        child: Padding(
          padding: EdgeInsets.all(2),
          child: ListTile(
              title: Text(e.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stats != null
                      ? Text(
                          'Last: ${stats['last']} lbs, 6mo Average: ${stats['sixMonth']} lbs')
                      : Text('Stats unavailable'),
                  Text(
                    '${e.sets} sets of ${e.reps} reps',
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                ],
              ),
              onTap: () async {
                if (!getCurrentCompletedMachines().contains(e.name)) {
                  final bool = await showDialog(
                      context: context,
                      builder: (context) =>
                          MachineSelector(m: e, workout: wktName));
                  if (bool != null && bool == true) {
                    setState(() {
                      addToCompletedMachines(e.name);
                    });
                  }
                }
              },
              onLongPress: () async {
                if (await confirm(context,
                    title: Text("Are you sure you want to delete ${e.name}?"),
                    content: Text(
                        "Machine data will remain and will repropagate if a machine with the same name is added"))) {
                  await Requester.makeDeleteRequest('/workout/machine',
                      {"workout": wktName, "machineName": e.name});
                  initComponent();
                }
              },
              trailing: getCurrentCompletedMachines().contains(e.name)
                  ? Icon(Icons.check_box)
                  : Icon(Icons.check_box_outline_blank)),
        ),
      ));
    }
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
    DateTime dt = DateTime.now();
    if (workouts!['lastWorkout'] != DateFormat('M-d-yyyy').format(dt)) {
      bucket.writeState(context, <String>[], identifier: wktName);
    }
    availableMachines.clear();
    setState(() {
      workouts['workouts'][wktName].forEach((e) {
        availableMachines.add(Machine.fromJson(e));
      });
    });
    final cards = await genMachineCards();
    setState(() {
      machineCards = cards;
    });
    context.loaderOverlay.hide();
  }
}
