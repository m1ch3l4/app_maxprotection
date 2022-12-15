//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/model/MessageModel.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
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
import '../widgets/active_project_card.dart';
import '../widgets/bottom_container.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
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
        //backgroundColor: HexColor(Constants.grey),
        body:
        SlidingUpPanel(
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0)),
          onPanelSlide: (double pos) => updateState(pos),
          panelBuilder: (sc) => _panel(sc,width,context),
          body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        ),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('messages',widget.user,textTheme),
        )
    );
  }

  //
  Widget getMain(double width){
    return SafeArea(
      child: Column(
        children: <Widget>[
          _header(width),
          Divider(
            height: 5,
            thickness: 1,
            indent: 5,
            endIndent: 5,
            color: HexColor(Constants.grey),
          ),
          _body(),
        ],
      ),
    );
  }

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

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

    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
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
    return Expanded(
        child: listView());
  }

  Widget _header(double width){
    return TopContainer(
      height: 80,
      width: width,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 0, vertical: 5.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color:Colors.white,size: 20.0),
                    tooltip: 'Voltar',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(FadePageRoute(
                        builder: (context) => HomePage(),
                      ));
                    },
                  ),
                  Text(
                    'Minhas Mensagens',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 80,)
                ],
              ),
            ),

          ]),
    );
  }

  /**
   * for (int i=0; i<5; i++)
      getAlert('titulo', day.add(Duration(days:i)),
      (i%2<1?"Gostaria de receber mais informações sobre o SonicWall":"Um consultor entrará em contato no seu telefone!"),
      (i%2<1?"":"MaxProtection"))
   */
  Widget listView(){
    DateTime day = DateTime.now().subtract(Duration(days:5));
    return ListView(
      children: <Widget>[
      for (int i = 0; i < listModel.length; i++)
        getAlert((listModel[i].tipo!="padrao"?listModel[i].tipo:""), listModel[i].data, listModel[i].texto, listModel[i].tipo, listModel[i].sender.name)
      ],
    );
  }

  Widget getAlert(String title, DateTime date, String event, String justify, String sender){
    DateFormat dayOfWeek = DateFormat('EEEE',"pt_BR");
    return Card(
        child: Column(
          children: [
            SizedBox(height: 20,),
            Row(
              //mainAxisAlignment: (justify!=""?MainAxisAlignment.end:MainAxisAlignment.start),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.only(left:5),
                    child: Text(sender,style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black45,
                      fontWeight: FontWeight.w400,)),)
                    ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(padding: EdgeInsets.only(right: 5),
                    child: Text(simpleDate.format(date)+" | "+dayOfWeek.format(date),style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black45,
                      fontWeight: FontWeight.w400,)))
                    ],
                )
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.all(0),
              minLeadingWidth: 10.0,
              title: Text(title.toUpperCase()),
              subtitle: Html(data: event,
                  onLinkTap: (url, RenderContext context, Map<String, String> attributes, element) {
                    _launchURL(url);
                  }),
              leading: (justify=="" ?
              Container(
                width: 12,
                decoration: BoxDecoration(
                    color: HexColor(Constants.red),
                    borderRadius:BorderRadius.only(
                        topLeft: Radius.circular(3.0),
                        bottomLeft: Radius.circular(3.0))
                ),
              ):SizedBox(width: 1,)),
              trailing: (justify!=""? Container(
                width: 12,
                decoration: BoxDecoration(
                    color: HexColor(Constants.red),
                    borderRadius:BorderRadius.only(
                        topLeft: Radius.circular(3.0),
                        bottomLeft: Radius.circular(3.0))
                ),
              ):SizedBox(width: 1,)),
            )
          ],
        )
    );
  }

  void _launchURL(_url) async =>
      await canLaunch(Uri.encodeFull(_url)) ? await launch(Uri.encodeFull(_url)) : throw 'Could not launch $_url';

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user);
    /** return MediaQuery.removePadding(
        context: ctx,
        removeTop: true,
        child: ListView(
          controller: sc,
          children: <Widget>[
            SizedBox(
              height: 12.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                ),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            BottomContainer(
              height: 30,
              width: width,
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      'Mais Serviços',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: HexColor(Constants.red),
                        fontWeight: FontWeight.w400,
                      )
                  ),
                  SizedBox(width:20),
                  Icon(Icons.arrow_upward,
                      color: HexColor(Constants.red), size: 30.0),
                ],
              ),
            ),
            Column(
                children: <Widget>[
                  Container(
                      color: HexColor(Constants.grey),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                ActiveProjectsCard(
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.support,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets Abertos',
                                ),
                                SizedBox(width: 20.0),
                                ActiveProjectsCard(
                                  cardColor: Colors.white,
                                  icon:Icon(Icons.watch_later_outlined,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets em Atendimento',
                                ),
                              ],
                            ),
                          ]))]),
            SizedBox(
              height: 5,
            ),
          ],
        ));**/
  }

}