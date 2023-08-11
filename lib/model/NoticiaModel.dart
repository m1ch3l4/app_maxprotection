// @dart=2.9
import 'package:intl/intl.dart';

class NoticiaData{
  String id;
  String data;
  String titulo;
  String texto;
  String categoria;
  String url;
  String imageFile;

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
    id = json['id'].toString();
    titulo = json['title'];
    data = df.format(DateTime.parse(json['date']));
    texto = json['texto'];
    categoria = json['categoria'];
    url = json['url'];
    imageFile = json['imageFile'];
  }
}