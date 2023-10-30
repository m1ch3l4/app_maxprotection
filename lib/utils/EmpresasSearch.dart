import 'package:flutter/cupertino.dart';
import '../model/empresa.dart';

class EmpresasSearch{

  static final EmpresasSearch _instance = EmpresasSearch._internal();

  factory EmpresasSearch() {
    return _instance;
  }

  late Empresa defaultOption;
  Empresa defaultValue = Empresa("0","Selecione a empresa");
  List<Empresa> options = [];

  EmpresasSearch._internal(){
    defaultOption = defaultValue;
  }
  void setOptions(List<Empresa> lst){
    options = lst;
  }

  List<Empresa> get lstOptions=>options;

  Empresa get defaultOpt=>defaultOption;

  void setDefaultOpt(Empresa opt){
    defaultOption = opt;
  }


}