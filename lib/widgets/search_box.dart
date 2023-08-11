// @dart=2.9
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';


import '../utils/HexColor.dart';
import '../utils/HomeSearchDelegate.dart';
import '../utils/Message.dart';
import 'constants.dart';

import 'package:http/http.dart' as http;

class SearchBox extends StatefulWidget {

  final Color cardColor;
  final String title;
  final Map<String, dynamic> usr;
  final double width;
  final Function f;
  final SearchDelegate searchDelegate;

  SearchBox({
    this.cardColor,
    this.title,
    this.usr,
    this.width,
    this.f,
    this.searchDelegate
  });

  _searchBox createState() => _searchBox();

}
class _searchBox extends State<SearchBox>{
  TextEditingController txtSearch = TextEditingController();
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  Future<void> _showSearch(BuildContext context) async {
    await showSearch(
      context: context,
      delegate: widget.searchDelegate,
      query: txtSearch.value.text,
    );
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      print("texto reconhecido...."+_lastWords);
      txtSearch.text = _lastWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
        height: 40,
        width: widget.width,
        decoration: BoxDecoration(
          color: HexColor(Constants.red),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: HexColor(Constants.red),
              blurRadius: 1.0, // soften the shadow
              spreadRadius: 1.0, //extend the shadow
              offset: Offset(
                1.0, // Move to right 5  horizontally
                1.0, // Move to bottom 5 Vertically
              ),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(child: TextField(
                  //textAlignVertical: TextAlignVertical.center,
                  controller: txtSearch,
                  style: TextStyle(color: HexColor(Constants.red)),
                  //controller: _controller,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top:2,left:10),
                    hintText: widget.title,
                    fillColor: Colors.white,filled: true,
                    hintStyle: TextStyle(color:HexColor(Constants.red),fontSize: 13),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search,color: HexColor(Constants.red),size: 18,),
                      onPressed: () {
                        _showSearch(context);
                      },
                    ),
                    border: new OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        topLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                        topRight: Radius.circular(20.0)
                      ),
                    ),
                  ),
                ),height: 40,width: widget.width*0.9,),
                GestureDetector(
                  onTap: () {
                    widget.f(txtSearch.value.text);
                  },
                  child: Container(
                  height: 40,
                  width: widget.width*0.1,
                  decoration: new BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: HexColor(Constants.red),
                    //border: Border.all(color:Colors.white,width: 1)
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(!_speechToText.isNotListening?Icons.mic_off:Icons.mic_none_rounded,color: Colors.white,),
                    onPressed: (){
                      print("speech to text? "+_speechToText.isNotListening.toString());
                      _speechToText.isNotListening ? _startListening() : _stopListening();
                    },
                  ),
                )),
              ],
            ),
          ],
        ),
      );
  }

  /**
   *  if(txtSearch.value.text.isNotEmpty) {
      Future<String> ret = sendMessage();
      ret.then((value) {
      Message.showMessage(value);
      txtSearch.clear();
      }).catchError((error) {
      print(error);
      });
      }

   */

  /**
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
**/

}
