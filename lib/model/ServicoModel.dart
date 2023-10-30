class Servico{
  String? id;
  String? titulo;
  String? descricao;
  bool? contratado;

  Servico.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    titulo = json['titulo'];
    descricao = json['descricao'];
    contratado = json['contratado'];
  }
}