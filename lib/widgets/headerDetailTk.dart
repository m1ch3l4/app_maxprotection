import 'dart:io';

import 'package:app_maxprotection/widgets/top_container.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_page.dart';
import '../screens/inner_user.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/Logoff.dart';
import 'constants.dart';
import 'custom_route.dart';

class headerTkDetail extends StatelessWidget{

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  BuildContext? ctx;
  String? title;
  String? tipo;
  String? tkid;
  double? width;
  Function? f;

  @override
  Widget build(BuildContext context) {
    return _header(width!, context);
  }

  headerTkDetail(GlobalKey<ScaffoldState> key, BuildContext context, double w, String tit, String tip, String tki, Function ff){
    _scaffoldKey = key;
    width = w;
    title = tit;
    tipo = tip;
    tkid = tki;
    ctx = context;
    f = ff;
  }

  Widget _header(double width, BuildContext context){
    return TopContainer(
      height: 190,
      width: width,
      color: HexColor(Constants.blue),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
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
                  tooltip: 'Voltar',
                  onPressed: () {
                    f!();
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
                  tkid!+' - '+title!,
                  maxLines: 2,
                  softWrap: true,
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
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                (tipo=="1"?Image.asset("images/check.png",height: 20,width: 20): SizedBox(width: 1,)),
                    Text(
                      'PÚBLICO',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(width: 10,),
                (tipo=="2"?Image.asset("images/check.png",height: 20,width: 20): SizedBox(width: 1,)),
                    Text(
                      'INTERNO',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    )
              ],
            ),
            Divider(color: Colors.white,indent: width*0.18,
              endIndent: width*0.18,height: 0,),
          ]),
    );
  }

  void cadastro(BuildContext context){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => (InnerUser()),
    ));
  }

}