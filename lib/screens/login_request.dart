import 'dart:convert';
import 'dart:io';

import 'package:app_maxprotection/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:http/http.dart' as http;

import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../utils/Message.dart';
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


  Text subheading(String title) {
    return Text(
      title,
      style: TextStyle(
          color: Colors.blue,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor(Constants.red),
      resizeToAvoidBottomInset: false,
      body: getMain(context) ,
    );
  }
  Widget getMain(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    
    return Column(
      children: <Widget>[
        _header(width,(height*0.85)),
        _body(width, (height*0.15)),
      ],
    );
  }

  Widget _header(double width, double height){
    return TopContainer(
      height: height,
      width: width,
      child:
      Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 25,),
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset("images/icon2.png",width: 40,height: 40,),
                SizedBox(width:5),
                Text(
                  'Max Protection',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
            SizedBox(height: 20,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informe Nome, Celular e E-mail cadastrados na MaxProtection.',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 25,),
                    _formUI(),
                    SizedBox(height: 45,),
                    ElevatedButton(
                        child: Text(
                            "Enviar mensagem",
                            style: TextStyle(fontSize: 14)
                        ),
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(width*0.9, 50)),
                            foregroundColor: MaterialStateProperty.all<Color>(HexColor(Constants.red)),
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: HexColor(Constants.red))
                                )
                            )
                        ),
                        onPressed: (){
                          if (_key.currentState!.validate()) {
                            print('_sendForm');
                          _sendForm(context);
                          }else{
                            print('diz que ainda não é valido....');
                          }
                        },
                    )
                  ],
                ))
              ],
            ),
          ]),
    );
  }

  Widget _formUI() {
    return new Form(
        key: _key,
        child: Column(
      children: <Widget>[
        new TextFormField(
          controller: nomeCtrl,
          cursorColor: Colors.white,
          style: TextStyle(color: Colors.white),
          decoration: new InputDecoration(hintText: 'Nome Completo',
              hintStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                ),
                border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                ),errorStyle: TextStyle(color: Colors.white)),
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
        new TextFormField(
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            controller: celularCtrl,
            inputFormatters:[celularFormat],
            decoration: new InputDecoration(hintText: 'Celular',hintStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),errorStyle: TextStyle(color: Colors.white)),
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
        new TextFormField(
            cursorColor: Colors.white,
            controller: emailCtrl,
            style: TextStyle(color: Colors.white),
            decoration: new InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              errorStyle: TextStyle(color: Colors.white)
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
            getOptions()
      ],
    ));
  }

  Widget getOptions(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RadioListTile<SingingCharacter>(
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
    );
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
              color: HexColor(Constants.red),
              padding: EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 5.0),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child:
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color:Colors.white,size: 40.0),
                            tooltip: 'Ver todos',
                            onPressed: () {
                              Navigator.of(context).push(FadePageRoute(
                                builder: (context)=>WelcomeScreen(),
                              ));
                            },
                          ),
                          SizedBox(height: 5,),
                          Text(
                              'Voltar',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.white))
                        ])
                    )
                  ],
                )
              ],)
          ),
        ],
      ),
    );
  }


}
