import 'dart:convert';

import '../model/usuario.dart';
import '../widgets/constants.dart';
import 'api_response.dart';
import 'package:http/http.dart' as http;

class CallTecnicoApi{

  static Future<ApiResponse<Usuario>> callTecnico(String iduser) async {
    try {
      var url = Constants.urlEndpoint + 'calltecnico/save';

      print("url $url");

      Map params = {
        'cliente': iduser
      };

      //encode Map para JSON(string)
      var body = json.encode(params);

      var response = await http.post(Uri.parse(url),
          headers: {
            "Access-Control-Allow-Origin": "*",
            // Required for CORS support to work
            "Access-Control-Allow-Credentials": "true",
            // Required for cookies, authorization headers with HTTPS
            "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "POST, OPTIONS"
          },
          body: body).timeout(Duration(seconds: 5));

      print("${response.statusCode}");
      print("callTecnico "+response.body);


      if (response.statusCode == 200 && response.body.length>1) {
        Map<String, dynamic> mapResponse = json.decode(response.body);
        final usuario = Usuario.fromCall(mapResponse);
        return ApiResponse.ok(usuario);
      } else {
        return ApiResponse.error("Nenhum plantonista!");
      }
    } catch (error, exception) {
      print("Erro : $error > $exception ");
      return ApiResponse.error("Nenhum plantonista! ");
    }
    return ApiResponse.error("Nenhum plantonista!");
  }
}