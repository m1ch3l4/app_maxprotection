import 'package:app_maxprotection/model/usuario.dart';

class ChatData{
  DateTime? data;
  String? texto;
  String? tipo;
  Usuario? sender;

  ChatData.data([this.data, this.texto,this.tipo]) {
    // Set these rather than using the default value because Firebase returns
    // null if the value is not specified.
    this.data ??= DateTime.now();
    this.texto ??='text';
    this.tipo ??= 'default';
  }

  ChatData.fromJson(Map<String, dynamic> json) {
    data = DateTime.parse(json['data']);
    texto = json['text'];
    tipo = json['tipo'];
    if(json["sender"]!=null) {
      var e = json['sender'];
      sender = Usuario.fromJson(e);
    }
  }
}