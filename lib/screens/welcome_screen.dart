import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../utils/FingerPrintAuth.dart';
import '../utils/HexColor.dart';
import '../utils/Message.dart';
import '../utils/SharedPref.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/top_container.dart';
import 'contactus.dart';
import 'login_request.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  static const routeName = '/welcome';

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  bool firstLogin = true;

  FingerPrintAuth fp = new FingerPrintAuth();
  SharedPref sharedPref = SharedPref();

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

  void setState(){
    _fabHeight = _initFabHeight;
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
              if (snapshot.data!=null && snapshot.data.toString().length>0) {
                firstLogin = false;
              } else {
                firstLogin = true;
              }
            return buildWelcomeScrenn(context);
            }
    },
    ));
  }

  Widget buildWelcomeScrenn(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: HexColor(Constants.red),
      body: Column(
        children: <Widget>[
          _header(context,width,(height*0.75)),
          _body(context, width, (height*0.25)),
        ],
      ),
    );
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
                      'Olá,',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 30,),
                    Text(
                      'Entre em contato com o nosso canal de atendimento e acesse todos os nossos serviços.',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 70,),
                    ElevatedButton(
                        child: Text(
                            "Solicitar login de acesso",
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
                        onPressed: () {
                          Navigator.of(context).push(FadePageRoute(
                            builder: (context)=>LoginRequest(),
                          ));
                        }
                    )
    ],
                ))
              ],
            ),
          ]),
    );
  }
  Widget _body(BuildContext context, double width, double height){
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
                      icon: const Icon(Icons.lock_outline, color:Colors.white,size: 48.0),
                      tooltip: 'Ver todos',
                      onPressed: () {
                        Navigator.of(context).push(FadePageRoute(
                          builder: (context)=>LoginScreen(),
                        ));
                      },
                    ),
                        SizedBox(height: 15,),
                        GestureDetector(
                        onTap: (){
                        Navigator.of(context).push(FadePageRoute(
                        builder: (context)=>LoginScreen(),
                        ));
                        },
                        child:Text(
                            'Já Possui login? Clique aqui',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.white))
                    )]
                    )),
                    Expanded(
                      child:
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    IconButton(
                      icon: const Icon(Icons.chat_outlined, color:Colors.white,size: 48.0),
                      tooltip: 'Ver todos',
                      onPressed: () {
                        Navigator.of(context).push(FadePageRoute(
                          builder: (context)=>ContatcusScreen(),
                        ));
                      },
                    ),
                        SizedBox(height: 15,),
                    GestureDetector(
                    onTap:(){
                      Navigator.of(context).push(FadePageRoute(
                      builder: (context)=>ContatcusScreen(),
                      ));
                    },
                    child:Text(
                            "Fale Conosco",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.white)))]),
                    ),
                      Expanded(
                        child:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    IconButton(
                      icon: const Icon(Icons.fingerprint, color:Colors.white,size: 48.0),
                      tooltip: 'Ver todos',
                      onPressed: () {
                        biometricsAuth(context);
                      },
                    ),
                        SizedBox(height: 15,),
                      GestureDetector(
                      onTap: (){
                        biometricsAuth(context);
                      },child:
                        Text(
                            "Autenticação com Impressão Digital",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14,color:Colors.white)))
                    ]))
                  ],
                )
              ],)
            ),
          ],
        ),
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
              builder: (context)=>LoginScreen(),
            ));
          }
        });
    }
  }


}
