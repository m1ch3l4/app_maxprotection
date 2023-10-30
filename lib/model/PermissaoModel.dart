class Permissao{
  int? id;
  String? nome;
  bool? criar;
  bool? editar;
  bool? visualizar;
  bool? excluir;
  bool? meus;
  bool? todos;

  Permissao(this.nome,this.meus);

  Permissao.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    criar = json['criar'];
    editar = json['editar'];
    visualizar = json['visualizar'];
    excluir = json['excluir'];
    meus = json['meus'];
    todos = json['todos'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;
    data["nome"] = this.nome;
    data["criar"] = this.criar;
    data["editar"] = this.editar;
    data["visualizar"] = this.visualizar;
    data["excluir"] = this.excluir;
    data["meus"] = this.meus;
    data["todos"] = this.todos;
    return data;
  }
}