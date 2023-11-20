import 'dart:io';

import 'package:app_maxprotection/api/PushConfirmApi.dart';
import 'package:app_maxprotection/model/TechSupportModel.dart';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/screens/inner_elastic.dart';
import 'package:app_maxprotection/screens/inner_messages.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:convert';

import '../screens/inner_noticias.dart';
import '../screens/inner_zabbix.dart';
import '../screens/ticket-detail.dart';
import '../screens/ticketlist-consultor.dart';
import '../widgets/custom_route.dart';
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
  print("*****Handling a background message: ${message.messageId}");
  print(message.data["type"]); //Verificar a configuração de alert de som por tipo de mensagem
  saveToLocalStorage(message);
  isTecnico(message);
}
MessageData convertMessage(RemoteMessage message){
  var now = new DateTime.now();
  var formatter = new DateFormat('dd/MM HH:mm');
  String formattedDate = formatter.format(now);

  MessageData m = new MessageData();
  m.title = message.notification?.title;
  m.text = message.notification?.body;
  m.type = message.data['type'];
  m.id = message.data['id'];
  m.enterprise = message.data['eid'];
  m.aid = message.data['aid'];
  m.msgid = (message.data['msgid']!=null?message.data['msgid']:"-1");
  m.data = formattedDate;
  return m;
}
Future<void> saveToLocalStorage(RemoteMessage message) async{

  MessageData m = convertMessage(message);

  if(m.id!=null) {
    print("deve armazenar a message no storage");
    await storage.ready;
    await storage.setItem(m.id!, m.toJSON());
    var value = await sharedPref.getValue("pushid");
    if (value != null) {
      List<dynamic> lst = json.decode(value);
      lst.add(m.id);
      sharedPref.save("pushid", lst);
    } else {
      List<String> lst = [];
      lst.add(m.id!);
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
  return true;
}

class FCMInitConsultor{

  static final FCMInitConsultor _instance = FCMInitConsultor._internal();
  factory FCMInitConsultor() => _instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  //late Map<String, dynamic> user;
  late Usuario user;
  List<Empresa> lst = [];
  late String screen;
  late BuildContext ctx;
  var messageFCM = new MessageData();

  static bool isTecnico=false;

  List<String> topics = [];

  FCMInitConsultor._internal() {
    if(_firebaseMessaging==null) {
      _firebaseMessaging = FirebaseMessaging.instance;
    }
  }

  Future<void> unRegisterAll() async {
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
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    setListeners();

  }

  setListeners(){
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler
    );

    checkPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      messageFCM = convertMessage(message);

      if (Platform.isAndroid) {
        messageFCM.type = message.data['type'];
      } else if (Platform.isIOS) {
        messageFCM.type = message.data['type'];
      }
      //goto(message.data['type'], ctx);
      if(user.tipo=="T"){
        showMessage(messageFCM);
      }else{
        showSimpleMessage(messageFCM);
      }

    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage mes) {
      stopAlertSound();
      String tipo = mes.data["type"];
      String eid = mes.data["eid"];
      messageFCM = convertMessage(mes);
      goto(messageFCM, ctx);
    });
  }


  Future<bool> checkPermission() async {
    if (!await Permission.notification.isGranted) {
      PermissionStatus status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }


  Usuario get getUsr=>user;

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

  Future<void> setConsultant(Usuario usr) async {
    user = usr;
    isTecnico=false;


    lst = [];
    if(user.tipo=="C" && user.empresas!=null) {
      lst.addAll(user.empresas);
      /**for (Map i in user['empresas']) {
        lst.add(Empresa.fromJson(i as Map<String, dynamic>));
      }**/
    }

    if(user.tipo=='T') {
      if(user.empresas!=null){
        /**for (Map i in user['empresas']) {
          lst.add(Empresa.fromJson(i as Map<String,dynamic>));
        }**/
        lst.addAll(user.empresas);
      }
      isTecnico = true;
      readSavedPushMessage();
    }

    registerOnFirebase();
    registerNotification();
    print("setou FCM....");
  }

  void configureMessage(BuildContext context, String scr){
    ctx = context;
    screen = scr;
    //getMessage();
  }

  registerOnFirebase(){

    topics = [];

    if(user.tipo=="C" || user.tipo=="T"){
      print("FCMInit...assumindo que é consultor ou técnico...");
      lst.map((item) {
        if(item.id!="0"){
          if(item.siem!) {
            _firebaseMessaging.subscribeToTopic('elastic' + item.id!);
            topics.add('elastic' + item.id!);
          }
          if(item.zabbix!) {
            _firebaseMessaging.subscribeToTopic('zabbix' + item.id!);
            topics.add('zabbix' + item.id!);
          }
          _firebaseMessaging.subscribeToTopic('techsupport' + item.id!);
          topics.add('techsupport' + item.id!);
        }
      }).toList();

      /** lst.forEach((emp) {
          if(emp.id!="0") {
            _firebaseMessaging.subscribeToTopic('elastic' + emp.id);
            topics.add('elastic'+emp.id);
            _firebaseMessaging.subscribeToTopic('zabbix' + emp.id);
            topics.add('zabbix' + emp.id);
            _firebaseMessaging.subscribeToTopic('techsupport' + emp.id);
            topics.add('techsupport' + emp.id);
          }
        }); **/
        if(user.tipo=="T" && user.interno!) {
          _firebaseMessaging.subscribeToTopic("plantao" + user.id!);
          topics.add('plantao'+user.id!);
        }
    }else{ //se for diretor....
      print("FCMInit...assumindo que é diretor...");
        _firebaseMessaging.subscribeToTopic(
              'elastic' + user.idempresa.toString());
        topics.add('elastic' + user.idempresa.toString());
          _firebaseMessaging.subscribeToTopic(
              'zabbix' + user.idempresa.toString());
        topics.add('zabbix' + user.idempresa.toString());
        _firebaseMessaging.subscribeToTopic('techsupport'+user.idempresa.toString());
        topics.add('techsupport'+user.idempresa.toString());
   }
     _firebaseMessaging.subscribeToTopic('news');
    topics.add('news');
    _firebaseMessaging.subscribeToTopic("message"+user.id!);
    topics.add('message'+user.id!);

    for(String s in topics) {
      print('FCMInit...registrado em:'+s);
    }

  }

  void showSimpleMessage(MessageData message){
    print("*******RECEBEU Notificacao. showSimpleMessage: "+message.text!);
    if(message.title!="titulo") {
      showDialog(
          context: ctx,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              title: Text(message.title!,
                  style: TextStyle(color: HexColor(Constants.red))),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(message.text!)
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
                      Navigator.of(context, rootNavigator: true).pop();
                      //Navigator.of(context).pop();
                    }
                ),
                TextButton(
                  child: Text('Ver Ocorrência',
                      style: TextStyle(color: HexColor(Constants.blue))),
                  onPressed: () {
                    Navigator.of(context).pop();
                    goto(message,context);
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
    print("*******RECEBEU Notificacao. showMessage: "+message.text!);
    if(message.title!="titulo") {
      showDialog(
          context: ctx,
          builder: (BuildContext bdctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              title: Text(message.title!,
                  style: TextStyle(color: HexColor(Constants.red))),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(message.text!)
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Ciente',
                      style: TextStyle(color: HexColor(Constants.blue))),
                  onPressed: () {
                    removeMessageRead(message.id!);
                    PushApi.changePass(user.id!, message.id!).then((value){
                      //Navigator.of(bdctx).pop();
                      //Navigator.of(ctx).pop();
                      Navigator.of(bdctx, rootNavigator: true).pop();
                      goto(message,bdctx);
                    } );
                  },
                ),
              ],
            );
          }
      );
    }
  }
  void goto(MessageData msg, BuildContext context){
    print("goto.userTipo: "+user.tipo!);
    print(msg.type);
    print("Empresa.id: "+msg.enterprise!);
    print("Alert.id: "+msg.aid!);

    bool isConsultor = (user.tipo=="C"?true:false);
    switch (msg.type) {
      case 'elastic':
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => InnerElastic(msg.enterprise,msg.aid),));
        break;
      case 'zabbix':
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => InnerZabbix(msg.enterprise!,msg.aid!),));
        break;
      case 'techsupport':
        Empresa emp = Empresa(msg.enterprise,"");
        TechSupportData tech = TechSupportData(null,null,null,msg.aid,null,null);

        Navigator.of(context).pushReplacement(FadePageRoute(
          //builder: (context) => (isConsultor?TicketsviewConsultor(0):TicketlistConsultor(null, 0)),));
          builder: (context) => (isConsultor?TicketDetail(tech,emp,1):TicketlistConsultor(null, 0)),));
        break;
      case 'news':
        Navigator.of(context).pushReplacement(
            FadePageRoute(builder: (context) => InnerNoticias(),));
        break;
      case 'msg':
        //0 padrao, 1 - siem, 2 - ticket, 3 - zabbix, 4- lead
        Navigator.of(context).pushReplacement(FadePageRoute(builder:(context)=> InnerMessages(int.parse(msg.msgid!)),)); //parseint
        break;
      default:
        Navigator.of(context).pop();
    }
  }

}