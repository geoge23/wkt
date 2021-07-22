import 'package:flutter/material.dart';
import 'package:wkt/Requester.dart';

import 'WorkoutPage.dart';

class LocalAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext ctx) {
    return AppBar(
      title: Row(children: [
        Padding(
          padding: EdgeInsets.only(right: 5),
          child: Icon(Icons.line_weight_outlined),
        ),
        Text('wkt')
      ]),
      actions: [
        ModalRoute.of(ctx)!.settings.name == '/'
            ? IconButton(
                onPressed: () => print('test'), icon: Icon(Icons.settings))
            : Text(''),
      ],
    );
  }
}

class MachineAddDialog extends StatefulWidget {
  MachineAddDialog({Key? key}) : super(key: key);

  @override
  _MachineAddDialogState createState() => _MachineAddDialogState();
}

class _MachineAddDialogState extends State<MachineAddDialog> {
  Map<String, dynamic> machineInfo = {'name': '', 'sets': -1, 'reps': -1};
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel')),
          TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context, machineInfo);
                }
              },
              child: Text('Add'))
        ],
        content: SingleChildScrollView(
            child: ListBody(
          children: [
            Text(
              'Add a new machine',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Form(
                key: formKey,
                child: ListBody(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        onSaved: (newValue) => machineInfo['name'] = newValue,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field missing or invalid';
                          }
                          return null;
                        },
                        decoration: InputDecoration(hintText: "Machine Name"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        onSaved: (newValue) =>
                            machineInfo['sets'] = int.parse(newValue!),
                        validator: (value) {
                          if (value == null ||
                              int.tryParse(value) == null ||
                              int.tryParse(value)! > 20) {
                            return 'Field missing or invalid';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: '2 sets', suffixText: 'sets'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        onSaved: (newValue) =>
                            machineInfo['reps'] = int.parse(newValue!),
                        validator: (value) {
                          if (value == null ||
                              int.tryParse(value) == null ||
                              int.tryParse(value)! > 50) {
                            return 'Field missing or invalid';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: '10 reps', suffixText: 'reps'),
                      ),
                    )
                  ],
                ))
          ],
        )));
  }
}

class MachineSelector extends StatefulWidget {
  final Machine m;
  final String workout;

  MachineSelector({Key? key, required this.m, required this.workout})
      : super(key: key);

  @override
  _MachineSelectorState createState() =>
      _MachineSelectorState(m: m, workout: workout);
}

class _MachineSelectorState extends State<MachineSelector> {
  final Machine m;
  final String workout;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List vals = [];

  _MachineSelectorState({required this.m, required this.workout});

  String? numValidator(value) {
    if (value == null ||
        int.tryParse(value) == null ||
        int.tryParse(value)! > 300) {
      return 'Field missing or invalid';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              '${m.name}',
              style: TextStyle(fontSize: 25),
            ),
            Form(
              key: formKey,
              child: ListBody(
                children: genSetCards(),
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                vals.forEach((element) async {
                  try {
                    print(element);
                    print(await Requester.makePostRequest('/action', element));
                  } catch (e) {
                    print(e);
                    final snackBar = SnackBar(
                        backgroundColor: Color.fromRGBO(250, 0, 0, 1),
                        content: Text(
                            'Error connecting to server. Please try again.'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;
                  }
                });
                vals.clear();
                Navigator.pop(context, true);
              }
            },
            child: Text('Complete'))
      ],
    );
  }

  List<Widget> genSetCards() {
    List<Widget> cards = [];
    for (var i = 1; i <= m.sets; i++) {
      cards.addAll([
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text('Set $i'),
        ),
        TextFormField(
            keyboardType: TextInputType.number,
            onSaved: (v) {
              vals.add({
                'workout': workout,
                'machine': m.name,
                'weight': int.parse(v!),
                'reps': m.reps,
                'set': i
              });
            },
            validator: numValidator,
            decoration: InputDecoration(hintText: '0.0', suffixText: 'lbs'))
      ]);
    }
    return cards;
  }
}
