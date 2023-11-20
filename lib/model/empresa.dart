import 'dart:convert';

import 'package:equatable/equatable.dart';

class Empresa extends Equatable{
  String? id;
  String? name;
  int? novo;
  int? aguardando;
  int? atendimento;
  bool? siem;
  bool? zabbix;

  Empresa(this.id,this.name);

  void setNovo(int novo){
    this.novo = novo;
  }
  void setAguardando(int aguard){
    this.aguardando = aguard;
  }
  void setAtendimento(int atd){
    this.atendimento = atd;
  }
  void setSiem(bool siem){
    this.siem = siem;
  }
  void setZabbix(bool zab){
    this.zabbix = zab;
  }

  /** Empresa.data([this.id,this.name]){
    this.id??="1";
    this.name??="name";
  }**/

  /** String get getName=>name;
  String get getId=>id; **/

  Empresa.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    siem = json["siem"];
    zabbix = json["zabbix"];
  }

  Map toJson() => {
    'id': id,
    'name': name,
    'siem':siem,
    'zabbix':zabbix
  };

  @override
  // TODO: implement props
  List<Object> get props => [id!];

}