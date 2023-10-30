import 'dart:convert';
import 'dart:io';

import 'package:app_maxprotection/utils/Logoff.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../api/ChangPassApi.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/RadialButton.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
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
          return (snapshot.hasData ? new PwdPage(title: 'Mudar Senha', user: snapshot.data as Map<String, dynamic>): CircularProgressIndicator());
        },
      ),
    );
  }
}

class PwdPage extends StatefulWidget {
  PwdPage({this.title,this.user}) : super();

  final String? title;
  final Map<String, dynamic>? user;


  @override
  _PwdPageState createState() => new _PwdPageState();
}

class _PwdPageState extends State<PwdPage> {

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  bool consultant=false;
  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  // Initially password is obscure
  bool _obscureText = true;
  bool _obscureTextc = true;
  late String senha, confsenha;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.of(context).maybePop(context).then((value) {
      if (value == false) {
        Navigator.pushReplacement(
            context,
            FadePageRoute(
              builder: (ctx) => HomePage(),
            ));
      }
    });
    return true;
  }
  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }


  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    consultant = (widget.user!["tipo"]=="C"?true:false);
    _fabHeight = _initFabHeight;

  }

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _togglec() {
    setState(() {
      _obscureTextc = !_obscureTextc;
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
        resizeToAvoidBottomInset : false,
        body: getMain(width),
        drawer:  Drawer(
          child: SliderMenu('password',widget.user!,textTheme,(width*0.6)),
        )
    );
  }

  Widget warming(double width){
    return Container(
      width: width,
      decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color:HexColor(Constants.blue),width: 5),
            right: BorderSide(color:HexColor(Constants.blue),width: 5),
          ),
          color:HexColor(Constants.firtColumn)
      ),
      margin: EdgeInsets.all(7.0),
      padding: EdgeInsets.all(15.0),
      child: Column(children: [
        Row(children: [
        Icon(Icons.warning_amber_outlined,color:HexColor(Constants.red),size: 24.0),
        Expanded(child:
        Text('Ao alterar sua senha você será desconectado e deverá efetuar login novamente.',textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.0,
              color: HexColor(Constants.blue),
              fontWeight: FontWeight.bold)),
        )])]),
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
                headerAlertas(_scaffoldKey, widget.user!, context, width, 185, "Alteração de Senha"),
                Spacer(),
                Container(
                    width: width*0.9,
                    child: _body(MediaQuery.of(context).size.width)),
          Spacer(),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Text('A sua senha deve ter 12 caracteres contendo: letras maiúsculas, números e \ncaracteres especiais (!@#\$&*~)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: HexColor(Constants.red),
                    fontWeight: FontWeight.normal,
                  ),
                )]),
          Spacer(),
          warming(width),
          Spacer(),
          Row(mainAxisAlignment:MainAxisAlignment.center,children: [RadialButton(buttonText: "Salvar", width: width*0.8, onpressed: ()=> _sendForm())],),
          Spacer()
              ],
      ),
    );
  }
  Widget _body(double width){
    return
      Column(
    children:[
      new Form(
      key: _key,
      child: _formUI(width*0.85),
    )
    ]);
  }

  Widget _formUI(double width) {
    Color clTitle = HexColor(Constants.red);
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.start,children:[SizedBox(width: 13,),Text("Nova Senha",style: TextStyle(color:clTitle,fontWeight: FontWeight.bold))]),
        SizedBox(height: 2,),
        new TextFormField(
          cursorColor: Colors.white,
          style: TextStyle(color: clTitle),
          decoration: new InputDecoration(
              counterStyle: TextStyle(color:clTitle),
              prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child:Icon(Icons.lock,color:clTitle)),
              suffixIcon: IconButton(
                onPressed: _toggle,
                icon: Icon(Icons.remove_red_eye_sharp),
                color: HexColor(Constants.red),),
              hintText: 'Nova Senha',
              hintStyle: TextStyle(color: clTitle),
              enabledBorder: OutlineInputBorder(
                borderSide:
                BorderSide(width: 2, color: clTitle), //<-- SEE HERE
                borderRadius: BorderRadius.circular(15.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width:2,color: clTitle),
                borderRadius: BorderRadius.circular(15.0),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(width:2,color: clTitle),
                borderRadius: BorderRadius.circular(15.0),
              ),errorStyle: TextStyle(fontWeight:FontWeight.bold,color: HexColor(Constants.blue))),
          maxLength: 12,
          validator: _validarSenha,
          onChanged: (String val){
            senha = val;
          },
          onSaved: (String? val) {
            senha = val!;
          },
          obscureText: _obscureText,
        ),
        SizedBox(height: 10,),
        Row(mainAxisAlignment: MainAxisAlignment.start,children:[SizedBox(width: 13,),Text("Confirmação Senha",style: TextStyle(color:clTitle,fontWeight: FontWeight.bold))]),
        SizedBox(height: 2,),
        new TextFormField(
          cursorColor: Colors.white,
          style: TextStyle(color: clTitle),
          decoration: new InputDecoration(
              counterStyle: TextStyle(color:clTitle),
              prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child:Icon(Icons.lock,color:clTitle)),
              suffixIcon: IconButton(
                onPressed: _togglec,
                icon: Icon(Icons.remove_red_eye_sharp),
                color: HexColor(Constants.red),),
              hintText: 'Confirmação Senha',
              hintStyle: TextStyle(color: clTitle),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2, color: clTitle), //<-- SEE HERE
                borderRadius: BorderRadius.circular(15.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width:2,color: clTitle),
                borderRadius: BorderRadius.circular(15.0),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(width:2,color: clTitle),
                borderRadius: BorderRadius.circular(15.0),
              ),errorStyle: TextStyle(fontWeight:FontWeight.bold,color: HexColor(Constants.blue))),
          maxLength: 12,
          validator: _validarConfSenha,
          onSaved: (String? val) {
            confsenha = val!;
          },
          obscureText: _obscureTextc,
        ),
      ],
    );
  }

  String? _validarSenha(String? value) {
    var atual =widget.user!["password"].toString();
    RegExp regex =
    RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{12,}$');
    if(!regex.hasMatch(value!)){
      return "A senha deve ter 12 caracteres incluindo pelo menos 1 letra maiúscula, número e caracter especial";
    }
    if(value == atual){
      return "A Nova senha deve ser diferente da anterior!";
    }
    return null;
  }

  String? _validarConfSenha(String? value) {
    if (value!=senha) {
      return "A senha e a confirmação devem ser iguais";
    }
    return null;
  }

  _sendForm() {
    if (_key.currentState!.validate()) {
      // Sem erros na validação
      _key.currentState!.save();
      print("Senha $senha");
      print("Confsenha $confsenha");
      changePass(widget.user!['id'].toString(), senha);
    } else {
      print("Diz q. não está correto...");
      // erro de validação
      setState(() {
        _validate = true;
      });
    }
  }

  Future<String> changePass(String iduser,String newpass) {
    return ChangePassApi.changePass(widget.user!["token"],iduser, newpass,consultant).then((resp) {
      print('LoginAPI. ${resp.ok}');
      if(!resp.ok){
        Message.showMessage("Não foi possível alterar sua senha!");
        Message.showMessage(utf8.decode(resp.msg.codeUnits));
        return 'user not exists';
      }else {

        Message.showMessage("Senha Alterada com sucesso!\nSuas credenciais não são mais validas\n, você deverá fazer login novamente.");

        Logoff.logoffSenha();

        return 'senha alterada';
      }
    });
  }


}