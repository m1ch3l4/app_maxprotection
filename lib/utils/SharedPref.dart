import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPref {

  read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getString(key);
    if(value!=null)
      return json.decode(value);
  }

  getValue(String key) async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}
