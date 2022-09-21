import 'dart:convert';

import '../widgets/constants.dart';
import 'api_response.dart';
import 'package:http/http.dart' as http;

class PushApi{

  static Future<ApiResponse<String>> changePass(String iduser, String idMessage) async {

    try{
      var url =Constants.urlEndpoint+'push/update';

      print("url $url");

      Map params = {
        'id': idMessage,
        'user' : iduser
      };

      //encode Map para JSON(string)
      var body = json.encode(params);

      var response = await http.post(Uri.parse(url),
          headers: {"Access-Control-Allow-Origin": "*", // Required for CORS support to work
            "Access-Control-Allow-Credentials": "true", // Required for cookies, authorization headers with HTTPS
            "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "POST, OPTIONS"},
          body: body).timeout(Duration(seconds: 5));

      print("Push.retorno...${response.statusCode}");

      if(response.statusCode == 200){
        return ApiResponse.ok("Confirmação de Recebimento enviada");
      }else{
        return ApiResponse.error("Erro");
      }

    }catch(error, exception){
      print("Push.Erro : $error > $exception ");
      return ApiResponse.error("Sem comunicação ... tente mais tarde... ");
    }
  }
}