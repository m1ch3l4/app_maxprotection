import 'dart:io';

import 'package:app_maxprotection/screens/inner_forgotpass.dart';
import 'package:app_maxprotection/screens/login_request.dart';
import 'package:app_maxprotection/widgets/RadialButton.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_login.dart';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/FingerPrintAuth.dart';
import '../utils/HexColor.dart';
import '../utils/Message.dart';
import '../utils/SharedPref.dart';
import '../utils/perfil.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import 'contactus.dart';
import 'home_page.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  static const routeName = '/welcome';

  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen>{

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  String login='', senha='';
  bool firstLogin = false;
  final loginCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  FingerPrintAuth fp = new FingerPrintAuth();
  SharedPref sharedPref = SharedPref();

  bool _isHidden=true;

  double tamanho = 0.0;

  @override
  State<StatefulWidget> createState() {
    _fabHeight = _initFabHeight;
    throw UnimplementedError();
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }

    @override
    Widget build(BuildContext context) {
      return Material(
          color: HexColor(Constants.blue),
          child: FutureBuilder(
            future: sharedPref.read("usuario"),
            builder: (context,snapshot){
              if(snapshot.connectionState!=ConnectionState.done){
                return CircularProgressIndicator();
              }else {
                //print("LOGIN_SCREEN: snapshot.value...");
                //print(snapshot.data);
                if (snapshot.data!=null && snapshot.data.toString().length>0) {
                  EmpresasSearch _empSearch = new EmpresasSearch();
                  List<Empresa> lstEmpresas = [];
                  var a = snapshot.data as Map<String,dynamic>;
                  Perfil.tecnico = (a["tipo"]=="T"?true:false);
                  if(a!=null) {
                    if(a['empresas']!=null) {
                      print('empresa...'+a['empresas'].toString());
                      for (Map<String, dynamic> i in a['empresas']) {
                        lstEmpresas.add(Empresa.fromJson(i));
                      }
                      _empSearch.setOptions(lstEmpresas);
                    }
                  }
                  FCMInitConsultor _fcmInit = new FCMInitConsultor();
                  _fcmInit.setConsultant(a);

                  return HomePage(); //login with fingerprint
                } else {
                  firstLogin = true;
                  print('Primeiro login $firstLogin');
                  return buildWelcomeScrenn(context);
                }
              }
            },
          )
      );
  }

  Widget buildWelcomeScrenn(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;

    print("Tamanho da tela? "+height.toString());

    tamanho = height;

    return
      Scaffold(
        resizeToAvoidBottomInset : false,
        body: Container(
          height: height,
          width: width,
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/Fundo.png"),fit: BoxFit.cover),),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _logo(context,width,(height*0.25)),
              _formLogin(context,width,(height*0.5)),
              _body(context, width, (height*0.25)),
            ],
          ),

        ),
        backgroundColor: Colors.transparent,
      )
      ;
  }
  Widget _logo(BuildContext context, double width, double height){
    return Container(
      height: height,
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      alignment: Alignment.center,
      child:
      Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
      Spacer(),
    Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
    Image.asset("images/lg.png",width: (tamanho<700?280:300),height: (tamanho<700?128:138),),
    ],
    ),
          Spacer()]));
  }

  Widget _formLogin(BuildContext context, double width, double height){
    return Container(
      width: width,
        height: height,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child:
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _formUI(),
                    InkWell(
                      child: Text("Esqueceu sua senha?",style: TextStyle(color:Colors.white),),
                      onTap: () => forgotPass(context),
                    ),
                    SizedBox(height: height*0.12),
                    RadialButton(buttonText: "LOGIN", width: width, onpressed: ()=> getlogin(context)),
                    SizedBox(height: (tamanho<700?8:10),),
                    InkWell(
                      child: Text("Solicitar login de acesso...",style: TextStyle(color:Colors.white),),
                      onTap: () => requestLogin(context),
                    )],
                ))
          ]));
  }

  getlogin(BuildContext context){
    _sendForm(context);
  }

  requestLogin(BuildContext context){
    Navigator.of(context).push(FadePageRoute(
      builder: (context)=>LoginRequest(),
    ));
  }

  forgotPass(BuildContext context){
    Navigator.of(context).push(FadePageRoute(
      builder: (context)=>ForgotScreen(),
    ));
  }

  Widget _formUI() {
    return Form(
        key: _key,
        child: new Column(
          children: <Widget>[
            new TextFormField(
              controller: loginCtrl,
              cursorColor: HexColor(Constants.red),
              style: TextStyle(color: HexColor(Constants.red)),
              decoration: new InputDecoration(hintText: 'Login', hintStyle: TextStyle(color: HexColor(Constants.red)),
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
            new TextFormField(
              cursorColor: Colors.white,
              obscureText: _isHidden,
              controller: passCtrl,
              style: TextStyle(color: HexColor(Constants.red)),
              decoration: new InputDecoration(hintText: 'Senha', hintStyle: TextStyle(color: HexColor(Constants.red)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                  ),
                  filled:true,
                  fillColor: Colors.white,
                  suffixIcon: InkWell(
                    onTap: _togglePasswordView,
                    child: Icon(Icons.visibility_outlined,color: HexColor(Constants.red)),
                  )),
              maxLength: 12,
              validator: (value){
                if (value == null || value.isEmpty) {
                  return 'Informe a senha!';
                }else{
                  if(value!=null && value.length<8){
                    return 'Senha fora do padrão';
                  }
                }
                return null;
              },)
          ],
        ));
  }

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }


  Widget _body(BuildContext context, double width, double height){
    return
            Container(
                width: width,
                height: height/2-1,
              color: HexColor(Constants.blueContainer).withOpacity(0.35),
              padding: EdgeInsets.symmetric(
                  horizontal: 20.0),
              child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.fingerprint, color:Colors.white,size: 40.0),
                                tooltip: 'Ver todos',
                                onPressed: () {
                                  biometricsAuth(context);
                                },
                              ),
                            ]),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    IconButton(
                      icon: Icon(Icons.phone, color:Colors.white,size: 40.0),
                      tooltip: 'Ver todos',
                      onPressed: () {
                        Navigator.of(context).push(FadePageRoute(
                          builder: (context)=>ContatcusScreen(),
                        ));
                      },
                    ),]),
                  ],
                )
    );
  }

  void biometricsAuth(BuildContext context){
    if(firstLogin){
      Message.showMessage("Após o primeiro login você poderá associar a sua digital ao seu usuário!");
    }else {
      if (fp.checkBiometrics())
        Message.showMessage(
            "Seu dispositivo não suporta esse tipo de autenticação!");
      else
        fp.authWithBiometrics().then((val) {
          if(val){
            Navigator.of(context).push(FadePageRoute(
              builder: (context)=>HomePage()
              //builder: (context)=>LoginScreen(),
            ));
          }
        });
    }
  }

  _sendForm(BuildContext context) {
    login = loginCtrl.value.text;
    senha = passCtrl.value.text;
    print('send form...$login|$senha');
    webLogin(login, senha,context);
  }

  Future<void> webLogin(String login, String senha, BuildContext context) {
    //return LoginApi.loginConsultor(login, senha).then((resp) {
    return LoginApi.login(login, senha).then((resp){
      print('LoginAPI. ${resp.ok}');
      if(!resp.ok){
        Message.showMessage(resp.msg);
      }else {
        Navigator.of(context).pushAndRemoveUntil(FadePageRoute(
          builder: (context)=>HomePage(),
        ),(Route<dynamic> route) => false);
      }
    });
  }

  _launchURL(_url) async =>
      await launch(_url) ? await launch(_url) : Message.showMessage("Não foi possível abrir a URL: "+_url);

}
