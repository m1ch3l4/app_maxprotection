//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/Logoff.dart';
import 'package:app_maxprotection/widgets/top_container.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';import '../screens/home_page.dart';
import '../screens/inner_user.dart';
import '../utils/FCMInitialize-consultant.dart';


import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class headerTk extends StatelessWidget{

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Map<String, dynamic> usr;
  BuildContext ctx;
  String perfil;
  String status;
  int tk;
  double width;
  Function f;

  @override
  Widget build(BuildContext context) {
    return _header(width, context);
  }

  headerTk(GlobalKey<ScaffoldState> key, Map<String,dynamic> u, BuildContext context, String p, int t, double w, String s, Function ff){
    _scaffoldKey = key;
    usr = u;
    perfil = p;
    tk = t;
    width = w;
    status = s;
    ctx = context;
    f = ff;
  }

  Widget _header(double width, BuildContext context){
    return TopContainer(
      height: 208,
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
                    _scaffoldKey.currentState.openDrawer();
                  },
                ),
                Spacer(),
                Image.asset("images/lg.png",width: 150,height: 69,),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color:Colors.white,size: 20.0),
                  tooltip: 'Voltar',
                  onPressed: () {
                    f();
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
                  'Olá, '+usr['name'].toString()+" | "+perfil,
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
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: [
                    Text(
                      'Tickets '+status,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: [
                    Text(
                      tk.toString(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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