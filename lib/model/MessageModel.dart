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
  String enterprise;
  String aid;
  String msgid;

  MessageData.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('dd/MM HH:mm');
    title = json['title'];
    data = df.format(DateTime.parse(json['data']));
    text = json['text'];
    type = json['tipo'];
    id = json['id'];
    enterprise = json['enterprise'];
    aid = json['aid'];
    msgid = json['msgid'];
  }

  MessageData.fromJsonLS(Map<String, dynamic> json) {
    title = json['title'];
    data = json['data'];
    text = json['text'];
    type = json['type'];
    id = json['id'];
    enterprise = json['enterprise'];
    aid = json['aid'];
    msgid = json['msgid'];
  }

  toJSON() {
    Map<String, dynamic> m = new Map();
    m['id'] = id;
    m['title'] = title;
    m['data'] = data;
    m['text'] = text;
    m['type'] = type;
    m['enterprise'] = enterprise;
    m['aid'] = aid;
    m['msgid'] = msgid;

    return m;
  }
}