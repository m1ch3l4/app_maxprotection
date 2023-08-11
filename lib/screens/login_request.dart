import 'dart:convert';
import 'dart:io';

import 'package:app_maxprotection/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:http/http.dart' as http;

import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../utils/Message.dart';
import '../widgets/RadialButton.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/top_container.dart';

class LoginRequest extends StatefulWidget {
  @override
  LoginRequestState createState() {
    return LoginRequestState();
  }
}
enum SingingCharacter { login, suporte }
class LoginRequestState extends State<LoginRequest> {

  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  late String nome, email, celular;
  String opcaoLogin="Já sou cliente quero receber o login de acesso";
  String opcaoSuporte = "Ainda não sou cliente gostaria de receber a ligação de um consultor";

  SingingCharacter? _character = SingingCharacter.login;

  final nomeCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final celularCtrl = TextEditingController();

  MaskTextInputFormatter celularFormat = MaskTextInputFormatter(mask: "(##)#####-####",filter: { "#": RegExp(r'[0-9]') },type: MaskAutoCompletionType.lazy);


  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        constraints: const BoxConstraints.expand(),
    decoration: BoxDecoration(
      color: HexColor(Constants.blueRequestLogin)
    ),
    child:
      getMain(context)
      ),
    backgroundColor: Colors.transparent,);
  }
  Widget getMain(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Column(
      children: <Widget>[
        _header(width,(height*0.15)),
        Spacer(),
        _body(width, (height*0.80)),
      ],
    );
  }

  Widget _header(double width, double height){
    return TopContainer(
      padding: EdgeInsets.zero,
      height: height,
      width: width,
      child:
      Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 35,),
            Container(
              color: HexColor(Constants.red),
              padding: EdgeInsets.symmetric(vertical: 12),
              margin: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(width:10),
                  InkWell(child: new Icon(Icons.arrow_back,color: Colors.white,),onTap:()=>backToWelcome(context)),
                  SizedBox(width:5),
                  Text(
                    'Cadastro',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  InkWell(child: new Icon(Icons.more_vert,color: Colors.white,),onTap:()=>print("back"))
                ],
              ),
            ),
          ]),
    );
  }

  Widget _formUI() {
    double width = MediaQuery.of(context).size.width;
    return new Form(
        key: _key,
        child: Container(
          margin: EdgeInsets.only(left: 15,right:15),
            child:Column(
          children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.start,children:[Text("Nome Completo",style: TextStyle(color:Colors.white))]),
            new TextFormField(
                controller: nomeCtrl,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                decoration: new InputDecoration(
                    prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child:Icon(Icons.person,color:HexColor(Constants.greyContainer))),
                    hintText: 'Nome Completo', contentPadding: EdgeInsets.only(top:20),
                    hintStyle: TextStyle(color: HexColor(Constants.greyContainer)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.greyContainer)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.grey)),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.grey)),
                    ),errorStyle: TextStyle(color: HexColor(Constants.grey))),
                maxLength: 40,
                validator: (value){
                  String patttern = r'(^[a-zA-Z ]*$)';
                  RegExp regExp = new RegExp(patttern);
                  if (value!.length == 0) {
                    return "Informe o nome";
                  } else if (!regExp.hasMatch(value)) {
                    return "O nome deve conter caracteres de a-z ou A-Z";
                  }
                  return null;
                }
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start,children:[Text("Email",style: TextStyle(color:Colors.white))]),
            new TextFormField(
              cursorColor: Colors.white,
              controller: emailCtrl,
              style: TextStyle(color: Colors.white),
              decoration: new InputDecoration(hintText: 'Email',contentPadding: EdgeInsets.only(top:20), hintStyle: TextStyle(color: HexColor(Constants.greyContainer)),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child:Icon(Icons.mail,color:HexColor(Constants.greyContainer))),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: HexColor(Constants.greyContainer)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: HexColor(Constants.grey)),
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: HexColor(Constants.grey)),
                  ),
                  errorStyle: TextStyle(color: HexColor(Constants.grey))
              ),
              keyboardType: TextInputType.emailAddress,
              maxLength: 40,
              validator: (value){
                String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                RegExp regExp = new RegExp(pattern);
                if(value==null || value.isEmpty){
                  return "Preencha o seu e-mail";
                }else {
                  if (!regExp.hasMatch(value)) {
                    return "Email inválido";
                  }
                }
                return null;
              },),
            Row(mainAxisAlignment: MainAxisAlignment.start,children:[Text("Celular",style: TextStyle(color:Colors.white))]),
            new TextFormField(
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                controller: celularCtrl,
                inputFormatters:[celularFormat],
                decoration: new InputDecoration(hintText: '(DDD) 00000-0000',contentPadding: EdgeInsets.only(top:20),hintStyle: TextStyle(color: HexColor(Constants.greyContainer)),
                    prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child:Icon(Icons.phone_android,color:HexColor(Constants.greyContainer))),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.greyContainer)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.grey)),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.grey)),
                    ),errorStyle: TextStyle(color: HexColor(Constants.grey))),
                keyboardType: TextInputType.phone,
                maxLength: 14,
                validator: (value){
                  String patttern = r'(^[0-9]*$)';
                  RegExp regExp = new RegExp(patttern);
                  if (value?.length == 0) {
                    return "Informe o celular";
                  } else if(value?.length != 14){
                    return "O celular deve ter 14 dígitos";
                  }
                  return null;
                }
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start,children:[Text("Confirme o Celular",style: TextStyle(color:Colors.white))]),
            new TextFormField(
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                controller: celularCtrl,
                inputFormatters:[celularFormat],
                decoration: new InputDecoration(hintText: '(DDD) 00000-0000', contentPadding: EdgeInsets.only(top:20),hintStyle: TextStyle(color: HexColor(Constants.greyContainer)),
                    prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child:Icon(Icons.phone_android,color:HexColor(Constants.greyContainer))),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.greyContainer)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.grey)),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: HexColor(Constants.grey)),
                    ),errorStyle: TextStyle(color: HexColor(Constants.grey))),
                keyboardType: TextInputType.phone,
                maxLength: 14,
                validator: (value){
                  String patttern = r'(^[0-9]*$)';
                  RegExp regExp = new RegExp(patttern);
                  if (value?.length == 0) {
                    return "Informe o celular";
                  } else if(value?.length != 14){
                    return "O celular deve ter 14 dígitos";
                  }
                  return null;
                }
            ),
            getOptions(width),
          ],
        )));
  }

  Widget getOptions(double width){
    return Container(
      width: width,
      child:Column(
      children: [
        RadioListTile<SingingCharacter>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          tileColor: Colors.white,
          activeColor: Colors.white,
          title: Text(opcaoLogin,style: TextStyle(color: Colors.white)),
          value: SingingCharacter.login,
          groupValue: _character,
          onChanged: (SingingCharacter? value) {
            setState(() {
              _character = value;
            });
          },
        ),
        RadioListTile<SingingCharacter>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          tileColor: Colors.white,
          activeColor: Colors.white,
          title: Text(opcaoSuporte,style: TextStyle(color: Colors.white)),
          value: SingingCharacter.suporte,
          groupValue: _character,
          onChanged: (SingingCharacter? value) {
            setState(() {
              _character = value;
            });
          },
        )
      ],
    ));
  }


  _sendForm(BuildContext context) {
    nome = nomeCtrl.value.text;
    email = emailCtrl.value.text;
    celular = celularCtrl.value.text;
    var opcao = (_character.toString());
    print("opcao $opcao");

    Future<String> ret = sendMessage();
    ret.then((value) {
      Message.showMessage(value);
      nomeCtrl.clear();
      emailCtrl.clear();
      celularCtrl.clear();
    })
        .catchError( (error) {
      print(error);
    });
  }

  Future<String> sendMessage() async{
    var url =Constants.urlEndpoint+'message/app';
    var ssl = false;
    var response = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;


    print("url $url");
    int tipo = 0;
    if(_character == SingingCharacter.login)
      tipo=1;
    else
      tipo=2;

    Map params = {
      'nome': nome,
      'email' : email,
      'celular': celular,
      'tipo': tipo,
      'assunto':''
    };

    //encode Map para JSON(string)
    var body = json.encode(params);

    if(ssl){
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
    print("sentMessage...");
    print(response.body);
    print("++++++++++++++++");
    return response.body;
  }

  Widget _body(double width, double height){
    return Container(
      width: width,
      height: height,
      child: Column(
        //crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 5.0),
              child: Column(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 25,),
                        _formUI(),
                        SizedBox(height: 45,),
                        Container(
                          margin: EdgeInsets.only(left: 15,right:15),
                        child:
                        RadialButton(buttonText: "ENVIAR ACESSO", width: width, onpressed: ()=> _sendForm(context))),
                      ],
                    ))
                  ],
                ),
                SizedBox(height: 30,)
              ],)
          ),
        ],
      ),
    );
  }

  backToWelcome(BuildContext context){
    Navigator.of(context).push(FadePageRoute(
      builder: (context)=>WelcomeScreen(),
    ));
  }


}
