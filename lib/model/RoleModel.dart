import 'PermissaoModel.dart';

class Role{
  int? id;
  String? nome;
  List<Permissao> permissoes=[];

  Role.fromJson(Map<String, dynamic> json){
    id = json["id"];
    nome = json["nome"];
    permissoes = [];
    if(json['permissoes']!=null) {
      for (Map<String, dynamic> j in json['permissoes']) {
        permissoes.add(Permissao.fromJson(j));
      }
    }
  }
  void setPermissoes(List<Permissao> lst){
    this.permissoes = lst;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;
    data["nome"] = this.nome;
    data["permissoes"] = this.permissoes != null ? this.permissoes.map((i) => i.toJson()).toList() : null;
    return data;
  }


}