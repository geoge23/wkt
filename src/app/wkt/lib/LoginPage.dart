import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Components.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'host': TextEditingController(),
    'username': TextEditingController(),
    'password': TextEditingController()
  };

  void connectToServer() async {
    if (_formKey.currentState == null) return;
    if (_formKey.currentState!.validate()) {
      final Uri serverLoginUrl =
          Uri.parse('${controllers['host']!.text}/auth/login');
      final outgoingJson = jsonEncode(<String, String>{
        "username": controllers["username"]!.text,
        "password": controllers["password"]!.text
      });
      context.loaderOverlay.show();
      try {
        final res = await http.post(serverLoginUrl,
            body: outgoingJson,
            headers: <String, String>{"content-type": "application/json"});
        var jsonResponse = jsonDecode(res.body.toString());
        final spI = await SharedPreferences.getInstance();
        if (jsonResponse['jwt'] == null || !(jsonResponse['jwt'] is String))
          throw new HttpException("No JWT in response");
        spI.setString('JWT', jsonResponse['jwt']);
        spI.setString('serverUrl', controllers['host']!.text);
        spI.setBool('appSetupComplete', true);
        context.loaderOverlay.hide();
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (Route<dynamic> route) => false);
      } on SocketException catch (e) {
        context.loaderOverlay.hide();
        print(e);
        final snackBar = SnackBar(
            backgroundColor: Color.fromRGBO(250, 0, 0, 1),
            content: Text(
                'Error connecting to server. URL may be invalid. Please try again.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } on HttpException catch (e) {
        context.loaderOverlay.hide();
        print(e);
        final snackBar = SnackBar(
            backgroundColor: Color.fromRGBO(250, 0, 0, 1),
            content: Text(
                'Error communicating with server. Please check server logs for more info'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      final snackBar = SnackBar(
          content: Text('Form invalid. Please correct the errors and retry'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  String? textValidator(value) {
    if (value == null || value.isEmpty) {
      return 'Field missing or invalid';
    }
    return null;
  }

  @override
  void initState() {
    print('test');
    SharedPreferences.getInstance().then((value) {
      var appSetup = value.getBool('appSetupComplete');
      if (appSetup != null && appSetup == true) {
        print(value.getKeys());
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (Route<dynamic> route) => false);
        //For testing only!
        // value.clear();
      } else {
        print('not setup');
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
        child: Scaffold(
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
                    controller: controllers['host'],
                    validator: (value) {
                      RegExp urlRegex = RegExp(
                          r"https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)");
                      if (value == null ||
                          value.isEmpty ||
                          !urlRegex.hasMatch(value)) {
                        return 'URL field missing or invalid';
                      } else {
                        return null;
                      }
                    },
                    decoration: InputDecoration(
                        hintText: "Host (i.e. wkt.example.com)"),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: TextFormField(
                    controller: controllers['username'],
                    validator: textValidator,
                    decoration: InputDecoration(hintText: "Username"),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: TextFormField(
                    controller: controllers['password'],
                    obscureText: true,
                    validator: textValidator,
                    decoration: InputDecoration(hintText: "Password"),
                  ),
                ),
                ElevatedButton(
                    onPressed: connectToServer,
                    child: Text('Connect to server'))
              ],
            ),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    ));
  }
}
