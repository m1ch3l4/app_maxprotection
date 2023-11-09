import 'dart:io';

import 'package:app_maxprotection/screens/inner_user.dart';
import 'package:app_maxprotection/widgets/top_container.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_page.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/Logoff.dart';
import 'constants.dart';
import 'custom_route.dart';

class headerAlertas extends StatelessWidget{

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Map<String, dynamic>? usr;
  BuildContext? ctx;
  String? perfil;
  String? status;
  double? width;
  double? het;

  @override
  Widget build(BuildContext context) {
    return _header(width!, context);
  }

  headerAlertas(GlobalKey<ScaffoldState> key, Map<String,dynamic> u, BuildContext context, double w, double _height, String s){
    _scaffoldKey = key;
    usr = u;
    perfil = "depois...";
    width = w;
    status = s;
    het = _height;
    ctx = context;
  }

  Widget _header(double width, BuildContext context){
    if(usr!["tipo"]=="D")
      perfil = "Diretor";
    if(usr!["tipo"]=="T")
      perfil = "Analista";
    if(usr!["tipo"]=="C")
      perfil = "Consultor";
    
    return TopContainer(
      height: (het!=null?het:200),
      width: width,
      color: HexColor(Constants.blue),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(children: [SizedBox(height: 10,)],),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.menu, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),
                Spacer(),
                Image.asset("images/lg.png",width: 150,height: 69,),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    Navigator.of(ctx!).maybePop(ctx).then((value) {
                      if (value == false) {
                        Navigator.push(
                            ctx!,
                            FadePageRoute(
                              builder: (ctx) => HomePage(),
                            ));
                      }
                    });
                    /**Navigator.of(ctx).push(FadePageRoute(
                      builder: (ctx) => HomePage(),
                    ));**/
                  },
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.person_outline_outlined, color:Colors.white,size: 20.0),
                  tooltip: 'Perfil',
                  onPressed: () {
                    cadastro(context);
                  },
                ),
                Expanded(child: Text(
                  'Olá, '+usr!['name'].toString()+" | "+perfil!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.exit_to_app_outlined, color:Colors.white,size: 20.0),
                  tooltip: 'Sair',
                  onPressed: () {
                    Logoff.confirmarLogoff(context);
                  },
                )
              ],
            ),
            const Divider(
              height: 3,
              thickness: 1,
              indent: 5,
              endIndent: 5,
              color: Colors.white,
            ),
            SizedBox(height: 15,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: [
                    Container(
                      decoration:  BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.white))
                      ),
                      child:
                    Text(
                      status!,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
              ],
            )
          ]),
    );
  }
  void cadastro(BuildContext context){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => (InnerUser()),
    ));
  }


}