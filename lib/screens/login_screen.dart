import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_login.dart';
import '../model/empresa.dart';
import '../model/usuario.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/FingerPrintAuth.dart';
import '../utils/HexColor.dart';
import '../utils/Message.dart';
import '../utils/perfil.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  String login='', senha='';
  bool firstLogin = false;
  final loginCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  var senhaFocus = FocusNode();

  FingerPrintAuth fp = new FingerPrintAuth();
  SharedPref sharedPref = SharedPref();

  bool _isHidden=true;

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
    return Material(
        color: HexColor(Constants.blue),
        child: FutureBuilder(
          future: sharedPref.read("usuario"),
          builder: (context,snapshot){
            //print("snapshot.obj:");
            //print(snapshot);
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
                _fcmInit.setConsultant(Usuario.fromJson(a));

                return HomePage(); //login with fingerprint
              } else {
                firstLogin = true;
                print('Primeiro login $firstLogin');
                return buildLoginScreen(context);
              }
            }
          },
        )
    );
  }

  Widget buildLoginScreen(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double _hheader = MediaQuery.of(context).size.height*0.85;
    double _hbody = MediaQuery.of(context).size.height*0.15;
    return getMain(context, width, _hheader, _hbody);
  }

  Widget getMain(BuildContext context, double width, double _hheader, double _hbody){
    return Scaffold(
        backgroundColor: HexColor(Constants.red),
        resizeToAvoidBottomInset: false,
        body: Column(
          children: <Widget>[
            _header(context, width,_hheader),
            _body(width, _hbody),
          ],
        ));
  }
  Widget _header(BuildContext context, double width, double height){
    return TopContainer(
      height: height,
      width: width,
      child:
      Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20,),
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
                      'Informe suas credenciais',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 30,),
                    _formUI(),
                    SizedBox(height: 5,),
                    Container(
                      alignment: Alignment.centerRight,
                      child: new InkWell(
                          child: new Text('Esqueceu a senha?',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              )),
                          onTap: () => _launchURL('https://app.maxprotection.com.br')
                      ),
                    ),
                    SizedBox(height: 60,),
                    ElevatedButton(
                        child: Text(
                            "Entrar",
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
                          //if (_key.currentState!.validate()) {
                            _sendForm(context);
                          //}
                        },
                    )
                  ],
                ))
              ],
            ),
          ]),
    );
  }

  void _togglePasswordView() {
    print("toggle....");
    setState(() {
      _isHidden = !_isHidden;
      passCtrl.selection =
          TextSelection.collapsed(offset: passCtrl.text.length);
      FocusScope.of(context).requestFocus(senhaFocus);
    });
  }


  Widget _formUI() {
    return Form(
        key: _key,
        child: new Column(
      children: <Widget>[
        new TextFormField(
          controller: loginCtrl,
          cursorColor: Colors.white,
          style: TextStyle(color: Colors.white),
          decoration: new InputDecoration(hintText: 'Login', hintStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),errorStyle: TextStyle(color: Colors.white)),
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
          cursorColor: HexColor(Constants.red),
          obscureText: _isHidden,
          controller: passCtrl,
          focusNode: senhaFocus,
          style: TextStyle(color: Colors.white),
          decoration: new InputDecoration(hintText: 'Senha', hintStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusColor: HexColor(Constants.red),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),errorStyle: TextStyle(color: Colors.white),
          suffixIcon: InkWell(
            onTap: _togglePasswordView,
            child: Icon(Icons.visibility_outlined,color: Colors.white),
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
                            icon: const Icon(Icons.fingerprint_outlined, color:Colors.white,size: 48.0),
                            tooltip: 'digital',
                            onPressed: () {
                              if(firstLogin)
                                //Message.showMessage("Após o primeiro login você poderá associar a sua digital ao seu usuário!");
                                if(fp.checkBiometrics())
                                  Message.showMessage("Seu dispositivo não suporta esse tipo de autenticação!");
                                else
                                  fp.authWithBiometrics().then((val) {
                                    print(val==true?'autenticou':'não autenticou');
                                  });
                            },
                          ),
                          SizedBox(height: 15,),
                          Text(
                              'Fazer login com a minha digital',
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

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
  void _launchURL(_url) async =>
      await launch(_url) ? await launch(_url) : Message.showMessage("Não foi possível abrir a URL: "+_url);
}

