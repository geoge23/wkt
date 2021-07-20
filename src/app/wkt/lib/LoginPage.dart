import 'package:flutter/material.dart';
import 'Components.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'host': TextEditingController(),
    'user': TextEditingController(),
    'pass': TextEditingController()
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LocalAppBar(),
      body: Column(
        children: [
          Text(
            'Login',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 40),
            textAlign: TextAlign.center,
          ),
          Text(
            'Please fill in these details to connect to your server',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(
                        hintText: "Host (i.e. wkt.example.com)"),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(hintText: "Username"),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(hintText: "Password"),
                  ),
                ),
                ElevatedButton(
                    onPressed: () => print('test'),
                    child: Text('Connect to server'))
              ],
            ),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }
}
