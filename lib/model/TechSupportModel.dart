// @dart=2.9
import 'package:intl/intl.dart';
class TechSupportData{
  String title;
  String data;
  String status;
  String id;
  String justify;
  String empresa;
  String user;
  String tecnico;
  String urgencia;

  TechSupportData(this.title,this.data,this.status,this.id,this.justify,this.empresa) {
    // Set these rather than using the default value because Firebase returns
    // null if the value is not specified.
    this.title ??= '';
    this.data ??= 'dd/MM/yyyy';
    this.status ??='status';
    this.id ??= 'id';
    this.justify ??='';
    this.empresa ??='';
  }

  void setEmpresa(String emp){
    this.empresa = emp;
  }
  void setUser(String usr){
    this.user = usr;
  }
  void setTecnico(String tec){
    this.tecnico = tec;
  }
  void setUrgencia(String urgencia){
    this.urgencia = urgencia;
  }

  TechSupportData.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('dd/MM/yyyy HH:mm');
    title = json['titulo'];
    data = df.format(DateTime.parse(json['dtUpdate']));
    status = json['status'];
    id = json['internalId'].toString();
    justify = json['justifyStatus'];
    empresa = json['empresa']['name'];
    urgencia = json['urgency'];
  }

  @override
  bool operator ==(other) {
    return (other is TechSupportData)
        && other.id == id
        && other.title == title
        && other.status == status
        && other.data == data;
  }

}