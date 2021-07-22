import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Requester {
  static Future<Map?> makeGetRequest(String path,
      {Map<String, dynamic>? query}) async {
    final spI = await SharedPreferences.getInstance();
    final urlString = spI.getString("serverUrl");
    final jwt = spI.getString("JWT");
    if (urlString == null || jwt == null) return null;
    final _uri = Uri.parse(urlString);
    final res = await http.get(_uri.replace(path: path, queryParameters: query),
        headers: {"authorization": jwt});
    return jsonDecode(res.body);
  }

  static Future<Map?> makePostRequest(String path, Map body) async {
    final spI = await SharedPreferences.getInstance();
    final urlString = spI.getString("serverUrl");
    final jwt = spI.getString("JWT");
    if (urlString == null || jwt == null) return null;
    final _uri = Uri.parse(urlString);
    final res = await http.post(_uri.replace(path: path),
        headers: {"authorization": jwt, "content-type": "application/json"},
        body: jsonEncode(body));
    return jsonDecode(res.body);
  }

  static Future<Map?> makeDeleteRequest(String path, Map body) async {
    final spI = await SharedPreferences.getInstance();
    final urlString = spI.getString("serverUrl");
    final jwt = spI.getString("JWT");
    if (urlString == null || jwt == null) return null;
    final _uri = Uri.parse(urlString);
    final res = await http.delete(_uri.replace(path: path),
        headers: {"authorization": jwt, "content-type": "application/json"},
        body: jsonEncode(body));
    return jsonDecode(res.body);
  }
}
