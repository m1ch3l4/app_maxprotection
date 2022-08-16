// @dart=2.9
import 'dart:convert';

import 'package:intl/intl.dart';

import 'moviedesk/Action.dart';
import 'moviedesk/Owner.dart';
import 'moviedesk/Person.dart';

class Ticket{
  String id;
  String title;
  String data;
  String created;
  String status;
  String category;
  String justify;
  String origin;
  String type;
  String urgency;
  String serviceFirstLevel;
  String serviceSecondLevel;
  String cc;
  Person client;
  Owner owner;
  List<ActionLog> actions;


  Ticket.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('dd/MM/yyyy HH:mm');
    title = json['subject'];
    data = df.format(DateTime.parse(json['lastUpdate']));
    created = df.format(DateTime.parse(json['createdDate']));
    status = json['status'];
    id = json['id'].toString();
    justify = json['justify'];
    origin = json["origin"];
    type = json["type"];
    urgency = json["urgency"];
    serviceFirstLevel = json["serviceFirstLevel"];
    serviceSecondLevel = json["serviceSecondLevel"];
    cc = json["cc"];
    category = json["category"];
    var c = json['clients'];
    if(c!=null)
      client = Person.fromJson(json['clients'][0]);
    var o = json['owner'];
    if(o!=null)
      owner = Owner.fromJson(json['owner']);
    var act = json["actions"];
    List<ActionLog> lst = [];
    if(act!=null){
      for(Map i in act){
        lst.add(ActionLog.fromJson(i));
      }
      actions = lst;
    }
  }
}