//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/model/MessageModel.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/simpleheader.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:url_launcher/url_launcher.dart';

import '../model/ChatMessage.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../widgets/active_project_card.dart';
import '../widgets/bottom_container.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


class InnerMessages extends StatelessWidget {

  static const routeName = '/messages';
  SharedPref sharedPref = SharedPref();

  final int tipo; //0 padrao, 1 - siem, 2 - ticket, 3 - zabbix, 4- lead

  InnerMessages(this.tipo);

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
            home: new MessagesPage(title: 'Mensagens', user: snapshot.data, tipo: tipo),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class MessagesPage extends StatefulWidget {
  MessagesPage({Key key, this.title,this.user,this.tipo}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;
  final int tipo;

  @override
  _MessagesPageState createState() => new _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  DateFormat simpleDate = DateFormat('dd/MM/yy');
  String languageCode="pt_BR";
  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  List<ChatData> listModel = [];
  var loading = false;


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }

  void initState() {
    super.initState();
    getData();
    _fabHeight = _initFabHeight;
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    languageCode = Localizations.localeOf(context).languageCode;
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "messages");
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
        body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('messages',widget.user,textTheme,(width*0.5)),
        )
    );
  }

  //
  Widget getMain(double width){
    return SafeArea(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
          children:[
          simpleHeader(_scaffoldKey,context,width),
           Container(padding:EdgeInsets.only(top:100,left:10,right: 10),height: MediaQuery.of(context).size.height-50, child:_body())
          ])
        ],
      )
    );
  }

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });
    String urlApi = "";
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;


    //0 padrao, 1 - siem, 2 - ticket, 3 - zabbix, 4- lead
    switch(widget.tipo){
      case 0:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user['id'].toString();
        break;
      case 1:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user['id'].toString()+"/siem";
        break;
      case 2:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user['id'].toString()+"/moviedesk";
        break;
      case 3:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user['id'].toString()+"/zabbix";
        break;
      case 4:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user['id'].toString()+"/lead";
        break;
      default:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user['id'].toString();
    }


    print("****URL API: ");
    print(urlApi);
    print("**********");

    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));

    Map<String, String> h = {
      "Authorization": basicAuth,
    };
    if(ssl) {
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5));
    }else{
      responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5));
    }
    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      print("source...");
      print(source);
      final data = jsonDecode(source);
      setState(() {
        for(Map i in data){
          var alert = ChatData.fromJson(i);
          listModel.add(alert);
        }
        loading = false;
      });
    }else{
      loading = false;
    }
  }


  Widget _body(){
    return SingleChildScrollView(child:listView());
  }

    Widget listView(){
    DateTime day = DateTime.now().subtract(Duration(days:5));
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: <Widget>[
      for (int i = 0; i < listModel.length; i++)
        getAlert((listModel[i].tipo!="padrao"?listModel[i].tipo:""), listModel[i].data, listModel[i].texto, listModel[i].tipo, (listModel[i].sender!=null?listModel[i].sender.name:"-"),i)
      ],
    );
  }

  Widget getAlert(String title, DateTime date, String event, String justify, String sender, int i){
    Color par = HexColor(Constants.red);
    Color impar = HexColor(Constants.blue);
    Color cl = par;
    Color clTexto = impar;
    if(i%2>0) {
      cl = impar;
      clTexto = par;
    }else {
      cl = par;
      clTexto = impar;
    }

    String valid = "";
    DateTime hoje = DateTime.now();
    final difference = hoje.difference(date).inDays;
    if(difference<1)
      valid = "Novo";
    else
      valid = difference.toString()+"d";

    DateFormat dayOfWeek = DateFormat('EEEE',"pt_BR");
    return
      Card(
          margin: EdgeInsets.all(15),
          child:
          ClipPath(
          clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5))),
    child:
    Container(
    decoration: BoxDecoration(
    border: Border(
    left: BorderSide(color: cl, width: 10),
    ),
    ),
    //margin: EdgeInsets.all(12.0),
    padding: EdgeInsets.all(12.0),
    //height: 300,
    child:
    Column(
    mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
              Column(
                children: [
                  Text(simpleDate.format(date),style:TextStyle(color:cl,fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.more_horiz,color: cl,)
                ],
              )
            ],
            ),
            Row(
              children: [
                Column(
                  children: [
                    Text(sender,style: TextStyle(
                      fontSize: 14.0,
                      color: clTexto
                      ,fontWeight: FontWeight.bold))
                    ],
                )]),
            Row(
              children: [
                Expanded(child:
                Column(
                  children: [Text(removeAllHtmlTags(event),style: TextStyle(color:clTexto),)],
                )),
                Column(
                  children: [Text(valid,style:TextStyle(color:clTexto))],
                )
              ],
            )
            /**ListTile(
              contentPadding: EdgeInsets.zero,
              //minLeadingWidth: 10.0,
              title: Text(title.toUpperCase(),style:TextStyle(color:clTexto)),
              subtitle: Html(data: event,
                  onLinkTap: (url, RenderContext context, Map<String, String> attributes, element) {
                    _launchURL(url);
                  }),
            )**/
          ],
        ))));
  }

  String removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(
        r"<[^>]*>",
        multiLine: true,
        caseSensitive: true
    );

    return htmlText.replaceAll(exp, '');
  }

  void _launchURL(_url) async =>
      await canLaunch(Uri.encodeFull(_url)) ? await launch(Uri.encodeFull(_url)) : throw 'Could not launch $_url';

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user);
  }

}