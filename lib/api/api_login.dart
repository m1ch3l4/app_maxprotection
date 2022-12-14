import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import '../model/usuario.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/perfil.dart';
import '../widgets/constants.dart';
import 'api_response.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;

class LoginApi{

  static Future<void> logoff() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    exit(0);
  }

  static Future<ApiResponse<Usuario>> login(String user, String password) async {
    final prefs = await SharedPreferences.getInstance();

    try{

      EmpresasSearch _empSearch = new EmpresasSearch();

      var url =Constants.urlEndpoint+'user/anotherLogin';

      print("url $url");

      Map params = {
        'login': user,
        'password' : password
      };

      //encode Map para JSON(string)
      var body = json.encode(params);

      var response = await http.post(Uri.parse(url),
          headers: {"Access-Control-Allow-Origin": "*", // Required for CORS support to work
            "Access-Control-Allow-Credentials": "true", // Required for cookies, authorization headers with HTTPS
            "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "POST, OPTIONS"},
          body: body).timeout(Duration(seconds: 10));

      /** print("${response.statusCode}");
      print("login...");
      print(response.body);
      print("++++++++++++++++"); **/

      Map<String,dynamic> mapResponse = json.decode(response.body);


      if(response.statusCode == 200){

        //mapResponse.forEach((k,v) => print("got key $k with $v"));

        final usuario = Usuario.fromJson(mapResponse);
        if(usuario.id=="-1"){
          return ApiResponse.error(utf8.decode(usuario.name.codeUnits)); //acento
        }else {
          Perfil.setTecnico(usuario.tipo == "T" ? true : false);

          if (usuario.hasAccess || usuario.tipo != "T") {
            prefs.setString('usuario', json.encode(usuario));
            prefs.setString(
                'tecnico', (usuario.tipo == "T" ? "true" : "false"));
            FCMInitConsultor _fcmInit = new FCMInitConsultor();
            _fcmInit.setConsultant(usuario.toJson());
            return ApiResponse.ok(usuario);
          } else {
            return ApiResponse.error("A sua credencial n??o ?? mais v??lida!");
          }
        }
      }

      return ApiResponse.error("Erro ao fazer o login");

    }catch(error, exception){

      print("Erro : $error > $exception ");

      return ApiResponse.error("Sem comunica????o ... tente mais tarde... ");

    }
  }

}