// @dart=2.9
import 'dart:convert';

import 'package:flutter/material.dart';


import '../utils/HexColor.dart';
import '../utils/Message.dart';
import 'constants.dart';

import 'package:http/http.dart' as http;

class SearchBox extends StatelessWidget {
  final Color cardColor;
  final String title;
  final Icon iconsufix;
  TextEditingController txtSearch = TextEditingController();
  final Map<String, dynamic> usr;

  SearchBox({
    this.cardColor,
    this.title,
    this.iconsufix,
    this.usr
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        //margin: EdgeInsets.symmetric(vertical: 5.0),
        //padding: EdgeInsets.only(bottom: 15.0),
        height: 48,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(width: 7),
                Expanded(child: TextField(
                  controller: txtSearch,
                  style: TextStyle(color: HexColor(Constants.red)),
                  //controller: _controller,
                  decoration: InputDecoration(
                    hintText: title,
                    fillColor: Colors.white,filled: true,
                    border: InputBorder.none,
                    /**border: new OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        topLeft: Radius.circular(10.0)
                      ),
                    ),**/
                  ),

                )),
                GestureDetector(
                  onTap: () {
                    if(txtSearch.value.text.isNotEmpty) {
                      Future<String> ret = sendMessage();
                      ret.then((value) {
                        Message.showMessage(value);
                        txtSearch.clear();
                      }).catchError((error) {
                        print(error);
                      });
                    }
                  },
                  child: Container(
                  height: 48,
                  width: 40,
                  decoration: new BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: HexColor(Constants.red),
                    border: Border.all(color:Colors.white,width: 1)
                  ),
                  child: iconsufix,
                )),
              ],
            ),
          ],
        ),
      );
  }

  Future<String> sendMessage() async{
    var url =Constants.urlEndpoint+'message/app';

    print("url $url");
    int tipo = 3;

    Map params = {
      'userid': usr["id"],
      'nome': usr["name"],
      'email' : usr["login"],
      'celular': '',
      'tipo': tipo,
      'assunto':'Quero informações sobre: '+txtSearch.value.text
    };

    //encode Map para JSON(string)
    var body = json.encode(params);

    var response = await http.post(Uri.parse(url),
        headers: {"Access-Control-Allow-Origin": "*", // Required for CORS support to work
          "Access-Control-Allow-Credentials": "true", // Required for cookies, authorization headers with HTTPS
          "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
          "Access-Control-Allow-Methods": "POST, OPTIONS"},
        body: body).timeout(Duration(seconds: 5));

    print("${response.statusCode}");
    print("sentMessage...");
    print(response.body);
    print("++++++++++++++++");
    return response.body;
  }
}
