//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/api/PushConfirmApi.dart';
import 'package:app_maxprotection/screens/home_page.dart';
import 'package:app_maxprotection/screens/inner_elastic.dart';
import 'package:app_maxprotection/screens/inner_noticias.dart';
import 'package:app_maxprotection/screens/inner_zabbix.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import 'dart:convert';

import '../screens/ticketlist-consultor.dart';
import '../screens/ticketsview-consultor.dart';
import '../widgets/custom_route.dart';
import 'perfil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../model/MessageModel.dart';
import '../model/empresa.dart';
import '../widgets/constants.dart';
import 'HexColor.dart';
import 'package:localstorage/localstorage.dart';

AudioPlayer player = AudioPlayer();
LocalStorage storage = new LocalStorage('pushmessage');
final sharedPref = SharedPref();

Future<void> playAlertSound() async{
  player.setVolume(1.0);
  player.setAsset("assets/bell.mp3");
  //player.setAsset("assets/alert.mp3");
  player.play();
}

Future<void> stopAlertSound() async{
  player.stop();
  print("Em teoria cancelou o som....");
  player.dispose();
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print(message.data["type"]); //Verificar a configuração de alert de som por tipo de mensagem
  saveToLocalStorage(message);
  isTecnico(message);
}
Future<void> saveToLocalStorage(RemoteMessage message) async{
  var now = new DateTime.now();
  var formatter = new DateFormat('dd/MM HH:mm');
  String formattedDate = formatter.format(now);

  MessageData m = new MessageData();
  m.title = message.notification.title;
  m.text = message.notification.body;
  m.type = message.data['type'];
  m.id = message.data['id'];
  m.data = formattedDate;

  if(m.id!=null) {
    print("deve armazenar a message no storage");
    await storage.ready;
    await storage.setItem(m.id, m.toJSON());
    var value = await sharedPref.getValue("pushid");
    if (value != null) {
      List<dynamic> lst = json.decode(value);
      lst.add(m.id);
      sharedPref.save("pushid", lst);
    } else {
      List<String> lst = [];
      lst.add(m.id);
      sharedPref.save("pushid", lst);
    }
  }
}

Future<bool> isTecnico(RemoteMessage message) async{
  final sharedPref = SharedPref();
  var value = await sharedPref.getValue("tecnico");
  print("FCMInitialize...isTecnico: "+value);
  if(value=="true") {
    playAlertSound();
  }
}

class FCMInitConsultor{

  static final FCMInitConsultor _instance = FCMInitConsultor._internal();
  factory FCMInitConsultor() => _instance;
  FirebaseMessaging _firebaseMessaging;
  Map<String, dynamic> user;
  List<Empresa> lst = [];
  String screen;
  BuildContext ctx;
  var messageFCM = new MessageData();

  static bool isTecnico;

  List<String> topics = [];

  FCMInitConsultor._internal() {
    if(_firebaseMessaging==null)
      _firebaseMessaging = FirebaseMessaging.instance;
  }

  void unRegisterAll() async {
    for(String s in topics) {
      print('FCMInit...unsubscribe...'+s);
      _firebaseMessaging.unsubscribeFromTopic(s);
    }
    _firebaseMessaging.deleteToken();
  }

  void deletePushStorage() async {
    storage = new LocalStorage('pushmessage');
    await storage.clear();
  }

    void registerNotification() async {
    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');


      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        messageFCM.text = message.notification?.body;
        messageFCM.title = message.notification?.title;
        if (Platform.isAndroid) {
          messageFCM.type = message.data['type'];
        } else if (Platform.isIOS) {
          messageFCM.type = message.data['type'];
        }
        //goto(message.data['type'], ctx);
        if(user["tipo"]=="T"){
          showMessage(messageFCM);
        }else{
          showSimpleMessage(messageFCM);
        }

      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage mes) {
        stopAlertSound();
        String tipo = mes.data["type"];
        goto(tipo, ctx);
      });

    } else {
      print('User declined or has not accepted permission');
    }

  }

  Map<String, dynamic> get getUsr=>user;

  Future<void> readSavedPushMessage() async{
    var value = await sharedPref.getValue("pushid");
    if(value!=null) {
      print("valor lido..."+value);
      List<dynamic> ids = json.decode(value);

      await storage.ready;
      ids.forEach((element) {
        getMessage(element.toString());
      });
    }
    print("********************");
  }
  void getMessage(String id) async{
    var jason = await json.encode(storage.getItem(id));
    print("Storage.getItem: " + jason+"|"+id);
    if(jason!=null && jason!="null") {
      MessageData m = MessageData.fromJsonLS(json.decode(jason));
      showMessage(m);
    }
  }
  //Deletando os itens exibidos...
  void removeMessageRead(String id) async{
    var value = await sharedPref.getValue("pushid");
    if (value != null) {
      List<dynamic> lst = json.decode(value);
      lst.remove(id);
      sharedPref.save("pushid", lst);
    }
    await storage.deleteItem(id);
  }
  void setConsultant(Map<String, dynamic> usr){
    user = usr;
    isTecnico=false;

    lst = [];
    if(user['tipo']=="C" && user['empresas']!=null) {
      for (Map i in user['empresas']) {
        lst.add(Empresa(i["id"], i["name"]));
      }
    }

    if(user['tipo']=='T') {
      if(user['empresas']!=null){
        for (Map i in user['empresas']) {
          lst.add(Empresa(i["id"], i["name"]));
        }
      }
      isTecnico = true;
      readSavedPushMessage();
    }

    registerOnFirebase();
    registerNotification();
  }

  void configureMessage(BuildContext context, String scr){
    ctx = context;
    screen = scr;
    //getMessage();
  }

  registerOnFirebase(){

    topics = [];

    if(user["tipo"]=="C" || user["tipo"]=="T"){
      print("FCMInit...assumindo que é consultor ou técnico...");
        lst.forEach((emp) {
          if(emp.id!="0") {
            _firebaseMessaging.subscribeToTopic('elastic' + emp.id);
            topics.add('elastic'+emp.id);
            _firebaseMessaging.subscribeToTopic('zabbix' + emp.id);
            topics.add('zabbix' + emp.id);
            _firebaseMessaging.subscribeToTopic('techsupport' + emp.id);
            topics.add('techsupport' + emp.id);
          }
        });
        if(user["tipo"]=="T") {
          _firebaseMessaging.subscribeToTopic("plantao" + user["id"]);
          topics.add('plantao'+user['id']);
        }
    }else{ //se for diretor....
      print("FCMInit...assumindo que é diretor...");
        _firebaseMessaging.subscribeToTopic(
              'elastic' + user['company_id'].toString());
        topics.add('elastic' + user['company_id'].toString());
          _firebaseMessaging.subscribeToTopic(
              'zabbix' + user['company_id'].toString());
        topics.add('zabbix' + user['company_id'].toString());
        _firebaseMessaging.subscribeToTopic('techsupport'+user['company_id'].toString());
        topics.add('techsupport'+user['company_id'].toString());
   }
     _firebaseMessaging.subscribeToTopic('news');
    topics.add('news');

    for(String s in topics) {
      print('FCMInit...registrado em:'+s);
    }

  }

  void showSimpleMessage(MessageData message){
    if(message.title!="titulo") {
      showDialog(
          context: ctx,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              title: Text(message.title,
                  style: TextStyle(color: HexColor(Constants.red))),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(message.text)
                  ],
                ),
              ),
              actions: <Widget>[
            Row (
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  child: Text('Fechar',
                      style: TextStyle(color: HexColor(Constants.blue))),
                    onPressed: () {
                      Navigator.of(context).pop();
                    }
                ),
                TextButton(
                  child: Text('Ver Ocorrência',
                      style: TextStyle(color: HexColor(Constants.blue))),
                  onPressed: () {
                    Navigator.of(context).pop();
                    goto(message.type,context);
                  },
                ),
              ])
              ],
            );
          }
      );
    }
  }

  void showMessage(MessageData message){
    if(message.title!="titulo") {
      showDialog(
          context: ctx,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              title: Text(message.title,
                  style: TextStyle(color: HexColor(Constants.red))),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(message.text)
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Ciente',
                      style: TextStyle(color: HexColor(Constants.blue))),
                  onPressed: () {
                    removeMessageRead(message.id);
                    PushApi.changePass(user["id"], message.id).then((value){
                      Navigator.of(context).pop();
                      goto(message.type,context);
                    } );
                  },
                ),
              ],
            );
          }
      );
    }
  }
  void goto(String tipo, BuildContext context){
    print("goto.userTipo: "+user["tipo"]);
    print(tipo);

    bool isConsultor = (user["tipo"]=="C"?true:false);
    switch (tipo) {
      case 'elastic':
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => InnerElastic(),));
        break;
      case 'zabbix':
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => InnerZabbix(),));
        break;
      case 'techsupport':
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => (isConsultor?TicketsviewConsultor(0):TicketlistConsultor(null, 0)),));
        break;
      case 'news':
        Navigator.of(context).pushReplacement(
            FadePageRoute(builder: (context) => InnerNoticias(),));
        break;
      default:
        Navigator.of(context).pop();
    }
  }

}