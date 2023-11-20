import 'dart:core';

class empresaServico{



  static Map<String,String> empresaServ(Map<String,dynamic> mapResponse){
  Map<String,String> e=Map();

  mapResponse.forEach((k,v) {
    String chave="";
    if(k == "relacionamento" || k =="enterpriseSet") {
      List<dynamic> l = v;
      l.asMap().entries.forEach((item) {
        Map<String,dynamic> mapServ = item.value;
        mapServ.forEach((k1,v1){
          if(k1=="id")
            chave = v1.toString();
          if(k1=="servicoSet") {
            List<dynamic> l2 = v1;
            l.asMap().entries.forEach((item2) {
                Map<String,dynamic> mapSitem = item2.value;
                mapSitem.forEach((key, value) {

                });
            });
          }
        });
      });
    }
  });

  return e;
  }
}