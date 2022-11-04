import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_maxprotection/screens/inner_servicos.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:new_version/new_version.dart';


import '../model/PermissaoModel.dart';
import '../model/RoleModel.dart';
import '../screens/home_page.dart';
import '../screens/inner_elastic.dart';
import '../screens/inner_messages.dart';
import '../screens/inner_noticias.dart';
import '../screens/inner_preferences.dart';
import '../screens/inner_pwd.dart';
import '../screens/inner_zabbix.dart';
import '../screens/ticketsview-consultor.dart';
import '../utils/Message.dart';
import 'HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class SliderMenu extends StatelessWidget{
  late String screen;
  late Map<String, dynamic> usr;
  late BuildContext ctx;
  late TextTheme textTheme;
  bool isConsultant = false;
  bool acessoContrato = false;
  late Role rol;
  late List<Permissao> lst;

  late StatelessWidget instance;
  late Timer _timer;

  NewVersion newVersion = NewVersion(
    iOSId: 'br.com.maxprotection.securityNews',
    androidId: 'br.com.maxprotection.security_news',
  );

  basicStatusCheck() async{
    try {
      final status = await newVersion.getVersionStatus();
      if(status!=null)
      {
        if(status.canUpdate)
        {
          newVersion.showUpdateDialog
            (
              context: ctx,
              versionStatus: status,
              dialogTitle: "App desatualizado",
              //dismissButtonText: "Skip",
              dialogText: "Atualize a versão "+"${status.localVersion}"+ " para "+ "${status.storeVersion}",
              allowDismissal: false,
              dismissAction: ()
              {
                Navigator.pop(ctx);
              },
              updateButtonText: "Atualizar"
          );
        }else {
          Message.showMessage("Versão: " + status.localVersion);
          showDialog(
              context: ctx,
              builder: (BuildContext builderContext) {
                _timer = Timer(Duration(seconds: 5), () {
                  Navigator.of(ctx).pop();
                  Navigator.of(builderContext).pop();
                });

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius:
                  BorderRadius.all(Radius.circular(15))),
                  backgroundColor: HexColor(Constants.grey),
                  title: Text('Versão do App',style:TextStyle(
                    fontSize: 18.0,
                    color: HexColor(Constants.red),
                    fontWeight: FontWeight.w600,
                  ),textAlign: TextAlign.center),
                  content: SingleChildScrollView(
                    child: Text('Você está com a última versão: '+status.localVersion,style: TextStyle(
                      fontSize: 16.0,
                      color: HexColor(Constants.red),
                      fontWeight: FontWeight.w400,
                    ),textAlign: TextAlign.center,),
                  ),
                );
              }
          ).then((val){
            if (_timer.isActive) {
              _timer.cancel();
            }
          });
        }
      }
    }catch(e){
      print("Erro: "+e.toString());
    }
  }

  SliderMenu(String screen, Map<String, dynamic> user, TextTheme theme){
    this.screen = screen;
    this.usr = user;
    textTheme = theme;
    if(usr!=null && usr["role"]!=null) {
      rol = Role.fromJson(usr["role"]);
      if(rol!=null)
      lst = rol.permissoes.where((content) => content.nome.contains("app-")).toList();
    }
  }

  Widget build(BuildContext context){
    ctx = context;
    int _selectedDestination = 0;
    return ListView(
      // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: <Widget>[
        /** Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
          child: Text(
            //'Olá '+usr['name'].toString(),
            'Olá pessoa',
            style: textTheme.headline6,
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
        ),**/
        SizedBox(height: 20,),
        ListTile(leading: Icon(Icons.arrow_back_ios,color:HexColor(Constants.red)),
        title: Text('Voltar',style:Theme.of(context).textTheme.subtitle1),
        selected: _selectedDestination == 0,
        onTap: () => Navigator.of(context).pop()),
        Divider(
          height: 1,
          thickness: 1,
        ),
        (screen!="home"? ListTile(
          leading: Icon(Icons.home_outlined,color:HexColor(Constants.red)),
          title: Text('Home',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 0,
          onTap: () => selectDestination(0),
        ):SizedBox(height:10)),
        (screen!="elastic" && getFromList("app-siem").meus ?ListTile(
          leading: Icon(Icons.add_alarm_outlined,color:HexColor(Constants.red)),
          title: Text('Alertas SIEM',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 1,
          onTap: () => selectDestination(1),
        ):SizedBox(height: 10)),
        (screen!="zabbix" && getFromList("app-zabbix").meus ?ListTile(
          leading: Icon(Icons.add_comment_outlined,color:HexColor(Constants.red)),
          title: Text('Zabbix',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 2,
          onTap: () => selectDestination(2),
        ):SizedBox(height: 10)),
        (screen!="tickets" && getFromList("app-tickets").meus ?ListTile(
          leading: Icon(Icons.support,color:HexColor(Constants.red)),
          title: Text('Tickets',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 3,
          onTap: () => selectDestination(3),
        ):SizedBox(height: 10)),
        (screen!="news"?ListTile(
          leading: Icon(Icons.menu_book,color:HexColor(Constants.red)),
          title: Text('Notícias',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 4,
          onTap: () => selectDestination(4),
        ):SizedBox(height: 10)),
        (screen!="messages" && getFromList("app-mensagem").meus ?ListTile(
          leading: Icon(Icons.message_outlined,color:HexColor(Constants.red)),
          title: Text('Mensagens',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 8,
          onTap: () => selectDestination(8),
        ):SizedBox(height: 10)),

        (screen!="servicos"&& getFromList("app-servico").meus ?ListTile(
          leading: Icon(Icons.miscellaneous_services_outlined,color:HexColor(Constants.red)),
          title: Text('Serviços',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 10,
          onTap: () => selectDestination(10),
        ):SizedBox(height: 10)),

        /**Divider(
          height: 1,
          thickness: 1,
        ),**/
        (screen!="changepass"?ListTile(
          leading: Icon(Icons.account_circle_outlined,color:HexColor(Constants.red)),
          title: Text('Alterar Senha',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 5,
          onTap: () => selectDestination(5),
        ):SizedBox(height: 10)),
        /**(screen!="preferencias"?ListTile(
          leading: Icon(Icons.folder_shared_outlined,color:HexColor(Constants.red)),
          title: Text('Preferências do Usuário',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 6,
          onTap: () => selectDestination(6),
        ):SizedBox(height: 10)),**/
        ListTile(
          leading: Icon(Icons.info_outline,color:HexColor(Constants.red)),
          title: Text("Versão",style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination ==11,
          onTap: () => selectDestination(11),
        ),
        ListTile(
          leading: Icon(Icons.logout,color:HexColor(Constants.red)),
          title: Text('Sair',style:Theme.of(context).textTheme.subtitle1),
          selected: _selectedDestination == 7,
          onTap: () => selectDestination(7),
        ),
      ],
    );
  }

  Permissao getFromList(String nome){
    if(rol!=null && lst!=null){
      return lst.where((element) => element.nome == nome).last;
    }else{
      Permissao p = Permissao(nome,true);
      return p;
    }
  }

  void selectDestination(int index) {
    switch(index){
      case 0:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          //builder: (context) => (isConsultant?HomeConsultor():Home()),
          builder: (context) => HomePage(),
        ));
        screen = "dashboard";
        break;
      case 1:
        Navigator.of(ctx).pop();
        Navigator.of(ctx).push(FadePageRoute(
          //builder: (context) => (isConsultant?ElasticAlertsConsultant():ElasticAlerts()),
          builder: (context){
            instance = InnerElastic();
            return instance;
          },
        ));
        screen = "elastic";
        break;
      case 2:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          //builder: (context) => (isConsultant?ZabbixAlertsConsultant():ZabbixAlerts()),
          builder: (context) => InnerZabbix(),
        ));
        screen = "zabbix";
        break;
      case 3:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          //builder: (context) => (isConsultant?TicketsviewConsultant():Ticketsview()),
          builder: (context) => TicketsviewConsultor(0),
        ));
        screen = "tickets";
        break;
      case 4:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          builder: (context) => InnerNoticias(),
        ));
        screen = "news";
        break;
      case 5:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          builder: (context) => InnerPwd(),
        ));
        screen = "password";
        break;
      case 6:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          builder: (context) => InnerPreferences(),
        ));
        screen = "preferencias";
        break;
      case 7:
        (isConsultant? logoutConsultor() : logout());
        break;
      case 8:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          builder: (context) => InnerMessages(0),
        ));
        screen = "messages";
        break;
      case 10:
        Navigator.of(ctx).pushReplacement(FadePageRoute(
          builder: (context) =>InnerServicos(),
        ));
        screen = "servicos";
        break;
      case 11:
        basicStatusCheck();
        break;
    }
  }
  Future<void> logout() async{
    SharedPref pref = SharedPref();
    pref.read('logged');
    exit(0);
  }

  Future<void> logoutConsultor() async{
    SharedPref pref = SharedPref();
    pref.read('consultor');
    exit(0);
  }
}