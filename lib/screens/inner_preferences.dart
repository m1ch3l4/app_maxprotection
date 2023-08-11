//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/SharedPref.dart';
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


void main() => runApp(new InnerPreferences());

class InnerPreferences extends StatelessWidget {

  static const routeName = '/preferencias';
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
            home: new PreferencesPage(title: 'Preferencias', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class PreferencesPage extends StatefulWidget {
  PreferencesPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;


  @override
  _PreferencesPageState createState() => new _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  bool consultant;
  GlobalKey<FormState> _key = new GlobalKey();

  Map<String, bool> pushMessage = {
    'Alertas SIEM ': true,
    'Alertas Zabbix': true,
    'Alertas Tickets MoviDesk': true,
  };

  final String keyElastic = "Alertas SIEM ";
  final String keyZabbix = "Alertas Zabbix";
  final String keyTickets = "Alertas Tickets MoviDesk";

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void initState() {
    super.initState();
    consultant = (widget.user["tipo"]=="C"?true:false);
    _fabHeight = _initFabHeight;
    pushMessage = {
      'Alertas SIEM ': widget.user['pm_elastic'],
      'Alertas Zabbix': widget.user['pm_zabbix'],
      'Alertas Tickets MoviDesk': widget.user['pm_tickets'],
    };
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

    _fcmInit.configureMessage(context, "preferences");
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
          child: SliderMenu('preferences',widget.user,textTheme,(width*0.5)),
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
      children: [
        Center(child: Text('Notificações por Mensagem Push',style: TextStyle(color: HexColor(Constants.red), fontWeight: FontWeight.w700, fontSize: 18.0))),
        new SizedBox(height: 15.0),
        new Column(children:getOptionsCheckBox()),
        new RaisedButton(
          onPressed: _sendForm,
          child: new Text('Salvar',style:TextStyle(color: HexColor(Constants.red), fontWeight: FontWeight.w700, fontSize: 14.0)),
        )
      ],
    );
  }

  List<CheckboxListTile> getOptionsCheckBox(){
    return pushMessage.keys
        .map((roomName) => CheckboxListTile(
      title: Text(roomName),
      value: pushMessage[roomName],
      checkColor: Colors.white,
      activeColor: HexColor(Constants.red),
      onChanged: (bool value) {
        setState(() {
          pushMessage[roomName] = value;
        });
      },
    )).toList();
  }


  _sendForm() {
    bool elastic,zabbix,ticket;
    pushMessage.forEach((key, value){
      print('Key: $key');
      print('Value: $value');
      print('------------------------------');
      if(key==keyElastic)
        elastic = value;
      if(key==keyZabbix)
        zabbix = value;
      if(key==keyTickets)
        ticket = value;
    });
    changePref(widget.user['id'].toString(), elastic,zabbix,ticket);
  }

  Future<String> changePref(String iduser,bool elastic, bool zabbix, bool tickets) {
    return ChangePassApi.changePush(iduser,elastic,zabbix,tickets,consultant).then((resp) {
      print('LoginAPI. ${resp.ok}');
      if(!resp.ok){
        Fluttertoast.showToast(
            msg: "Não foi possível alterar as preferências!",
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
            msg: "Preferências alteradas com sucesso!",
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