import 'dart:async';
import 'dart:convert';

import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/usuario.dart';
import '../utils/HttpsClient.dart';
import '../utils/perfil.dart';
import '../widgets/constants.dart';
import 'api_response.dart';
import 'package:http/http.dart' as http;

class ChangePassApi{


  static Future<ApiResponse<String>> sendMessageDiretor(String iduser, String message) async {
    try{
      var url =Constants.urlEndpoint+'diretor/contato';


      var ssl = false;
      var response = null;

      if(Constants.protocolEndpoint == "https://")
        ssl = true;

      print("url $url");

      Map params = {
        'iduser': iduser,
        'mensagem' : message
      };

      //encode Map para JSON(string)
      var body = json.encode(params);
      if(ssl) {
        var client = HttpsClient().httpsclient;
        response = await client.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS"
            },
            body: body).timeout(Duration(seconds: 20));
      }else {
        response = await http.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS"
            },
            body: body).timeout(Duration(seconds: 20));
      }
      print("Response..sendMessageDiretor..Code "+response.statusCode.toString());

      print("Response..SendMessageDiretor.."+response.body);

      if(response.statusCode == 200){
        return ApiResponse.ok("Mensagem enviada!");
      }else{
        return ApiResponse.error("Erro");
      }

    }catch(error, exception){

      print("Erro : $error > $exception ");

      return ApiResponse.error("Sem comunicação ... tente mais tarde... ");

    }
  }

  static Future<ApiResponse<Usuario>> changeUser(Usuario usr, String nome, String login, String fone) async {
    SharedPref sharedPref = SharedPref();
    try{
      var ssl = false;
      var response = null;

      if(Constants.protocolEndpoint == "https://")
        ssl = true;

      var url =Constants.urlEndpoint+'user/changeuser';


      print("url $url");

      Map params = {
        'id': usr.id,
        'name' : nome,
        'login':login,
        'phone': fone
      };

      //encode Map para JSON(string)
      var body = json.encode(params);

      String u = usr.login+"|"+usr.senha;
      String p = usr.senha;

      String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));

      if(ssl) {
        var client = HttpsClient().httpsclient;
        response = await client.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS",
              "Authorization": basicAuth
            },
            body: body).timeout(Duration(seconds: 5));
      }else {
        response = await http.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS",
              "Authorization": basicAuth
            },
            body: body).timeout(Duration(seconds: 5));
      }
      print("${response.statusCode}");

      Map<String,dynamic> mapResponse = jsonDecode(Utf8Decoder().convert(response.bodyBytes));

      if(response.statusCode == 200){
        final usuario = Usuario.fromJson(mapResponse);
        usuario.senha=usr.senha;

        return ApiResponse.ok(usuario);
      }else{
        return ApiResponse.error("Erro");
      }
    }catch(error, exception){

      print("Erro : $error > $exception ");

      return ApiResponse.error("Sem comunicação ... tente mais tarde... ");

    }
  }

  static Future<ApiResponse<Usuario>> changePass(String login, String pass, String iduser, String password, bool consultor) async {
    SharedPref sharedPref = SharedPref();
    try{
      var ssl = false;
      var response = null;

      if(Constants.protocolEndpoint == "https://")
        ssl = true;


      var url =Constants.urlEndpoint+'user/changepass';
      if(consultor)
        url =Constants.urlEndpoint+'consultant/changepass';

      print("url $url");

      Map params = {
        'id': iduser,
        'password' : password
      };

      //encode Map para JSON(string)
      var body = json.encode(params);

      String u = login+"|"+pass;

      String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$pass'));

      if(ssl) {
        var client = HttpsClient().httpsclient;
        response = await client.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS",
              "Authorization": basicAuth
            },
            body: body).timeout(Duration(seconds: 5));
      }else {
        response = await http.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS",
              "Authorization": basicAuth
            },
            body: body).timeout(Duration(seconds: 5));
      }
      print("${response.statusCode}");

      Map<String,dynamic> mapResponse = json.decode(response.body);

      if(response.statusCode == 200){
          final usuario = Usuario.fromJson(mapResponse);
          sharedPref.save('usuario', usuario);
          if(usuario.tipo=="C"){
            sharedPref.save('tipo', 'consultor');
          }else{
            sharedPref.save('tipo', 'cliente');
          }

          //await FlutterSession().set('logged', usuario);
          return ApiResponse.ok(usuario);
        }else{
        return ApiResponse.error("Erro");
      }

      return ApiResponse.error("Falha ao trocar a senha");

    }catch(error, exception){

      print("Erro : $error > $exception ");

      return ApiResponse.error("Sem comunicação ... tente mais tarde... ");

    }
  }

  static Future<ApiResponse<Usuario>> changePush(String iduser, bool elastic, bool zabbix, bool tickets, bool consultant) async {
    try{
      SharedPref sharedPref = SharedPref();

      var ssl = false;
      var response = null;

      if(Constants.protocolEndpoint == "https://")
        ssl = true;


      var url =Constants.urlEndpoint+'user/pushmessage';
      if(consultant)
        url =Constants.urlEndpoint+'consultant/pushmessage';

      print("url $url");

      Map params = {
        'id': iduser,
        'pmElastic' : elastic,
        'pmZabbix': zabbix,
        'pmMoviedesk': tickets
      };

      //encode Map para JSON(string)
      var body = json.encode(params);

      if(ssl) {
        var client = HttpsClient().httpsclient;
        response = await client.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS"
            },
            body: body).timeout(Duration(seconds: 5));
      }else {
        response = await http.post(Uri.parse(url),
            headers: {
              "Access-Control-Allow-Origin": "*",
              // Required for CORS support to work
              "Access-Control-Allow-Credentials": "true",
              // Required for cookies, authorization headers with HTTPS
              "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
              "Access-Control-Allow-Methods": "POST, OPTIONS"
            },
            body: body).timeout(Duration(seconds: 5));
      }

      print("${response.statusCode}");

      Map<String,dynamic> mapResponse = json.decode(response.body);

      if(response.statusCode == 200){
        final usuario = Usuario.fromJson(mapResponse);
        sharedPref.save('usuario', usuario);
        if(usuario.tipo=="C"){
          sharedPref.save('tipo', 'consultor');
        }else{
          sharedPref.save('tipo', 'cliente');
        }
          return ApiResponse.ok(usuario);
      }else{
        return ApiResponse.error("Erro");
      }

      return ApiResponse.error("Falha ao trocar a senha");

    }catch(error, exception){

      print("Erro : $error > $exception ");

      return ApiResponse.error("Sem comunicação ... tente mais tarde... ");

    }
  }

}