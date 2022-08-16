// @dart=2.10
import 'package:intl/intl.dart';
class MessageData{
  MessageData({this.title,this.text,this.type});

  String id;
  String title;
  String text;
  String data;
  String type;
  String sender;

  MessageData.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('dd/MM HH:mm');
    title = json['title'];
    data = df.format(DateTime.parse(json['data']));
    text = json['text'];
    type = json['tipo'];
    id = json['id'];
  }

  MessageData.fromJsonLS(Map<String, dynamic> json) {
    title = json['title'];
    data = json['data'];
    text = json['text'];
    type = json['type'];
    id = json['id'];
  }

  toJSON() {
    Map<String, dynamic> m = new Map();
    m['id'] = id;
    m['title'] = title;
    m['data'] = data;
    m['text'] = text;
    m['type'] = type;

    return m;
  }
}