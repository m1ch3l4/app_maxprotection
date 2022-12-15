//@dart=2.9
import 'package:intl/intl.dart';

class AlertData {
  String id;
  String title;
  String data;
  String text;
  String categoria;
  String empresa;
  String total;
  String status;
  String link;
  String linkSoc;

  AlertData.data([this.title,this.data,this.text,this.categoria]) {
    // Set these rather than using the default value because Firebase returns
    // null if the value is not specified.
    this.title ??= 'Título';
    this.data ??= 'dd/MM/yyyy';
    this.text ??='text';
    this.categoria ??= 'Categoria do Evento';
    this.status ??="LOW";
    this.total ??="0";
    this.link ??="";
    this.linkSoc ??="";
  }

  void setEmpresa(String emp){
    this.empresa = emp;
  }

  AlertData.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('dd/MM HH:mm');
    id = json['id'].toString();
    title = json['title'];
    data = df.format(DateTime.parse(json['date']));
    text = json['texto'];
    categoria = json['category'];
    empresa = json['company']['name']; //no zabbix está vindo assim, verificar no elastic...
    //empresa = json['empresa'];
    total = json["noOcorrencia"].toString();
    status = json["status"]; //Elastic: LOW, MEDIUM, HIGH, Zabbix:
    link = json["link"];
    linkSoc = json["linkSoc"];
  }
}