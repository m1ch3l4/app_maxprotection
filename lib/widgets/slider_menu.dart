// @dart=2.10
import 'dart:async';
import 'dart:io';

import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_version/new_version.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../model/PermissaoModel.dart';
import '../model/RoleModel.dart';
import '../screens/home_page.dart';
import '../screens/inner_elastic.dart';
import '../screens/inner_messages.dart';
import '../screens/inner_noticias.dart';
import '../screens/inner_preferences.dart';
import '../screens/inner_pwd.dart';
import '../screens/inner_servicos.dart';
import '../screens/inner_zabbix.dart';
import '../screens/ticketsview-consultor.dart';
import '../utils/Logoff.dart';
import '../utils/Message.dart';
import 'HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';
import 'package:path/path.dart';

class SliderMenu extends StatelessWidget{
  String screen;
  Map<String, dynamic> usr;
  BuildContext ctx;
  TextTheme textTheme;
  bool isConsultant = false;
  bool acessoContrato = false;
  Role rol;
  List<Permissao> lst;

  StatelessWidget instance;
  Timer _timer;
  double width;

  NewVersion newVersion = NewVersion(
    iOSId: 'br.com.maxprotection.securityNews',
    androidId: 'br.com.maxprotection.security_news',
  );

  TextStyle itemMenu = TextStyle(color:Colors.white,fontSize: 16.0,fontWeight: FontWeight.bold);
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
              dialogTitle: "App Desatualizado",
              dismissButtonText: "Agora Não",
              dialogText: "Atualize a versão "+"${status.localVersion}"+ " para "+ "${status.storeVersion}",
              allowDismissal: true,
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
                  BorderRadius.all(Radius.circular(20))),
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
      print("Erro versão....: "+e.toString());
    }
  }

  File _image;
  final picker = ImagePicker();
  Widget img = null;

  Future getImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    XFile pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null) return;

    File _storeImage = File(pickedImage.path);

    // use getApplicationDocumentsDirectory() to get a directory inside the app
    final appDir = await getApplicationDocumentsDirectory();
    // get the image's directory
    final fileName = basename(pickedImage.path);

    // copy the image's whole directory to a new <File>
    final File localImage = await _storeImage.copy('${appDir.path}/$fileName');
    print("localImage...."+localImage.path);

    prefs.setString('profile_image', localImage.path);
  }

  Future<Widget> loadImage() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String img = prefs.getString('profile_image');
    if(img!=null) {
      return CircleAvatar(
        backgroundImage: Image.file(File(img),width: 100,height:100,).image,
          radius: 40,
          backgroundColor: Colors.white
      );
    }else{
      return null;
    }
  }


  SliderMenu(String screen, Map<String, dynamic> user, TextTheme theme, double wd){

    this.screen = screen;
    this.usr = user;
    textTheme = theme;
    //this.width = (wd!=null? wd : 200);
    this.width = wd;
    if(usr!=null && usr["role"]!=null) {
      rol = Role.fromJson(usr["role"]);
      if(rol!=null)
      lst = rol.permissoes.where((content) => content.nome.contains("app-")).toList();
    }
    loadImage().then((value) => img= value);
  }



  Widget build(BuildContext context){
    ctx = context;
    int _selectedDestination = 0;

    //double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    double top = height*0.025;

    //print("screen...."+screen+"|"+height.toString()+"/"+top.toString());

    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            //stops: [0.1,0.15],
            colors: [
              HexColor(Constants.blueinit),
              HexColor(Constants.blueContainer),
              HexColor(Constants.blueContainer)
            ]
          )
        ),
        child:
        Column(
      // Important: Remove any padding from the ListView.
      //padding: EdgeInsets.zero,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top:(height>732?20:5)),
        margin:(height>732?EdgeInsets.only(bottom: 25):EdgeInsets.zero),
        decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage("images/molde.png"),
            fit: BoxFit.fill,
            alignment: Alignment.center,
          ),
          ),
            child: Container(
                alignment:Alignment.center,
                padding: EdgeInsets.only(right: 6),
                child: GestureDetector(child: img!=null?img:Image.asset("images/profilepic.png", width: 106, height: 106,),onTap: getImage,)),
          ),
        Spacer(),
    new Container (
    decoration: new BoxDecoration (
      gradient: screen=='home'? LinearGradient(
          begin: Alignment.centerLeft,
          end:Alignment.centerRight,
          colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
      ):null,
    ),
    child:ListTile(
          contentPadding: EdgeInsets.only(left: 30),
          leading: Icon(Icons.menu,color:Colors.white,size:(height>732?32:28)),
          title: Text('Menu',style:itemMenu),
          selected: _selectedDestination == 0,
          onTap: () => selectDestination(0),
        )),
        Spacer(),
        (getFromList("app-siem").meus ?
        new Container (
            decoration: new BoxDecoration (
              gradient: screen=='elastic'? LinearGradient(
                  begin: Alignment.centerLeft,
                  end:Alignment.centerRight,
                  colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
              ):null,
            ),
            child:
        ListTile(
          contentPadding: EdgeInsets.only(left:30),
          leading: ImageIcon(AssetImage("images/siem.png"),color: Colors.white,size:(height>732?32:28)),
          title: Text('SIEM',style:itemMenu),
          selected: _selectedDestination == 1,
          onTap: () => selectDestination(1),
        ))
            :SizedBox(height: 10)),
        Spacer(),
        (getFromList("app-zabbix").meus ?
        new Container (
            decoration: new BoxDecoration (
            gradient: screen=='zabbix'? LinearGradient(
            begin: Alignment.centerLeft,
            end:Alignment.centerRight,
            colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
            ):null,
            ),
            child:
        ListTile(
          contentPadding: EdgeInsets.only(left:30),
          leading: ImageIcon(AssetImage("images/zabbixinv.png"),color: Colors.white,size:(height>732?32:28)),
          title: Text('Zabbix',style:itemMenu),
          selected: _selectedDestination == 2,
          onTap: () => selectDestination(2),
        )):SizedBox(height: 10)),
        Spacer(),
        (getFromList("app-tickets").meus ?
        new Container (
            decoration: new BoxDecoration (
            gradient: screen=='tickets'? LinearGradient(
            begin: Alignment.centerLeft,
            end:Alignment.centerRight,
            colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
            ):null,
            ),
            child:
        ListTile(
          contentPadding: EdgeInsets.only(left:30),
          leading: Icon(Icons.star_rounded,color:Colors.white,size: (height>732?32:28),),
          title: Text('Tickets',style:itemMenu),
          selected: _selectedDestination == 3,
          onTap: () => selectDestination(3),
        )):SizedBox(height: 10)),
        Spacer(),
    new Container (
    decoration: new BoxDecoration (
          gradient: screen=='noticias'? LinearGradient(
          begin: Alignment.centerLeft,
          end:Alignment.centerRight,
          colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
          ):null,
    ),
    child:
        ListTile(
          contentPadding: EdgeInsets.only(left:30),
          leading: Icon(Icons.location_on,color:Colors.white,size:(height>732?32:28)),
          title: Text('Notícias',style:itemMenu),
          selected: _selectedDestination == 4,
          onTap: () => selectDestination(4),
        )),
        Spacer(),
        (getFromList("app-mensagem").meus ?
        new Container (
            decoration: new BoxDecoration (
              gradient: screen=='messages'? LinearGradient(
              begin: Alignment.centerLeft,
              end:Alignment.centerRight,
              colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
              ):null,
            ),
            child:
        ListTile(
          contentPadding: EdgeInsets.only(left:30),
          leading: Icon(Icons.message_rounded,color:Colors.white,size:(height>732?32:28)),
          title: Text('Mensagens',style:itemMenu),
          selected: _selectedDestination == 8,
          onTap: () => selectDestination(8),
        )):SizedBox(height: 10)),
        Spacer(),
        (getFromList("app-servico").meus ?
        new Container (
            decoration: new BoxDecoration (
                gradient: screen=='servicos'? LinearGradient(
                    begin: Alignment.centerLeft,
                    end:Alignment.centerRight,
                    colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
                ):null,
            ),
            child:
        ListTile(
          contentPadding: EdgeInsets.only(left:30),
          leading: Icon(Icons.settings_rounded,color:Colors.white, size:(height>732?32:28)),
          title: Text('Serviços',style:itemMenu),
          selected: _selectedDestination == 10,
          onTap: () => selectDestination(10),
        )):SizedBox(height: 10)),
        Spacer(),
        ListTile(
          contentPadding: EdgeInsets.only(left: 30),
          leading: Icon(Icons.lock,color:Colors.white, size:(height>732?32:28)),
          title: Text('Senha',style:itemMenu),
          selected: _selectedDestination == 5,
          onTap: () => selectDestination(5),
        ),
        Spacer(),
        ListTile(
          contentPadding: EdgeInsets.only(left: 30),
          leading: Icon(Icons.info_outline,color:Colors.white,size:(height>732?32:28)),
          title: Text("Versão",style:itemMenu),
          selected: _selectedDestination ==11,
          onTap: () => selectDestination(11),
        ),
        Container(
          height: (height>732?40:30),
          margin: EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end:Alignment.centerRight,
              colors: [HexColor(Constants.red),HexColor(Constants.innerRed)]
            ),
          ),
          child: GestureDetector(child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("LOG OUT", style:itemMenu),
            ],
          ),onTap: () =>selectDestination(7),)
        ),
        SizedBox(height: 15,)
      ],
    ));
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
        Navigator.of(ctx).push(FadePageRoute(
          //builder: (context) => (isConsultant?HomeConsultor():Home()),
          builder: (context) => HomePage(),
        ));
        screen = "dashboard";
        break;
      case 1:
        //Navigator.of(ctx).pop();
        Navigator.of(ctx).push(FadePageRoute(
          //builder: (context) => (isConsultant?ElasticAlertsConsultant():ElasticAlerts()),
          builder: (context){
            instance = InnerElastic(null,null);
            return instance;
          },
        ));
        screen = "elastic";
        break;
      case 2:
        Navigator.of(ctx).push(FadePageRoute(
          //builder: (context) => (isConsultant?ZabbixAlertsConsultant():ZabbixAlerts()),
          builder: (context) => InnerZabbix(null,null),
        ));
        screen = "zabbix";
        break;
      case 3:
        Navigator.of(ctx).push(FadePageRoute(
          //builder: (context) => (isConsultant?TicketsviewConsultant():Ticketsview()),
          builder: (context) => TicketsviewConsultor(0),
        ));
        screen = "tickets";
        break;
      case 4:
        Navigator.of(ctx).push(FadePageRoute(
          builder: (context) => InnerNoticias(),
        ));
        screen = "news";
        break;
      case 5:
        Navigator.of(ctx).push(FadePageRoute(
          builder: (context) => InnerPwd(),
        ));
        screen = "password";
        break;
      case 6:
        Navigator.of(ctx).push(FadePageRoute(
          builder: (context) => InnerPreferences(),
        ));
        screen = "preferencias";
        break;
      case 7:
        //(isConsultant? logoutConsultor() : logout());
        Logoff.confirmarLogoff(ctx);
        break;
      case 8:
        Navigator.of(ctx).push(FadePageRoute(
          builder: (context) => InnerMessages(0),
        ));
        screen = "messages";
        break;
      case 10:
        Navigator.of(ctx).push(FadePageRoute(
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