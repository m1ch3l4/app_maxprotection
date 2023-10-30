import 'package:flutter/cupertino.dart';

class DashboardData{
  int? siem;
  int? zabbix;
  int? open;
  int? novo=0;
  int? close;
  int? waiting;
  int? msgSiem;
  int? msgZabbix;
  int? msgTicket;
  int? msgLead;

  DashboardData.data([this.siem,this.zabbix,this.open,this.close,this.waiting,this.novo]) {
    this.siem ??= 0;
    this.zabbix ??=0;
    this.open ??= 0;
    this.close ??= 0;
    this.waiting ??=0;
    this.novo ??=0;
    this.msgSiem ??= 0;
    this.msgLead ??=0;
    this.msgTicket??= 0;
  }

  DashboardData.fromJson(Map<String, dynamic> json){
    siem = (json['siem']!=null?json['siem']:0);
    zabbix = (json['zabbix']!=null?json['zabbix']:0);
    open = json['open'];
    close = json['close'];
    waiting = json['waiting'];
    novo = (json['novo']!=null?json['novo']:0);
    novo = novo! + waiting!;
    novo = novo! + open!;
    msgLead = (json['msgLead']!=null?json['msgLead']:0);
    msgSiem = (json['msgSiem']!=null?json['msgSiem']:0);
    msgZabbix = (json['msgZabbix']!=null?json['msgZabbix']:0);
    msgTicket = (json['msgTicket']!=null?json['msgTicket']:0);
  }
}