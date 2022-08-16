// @dart=2.9

import 'package:intl/intl.dart';

import 'ActionCreator.dart';

class ActionLog{
  int id;
  int type;
  int origin;
  String description;
  String htmlDescription;
  String status;
  String justification;
  String createdDate;
  ActionCreator createdBy;
  bool isDeleted;

  ActionLog.data([this.id=0,this.type=0,this.origin=0,this.description="-",this.htmlDescription="-",this.status="-",this.justification="-",this.createdDate="-"]){
    this.id ??= 0;
    this.type ??=0;
    this.origin ??=0;
    this.description ??="-";
    this.htmlDescription ??="-";
    this.status ??="-";
    this.justification ??="-";
    this.createdDate ??="-";
  }

  ActionLog.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('dd/MM/yyyy HH:mm');
    description = (json['description']!=null? json['description']:"-");
    htmlDescription = (json['htmlDescription']!=null ? json['htmlDescription']:"-");
    status = (json["status"]!=null?json['status']:"-");
    justification = (json['justification']!=null?json['justification']:"-");
    createdDate = df.format(DateTime.parse(json['createdDate']));
    id = json["id"];
    if(json['createdBy']!=null)
      createdBy = ActionCreator.fromJson(json['createdBy']);

  }

}