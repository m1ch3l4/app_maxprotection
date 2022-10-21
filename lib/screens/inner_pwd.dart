//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../api/ChangPassApi.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


void main() => runApp(new InnerPwd());

class InnerPwd extends StatelessWidget {

  static const routeName = '/password';
  SharedPref sharedPref = SharedPref();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FutureBuilder(
        future: sharedPref.read("usuario"),
        builder: (context,snapshot){
          return (snapshot.hasData ? new MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TI & Segurança',
            theme: new ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: new PwdPage(title: 'Mudar Senha', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class PwdPage extends StatefulWidget {
  PwdPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;


  @override
  _PwdPageState createState() => new _PwdPageState();
}

class _PwdPageState extends State<PwdPage> {

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  bool consultant;
  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  // Initially password is obscure
  bool _obscureText = true;
  String senha, confsenha;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }
  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }


  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    consultant = (widget.user["tipo"]=="C"?true:false);
    _fabHeight = _initFabHeight;
  }

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "password");
    return Scaffold(
        key: _scaffoldKey,
        //backgroundColor: HexColor(Constants.grey),
        body:
        SlidingUpPanel(
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0)),
          onPanelSlide: (double pos) => updateState(pos),
          panelBuilder: (sc) => BottomMenu(context,sc,width,widget.user),
          body: getMain(width),
        ),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('password',widget.user,textTheme),
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        children: <Widget>[
          _header(width),
          Divider(
            height: 5,
            thickness: 1,
            indent: 5,
            endIndent: 5,
            color: HexColor(Constants.grey),
          ),
          _body(),
        ],
      ),
    );
  }
  Widget _body(){
    return new Form(
      key: _key,
      child: _formUI(),
    );
  }

  Widget _formUI() {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        new TextFormField(
          decoration: new InputDecoration(
              hintText: 'Nova Senha',
          contentPadding: new EdgeInsets.fromLTRB(20.0, 10.0, 0.0, 0.0),),
          maxLength: 12,
          validator: _validarSenha,
          onChanged: (String val){
            senha = val;
          },
          onSaved: (String val) {
            senha = val;
          },
          obscureText: _obscureText,
        ),
        new IconButton(
          onPressed: _toggle,
          icon: Icon(Icons.remove_red_eye_sharp),
          color: HexColor(Constants.red),),
        new TextFormField(
          decoration: new InputDecoration(hintText: 'Confirme a senha',
            contentPadding: new EdgeInsets.fromLTRB(20.0, 10.0, 0.0, 0.0),),
          maxLength: 12,
          validator: _validarConfSenha,
          onSaved: (String val) {
            confsenha = val;
          },
          obscureText: _obscureText,
        ),
        new SizedBox(height: 15.0),
        new RaisedButton(
          onPressed: _sendForm,
          child: new Text('Enviar',style:TextStyle(color: HexColor(Constants.red), fontWeight: FontWeight.w700, fontSize: 14.0)),
        )
      ],
    );
  }

  String _validarSenha(String value) {
    RegExp regex =
    RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{12,}$');
    /** if (value.length == 0) {
      return "Informe a senha";
    } else if(value.length != 12){
      return "A senha deve ter 12 caracteres";
    }**/
    if(!regex.hasMatch(value)){
      return "A senha deve ter 12 caracteres incluindo pelo menos 1 letra maiúscula, número e caracter especial";
    }
    return null;
  }

  String _validarConfSenha(String value) {
    if (value!=senha) {
      return "A senha e a confirmação devem ser iguais";
    }
    return null;
  }

  _sendForm() {
    if (_key.currentState.validate()) {
      // Sem erros na validação
      _key.currentState.save();
      print("Senha $senha");
      print("Confsenha $confsenha");
      changePass(widget.user['id'].toString(), senha);
    } else {
      print("Diz q. não está correto...");
      // erro de validação
      setState(() {
        _validate = true;
      });
    }
  }

  Future<String> changePass(String iduser,String newpass) {
    return ChangePassApi.changePass(iduser, newpass,consultant).then((resp) {
      print('LoginAPI. ${resp.ok}');
      if(!resp.ok){
        Fluttertoast.showToast(
            msg: "Não foi possível alterar sua senha!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: HexColor(Constants.red),
            textColor: Colors.white,
            fontSize: 16.0
        );
        return 'user not exists';
      }else {
        Fluttertoast.showToast(
            msg: "Senha Alterada com sucesso!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: HexColor(Constants.red),
            textColor: Colors.white,
            fontSize: 16.0
        );
        return 'senha alterada';
      }
    });
  }

  Widget _header(double width){
    return TopContainer(
      height: 80,
      width: width,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 0, vertical: 5.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color:Colors.white,size: 20.0),
                    tooltip: 'Voltar',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(FadePageRoute(
                        builder: (context) => HomePage(),
                      ));
                    },
                  ),
                  Expanded(child: Text(
                    'Preferências do Usuário',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  )),
                  SizedBox(width: 60,)
                ],
              ),
            ),

          ]),
    );
  }

}