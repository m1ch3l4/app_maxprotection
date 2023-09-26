import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/HexColor.dart';
import '../widgets/constants.dart';
import 'FCMInitialize-consultant.dart';

class Logoff{

  static void confirmarLogoff(BuildContext context){
    AlertDialog alert;
    Widget cancelButton = FlatButton(
      child: Text("Cancelar"),
      onPressed:  () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
    Widget launchButton = FlatButton(
      child: Text("Quero sair!"),
      onPressed:  () {
        logoff();
      },
    );  // set up the AlertDialog
    alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0))),
      title: Text("ATENÇÃO", style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red))),
      content: Text("Ao sair você fará logoff no app e precisará fazer login novamente. Tem certeza que deseja sair?",style: TextStyle(color:HexColor(Constants.blue)),softWrap: true),
      actions: [
        cancelButton,
        launchButton,
      ],
    );  // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static logoff() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    FCMInitConsultor().unRegisterAll(); //esperando que ele consiga cancelar registro no Push...
    FCMInitConsultor().deletePushStorage(); //deletando repositório pushmessage
    exit(0);
  }
}