import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Requester {
  static Future<Map?> makeGetRequest(String path) async {
    final spI = await SharedPreferences.getInstance();
    final urlString = spI.getString("serverUrl");
    final jwt = spI.getString("JWT");
    if (urlString == null || jwt == null) return null;
    final _uri = Uri.parse(urlString);
    final res = await http
        .get(_uri.replace(path: path), headers: {"authorization": jwt});
    return jsonDecode(res.body);
  }

  static Future<Map?> makePostRequest(String path, Map body) async {
    final spI = await SharedPreferences.getInstance();
    final urlString = spI.getString("serverUrl");
    final jwt = spI.getString("JWT");
    if (urlString == null || jwt == null) return null;
    final _uri = Uri.parse(urlString);
    final res = await http.post(_uri.replace(path: path),
        headers: {"authorization": jwt}, body: jsonEncode(body));
    return jsonDecode(res.body);
  }
}
