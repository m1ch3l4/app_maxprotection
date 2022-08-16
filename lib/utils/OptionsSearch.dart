

import '../model/Idbean.dart';

class OptionsSearch {

  static final OptionsSearch _instance = OptionsSearch._internal();
  factory OptionsSearch() => _instance;

  late Idbean defaultOption;
  Idbean defaultValue = Idbean(7,'últimos 7 dias');
  List<Idbean> options = <Idbean>[
    const Idbean(1,'últimas 24 horas'),
    const Idbean(7,'últimos 7 dias'),
    const Idbean(15,'últimos 15 dias'),
    const Idbean(30,'últimos 30 dias'),
  ];

  OptionsSearch._internal(){
    defaultOption = defaultValue;
  }

  List<Idbean> get lstOptions=>options;

  Idbean get defaultOpt=>defaultOption;

  void setDefaultOpt(Idbean opt){
      defaultOption = opt;
  }


}