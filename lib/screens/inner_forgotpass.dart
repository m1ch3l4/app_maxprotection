import 'package:app_maxprotection/api/ChangPassApi.dart';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/screens/welcome_screen.dart';
import 'package:app_maxprotection/utils/Logoff.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/HexColor.dart';
import '../widgets/RadialButton.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';

class ForgotScreen extends StatefulWidget {
  static const routeName = '/forgot';

  ForgotScreenState createState() => ForgotScreenState();
}

class ForgotScreenState extends State<ForgotScreen>{

  GlobalKey<FormState> _key = new GlobalKey();
  String login='';
  bool firstLogin = false;
  final loginCtrl = TextEditingController();

  var senhaFocus = FocusNode();
  bool _ok=false;
  bool _keyclose=false;

  double tam=0.0;

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
        Navigator.pushReplacement(
            context,
            FadePageRoute(
              builder: (ctx) => WelcomeScreen("true"),
            ));
    return true;
  }

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    print("build....");
    _keyclose = MediaQuery.of(context).viewInsets.bottom != 0;
    _ok = _keyclose;
    return buildForgotScrenn(context);
  }

  Widget buildForgotScrenn(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    tam = height;
    return
      Scaffold(
        resizeToAvoidBottomInset : false,
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/Fundo.png"),fit: BoxFit.cover),),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                width: width*0.9,
                child: _formUI(width,(height*0.75)),
              ),
              SizedBox(height: 80,),
              _footer(width, (height*0.25)),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
      );
  }

  handleKey(RawKeyEventData key) {
    String _keyCode;
    _keyCode = key.keyLabel.toString();
    print("clicou...."+_keyCode);//keycode of key event (66 is return)
  }

  Widget _formUI(double width, double height) {
    Widget f = Form(
        key: _key,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new TextFormField(
              controller: loginCtrl,
              cursorColor: HexColor(Constants.red),
              style: TextStyle(color: HexColor(Constants.red)),
              onFieldSubmitted: (value){
                  _ok=true;
                  print("submite...");
                  FocusScope.of(context).unfocus();
              },
              decoration: new InputDecoration(hintText: 'E-mail', hintStyle: TextStyle(color: HexColor(Constants.red)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                  ),
                  filled:true,
                  fillColor: Colors.white),
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
              },
              keyboardType: TextInputType.emailAddress,
              maxLength: 40,
            ),
            SizedBox(height: 5,),
            RadialButton(buttonText: "ENVIAR", width: width, onpressed: ()=>forgotPass()
                ),
          ],
        ));

    if(!_ok) {
      loginCtrl.selection = TextSelection.collapsed(offset: loginCtrl.text.length);
      FocusScope.of(context).requestFocus(senhaFocus);
      print("focos....");
    }

    return f;
  }

  forgotPass() async {
    String? msg;
    String login = loginCtrl.value.text;

    String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);

    if(login!=null && regExp.hasMatch(login)){

      await ChangePassApi.checkLogin(login).then((value) => msg=value.result);

      AlertDialog alert;
      Widget cancelButton = ElevatedButton(
        child: Text("OK"),
        onPressed:  () {
          Navigator.of(context, rootNavigator: true).pop('dialog');
          Logoff.cleanDados();
          Navigator.of(context).push(FadePageRoute(
              builder: (context)=>WelcomeScreen("")
          ));
        },
      );
      alert = AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: Text("ATENÇÃO", style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red))),
        content: Text(msg!,style: TextStyle(color:HexColor(Constants.blue)),softWrap: true),
        actions: [
          cancelButton
        ],
      );  // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }else{
      Message.showMessage("Preencha um login válido!");
    }
  }

String label(String tipo){
    String lbl = "T";

    switch(tipo){
      case "D":
        lbl = "Diretor";
        break;
      case "C":
        lbl = "Consultor";
        break;
      default:
        lbl = "Analista";
        break;
    }
    return lbl;
  }

  _footer(double width, double height){
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
    Row(children: [SizedBox(height:80)],),
    Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
    Image.asset("images/lg.png",width: 300,height: 138,),
    ],
    ),
    SizedBox(height: 40,),
    ]);
  }

}