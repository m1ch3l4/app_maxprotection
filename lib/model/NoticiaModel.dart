// @dart=2.9
import 'package:intl/intl.dart';

class NoticiaData{
  String data;
  String titulo;
  String texto;
  String url;

  NoticiaData.data([this.data, this.titulo,this.texto,this.url]) {
    // Set these rather than using the default value because Firebase returns
    // null if the value is not specified.
    this.titulo ??= 'Título';
    this.data ??= 'dd/MM/yyyy';
    this.texto ??='text';
    this.url ??= 'Categoria do Evento';
  }

  NoticiaData.fromJson(Map<String, dynamic> json) {
    final df = new DateFormat('yyyy-MM-dd');
    titulo = json['title'];
    data = df.format(DateTime.parse(json['date']));
    texto = json['texto'];
    url = json['url'];
  }
}