//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/Logoff.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../api/ChangPassApi.dart';
import '../model/empresa.dart';
import '../model/usuario.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/perfil.dart';
import '../widgets/RadialButton.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


void main() => runApp(new InnerUser());

class InnerUser extends StatelessWidget {

  static const routeName = '/user';
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
            home: new UserPage(title: 'Seus Dados Pessoais', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class UserPage extends StatefulWidget {
  UserPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;


  @override
  _UserPageState createState() => new _UserPageState();
}

class _UserPageState extends State<UserPage> {

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
  String nome;
  String login;
  String fone;
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Usuario usr;

  EmpresasSearch _empSearch = new EmpresasSearch();
  Empresa empSel;
  bool changeLogin=false;

  MaskTextInputFormatter celularFormat = MaskTextInputFormatter(mask: "(##)#####-####",filter: { "#": RegExp(r'[0-9]') },type: MaskAutoCompletionType.lazy);

  var maskFormatter = new MaskTextInputFormatter(
      mask: '(##)#####-####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => HomePage(),
    ));
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

    print(widget.user.toString());
    nome = widget.user["name"];
    login = widget.user["login"];
    fone = widget.user["phone"];
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
    _fcmInit.configureMessage(context, "usuario");

    usr = Usuario.fromSharedPref(widget.user);
    usr.empresas.add(_empSearch.defaultValue);
    _empSearch.setOptions(usr.empresas);
    empSel = _empSearch.defaultOpt;

    if(_empSearch.lstOptions.length <3)
      empSel = _empSearch.lstOptions.elementAt(0);

    return Scaffold(
        appBar: AppBar(backgroundColor: HexColor(Constants.blue), toolbarHeight: 0,),
        backgroundColor: HexColor(Constants.grey),
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: getMain(width),
        drawer:  Drawer(
          width: width*0.6,
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('usuario',widget.user,textTheme,(width*0.5)),
        )
    );
  }

  Widget warming(){
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: HexColor(Constants.red))
      ),
      margin: EdgeInsets.all(7.0),
      padding: EdgeInsets.all(10.0),
      child: Row(children: [
        Icon(Icons.warning_amber_outlined,color:HexColor(Constants.red),size: 40.0),
        Expanded(child: Text('Ao alterar o campo e-mail você será desconectado e deverá efetuar login novamente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.0,
            color: HexColor(Constants.red),
            fontWeight: FontWeight.w400,
          ),
        ))]),
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Stack(
              children: [
                headerAlertas(_scaffoldKey, widget.user, context, width, 185, "Dados Cadastrais"),
                Container(
                    width: width*.98,
                    height: MediaQuery.of(context).size.height-100,
                    padding:  EdgeInsets.only(left:10,top:200),
                    child: _body(MediaQuery.of(context).size.width))
              ])],
      ),
    );
    /**return SafeArea(
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
          warming(),
          _body(),
        ],
      ),
    );**/
  }
  Widget _body(double width){
    return Column(children:[Container(
      width: width*0.9,
        child:new Form(
      key: _key,
      child: _formUI(width),
    )),
    Spacer(),
    Row(mainAxisAlignment:MainAxisAlignment.center,children: [RadialButton(buttonText: "Salvar", width: width*0.8, onpressed: ()=> _sendForm())],)]);
  }

  Widget _formUI(double width) {
    Color clTitle = HexColor(Constants.red);
    Color clField = HexColor(Constants.blue);
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width: 13,),Text("Nome Completo",style: TextStyle(color:clTitle,fontWeight: FontWeight.bold))]),
        SizedBox(height: 2,),
        new TextFormField(
            initialValue: nome,
            onSaved: (String val) {
              nome = val;
            },
            onChanged: (String val){
              nome = val;
            },
            validator: _validarNome,
            cursorColor: Colors.white,
            style: TextStyle(color: clTitle),
            decoration: new InputDecoration(
              counterStyle: TextStyle(color:clTitle),
                prefixIcon: Padding(
                    padding: const EdgeInsets.only(right: 20,left:10),
                    child:Icon(Icons.person,color:clTitle)),
                hintText: 'Nome Completo',
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
                ),errorStyle: TextStyle(color: clTitle)),
            maxLength: 40,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.start,children:[SizedBox(width: 13,),Text("Email",style: TextStyle(color:clTitle,fontWeight: FontWeight.bold))]),
        SizedBox(height: 2,),
        new TextFormField(
          cursorColor: Colors.white,
          initialValue: login,
          style: TextStyle(color: clTitle),
          decoration: new InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: clTitle),
              counterStyle: TextStyle(color:clTitle),
              prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 20,left:10),
                  child:Icon(Icons.mail,color:clTitle)),
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
              ),
              errorStyle: TextStyle(color: clTitle)
          ),
          keyboardType: TextInputType.emailAddress,
          maxLength: 40,
            onSaved: (String val) {
              login = val;
            },
            onChanged: (String val){
              login = val;
            },
            validator: _validarLogin
            ,),
        Row(mainAxisAlignment: MainAxisAlignment.start,children:[SizedBox(width: 13,),Text("Celular",style: TextStyle(color:clTitle,fontWeight: FontWeight.bold))]),
        SizedBox(height: 2,),
        new TextFormField(
            cursorColor: Colors.white,
            initialValue: fone,
            style: TextStyle(color: clTitle),
            inputFormatters:[celularFormat],
            decoration: new InputDecoration(hintText: '(DDD) 00000-0000',hintStyle: TextStyle(color: clTitle),
                counterStyle: TextStyle(color:clTitle),
                prefixIcon: Padding(
                    padding: const EdgeInsets.only(right: 20,left:10),
                    child:Icon(Icons.phone_android,color:clTitle)),
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
                ),errorStyle: TextStyle(color: clTitle)),
            keyboardType: TextInputType.phone,
            maxLength: 14,
          onSaved: (String val) {
            fone = val;
          },
          onChanged: (String val){
            fone = val;
          },
          validator: _validarNome,
        ),
        /**Text('Nome'),
        TextFormField(
          style: TextStyle(color: HexColor(Constants.red)),
          initialValue: nome,
          decoration: new InputDecoration(
            contentPadding: new EdgeInsets.fromLTRB(20.0, 10.0, 0.0, 0.0),),
          onSaved: (String val) {
            nome = val;
          },
          onChanged: (String val){
            nome = val;
          },
          validator: _validarNome,
        ),
        Text('Login/E-mail'),
        TextFormField(
          style: TextStyle(color: HexColor(Constants.red)),
          initialValue: login,
          decoration: new InputDecoration(
            contentPadding: new EdgeInsets.fromLTRB(20.0, 10.0, 0.0, 0.0),),
          onSaved: (String val) {
            login = val;
          },
          onChanged: (String val){
            login = val;
          },
          validator: _validarLogin,
        ),
        Text('Celular/WhatsApp'),
        TextFormField(
          inputFormatters: [
            maskFormatter
          ],
          style: TextStyle(color: HexColor(Constants.red)),
          initialValue: fone,
          decoration: new InputDecoration(
            contentPadding: new EdgeInsets.fromLTRB(20.0, 10.0, 0.0, 0.0),),
          onSaved: (String val) {
            fone = val;
          },
          onChanged: (String val){
            fone = val;
          },
          validator: _validarFone,
        ),
        (widget.user["tipo"]!="C"?empresasToShow()
            :
        SizedBox(height:0)),
        new SizedBox(height: 15.0),**/
      ],
    );
  }

  String _validarLogin(String value) {
    RegExp regex =
    RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    if(!regex.hasMatch(value)){
      return "Informe um e-mail válido.";
    }
    return null;
  }

  String _validarNome(String value) {
    if(value.length==0){
      return "Esse campo não pode ficar em branco.";
    }
    return null;
  }
  String _validarFone(String value) {
    if(value.length<14){
      return "Informe um número de celular válido.";
    }
    return null;
  }


  Widget empresasToShow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DropdownButton<Empresa>(
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          style: TextStyle(color: HexColor(Constants.red)),
          underline: Container(
            height: 2,
            color: HexColor(Constants.blue),
          ),
          onChanged: (Empresa newValue) {
            setState(() {
              empSel = newValue;
              _empSearch.setDefaultOpt(newValue);
            });
          },
          items: _empSearch.lstOptions.map((Empresa bean) {
            return  DropdownMenuItem<Empresa>(
                value: bean,
                child: SizedBox(width: 310.0,child: Text(bean.name,overflow: TextOverflow.ellipsis,)));}
          ).toList(),
          value: empSel,
        ),
      ],
    );
  }

  _sendForm() {
    int changes=0;
    print(nome+"|"+login+"|"+fone);
    if (_key.currentState.validate()) {
      _key.currentState.save();
      if(usr.name!=nome)changes++;
      if(usr.login!=login) {
        changes++;
        changeLogin=true;
      }
      if(usr.phone!=fone)changes++;
      if(changes>0)
        changeUser();
      else
        Message.showMessage("Você não modificou nenhum atributo...");
    } else {
      changes=0;
      print("Diz q. não está correto...");
      // erro de validação
      setState(() {
        _validate = true;
      });
    }
  }

  Future<String> changeUser() {
    return ChangePassApi.changeUser(usr,nome,login,fone).then((resp) {
      SharedPref sharedPref = SharedPref();
      print('LoginAPI. ${resp.ok}');
      if(!resp.ok){
        Message.showMessage("Não foi possível alterar seus dados!");
        return 'user not exists';
      }else {
        if(changeLogin) {
          Message.showMessage(
              "Seus dados foram alterados!\nSuas credenciais não são mais validas\n, você deverá fazer login novamente.");
          Logoff.logoff();
        }else{
          Message.showMessage("Seus dados foram alterados com sucesso!");
          //TODO = replace widget
          final usuario = resp.result;
            Perfil.setTecnico(usuario.tipo == "T" ? true : false);
            sharedPref.save('usuario', usuario);
            sharedPref.save(
                'tecnico', (usuario.tipo == "T" ? "true" : "false"));
        }
        return 'senha alterada';
      }
    });
  }

}