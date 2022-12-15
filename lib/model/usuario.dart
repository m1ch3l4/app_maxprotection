//@dart=2.9
import 'package:flutter/cupertino.dart';

import 'RoleModel.dart';
import 'empresa.dart';

class Usuario extends ChangeNotifier{
  String id;
  String name;
  String login;
  String senha;
  String message;
  String idempresa;
  String empresa;
  bool pmElastic;
  bool pmZabbix;
  bool pmTickets;
  bool hasAccess;
  String tipo; //T - Tecnico, C - consultor, D- Diretor
  List<Empresa> empresas; //se for [C]onsultor tera uma lista de empresas...
  Role role;
  String phone;
  bool interno;

  Usuario({this.id="", this.name="", this.login="", this.senha="", this.message="",this.idempresa="",this.empresa="",this.pmElastic=false,this.pmZabbix=false,this.pmTickets=false,tipo="T",this.interno=false});

  Usuario.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    login = json['login'];
    senha = json['password'];
    message = json['message'];
    idempresa = json['company_id'];
    empresa = json['company_name'];
    pmElastic = json['pmElastic'];
    pmZabbix = json['pmZabbix'];
    pmTickets = json['pmMoviedesk'];
    tipo = json["tipo"];
    phone = json["phone"];
    var j = json["role"];
    if(json["role"]!=null)
        role = Role.fromJson(j);
    if(tipo=="T"){
      var e = json["relacionamento"];
      print("Usuario.fromJson..."+e.toString());
      empresas = [];
      if(e!=null) {
        for (Map<String, dynamic> i in e) {
          empresas.add(Empresa.fromJson(i));
        }
      }
    }else {
      var e = json["enterpriseSet"];
      empresas = [];
      if (e != null) {
        for (Map<String, dynamic> i in e) {
          empresas.add(Empresa.fromJson(i));
        }
      }
    }
    hasAccess = json['hasAccess'];
    interno = (json['interno']!=null?json['interno']:false);
  }

  Usuario.fromCall(Map<String,dynamic> json){
    id = json['id'];
    name = json['name'];
    login = json['login'];
    senha = json['password'];
    message = json['message'];
    pmElastic = json['pmElastic'];
    pmZabbix = json['pmZabbix'];
    pmTickets = json['pmMoviedesk'];
    tipo = json["tipo"];
    phone = json["phone"];
    hasAccess = json['hasAccess'];
    interno = json['interno'];
  }
  Usuario.fromSharedPref(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    login = json['login'];
    senha = json['password'];
    message = json['message'];
    idempresa = json['company_id'];
    empresa = json['company_name'];
    pmElastic = json['pmElastic'];
    pmZabbix = json['pmZabbix'];
    pmTickets = json['pmMoviedesk'];
    tipo = json["tipo"];
    var j = json["role"];
    role = Role.fromJson(j);
    var e = json["empresas"];
    print("usuario.fromShared..."+e.toString());
      empresas = [];
      for (Map<String, dynamic> i in e) {
        empresas.add(Empresa.fromJson(i));
      }
    hasAccess = json["hasAccess"];
      interno = json['interno'];
  }

  void setEmpresas(List<Empresa> lst){
    this.empresas = lst;
  }
  void setRole(Role rol){
    this.role = rol;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['login'] = this.login;
    data['password'] = this.senha;
    data['message'] = this.message;
    data['company_id'] = this.idempresa;
    data['company_name'] = this.empresa;
    data['pm_elastic'] = this.pmElastic;
    data['pm_zabbix'] = this.pmZabbix;
    data['pm_tickets'] = this.pmTickets;
    data["tipo"] = this.tipo;
    data["role"] = this.role.toJson();
    data['empresas'] =  this.empresas != null ? this.empresas.map((i) => i.toJson()).toList() : null;
    data['hasAccess'] = this.hasAccess;
    data['interno'] = this.interno;
    return data;
  }

  String toString(){
    return this.id.toString()+"|"+this.name+"|"+this.login;
  }
}