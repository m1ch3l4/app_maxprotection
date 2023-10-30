import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:http/io_client.dart' as ioclient;

class HttpsClient{

  static final HttpsClient _instance = HttpsClient._internal();
  factory HttpsClient() => _instance;
  late ioclient.IOClient httpsclient;
  late Dio dio;

  HttpsClient._internal(){
    HttpClient client = new HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    httpsclient = ioclient.IOClient(client);


    dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient dioClient) {
      dioClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    };
  }

  Dio get dioClient=>dio;
  ioclient.IOClient get https=>httpsclient;
}