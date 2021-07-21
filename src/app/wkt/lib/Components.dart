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
                    await Requester.makePostRequest('/action', element);
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
