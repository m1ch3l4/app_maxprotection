// @dart=2.9
class ChamadoMp3{
  String name;
  String uri;
  String type;
  int size;

  ChamadoMp3.fromJson(Map<String, dynamic> json){
    name = json["name"];
    uri = json["uri"];
    type = json["type"];
    size = json["size"];
  }
}