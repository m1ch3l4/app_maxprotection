import 'dart:convert';

import 'package:equatable/equatable.dart';

class Empresa extends Equatable{
  late String id;
  late String name;
  late int novo;
  late int aguardando;
  late int atendimento;

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

  /** Empresa.data([this.id,this.name]){
    this.id??="1";
    this.name??="name";
  }**/

  /** String get getName=>name;
  String get getId=>id; **/

  Empresa.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map toJson() => {
    'id': id,
    'name': name
  };

  @override
  // TODO: implement props
  List<Object> get props => [id];

}