import 'dart:io';

import 'package:app_maxprotection/model/MessageModel.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/simpleheader.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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
import '../widgets/TopHomeWidget.dart';
import '../widgets/active_project_card.dart';
import '../widgets/bottom_container.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/closePopup.dart';
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
    return FutureBuilder(
        future: sharedPref.read("usuario"),
        builder: (context,snapshot){
          return (snapshot.hasData ? new MessagesPage(title: 'Mensagens', user: snapshot.data as Map<String, dynamic>, tipo: tipo)
          : CircularProgressIndicator());
        },
    );
  }
}

class MessagesPage extends StatefulWidget {
  MessagesPage({this.title,this.user,this.tipo});

  final String? title;
  final Map<String, dynamic>? user;
  final int? tipo;

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
  double width=0.0;
  double altura = 0.0;


   bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
     Navigator.of(context).maybePop(context).then((value) {
       if (value == false) {
         Navigator.pushReplacement(
             context,
             FadePageRoute(
               builder: (ctx) => HomePage(),
             ));
       }
     });
     return true;
  }

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    getData();
    _fabHeight = _initFabHeight;
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    languageCode = Localizations.localeOf(context).languageCode;
    width = MediaQuery.of(context).size.width;
    altura = MediaQuery.of(context).size.height;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "messages");
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
        //body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        body: //loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        SlidingUpPanel(
          color: HexColor(Constants.grey),
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0)),
          onPanelSlide: (double pos) => updateState(pos),
          panelBuilder: (sc) => _panel(sc,width,context),
          body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        ),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('messages',widget.user!,textTheme,(width*0.5)),
        )
    );
  }

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user!);
  }

  //
  Widget getMain(double width){
    double tam = (altura<700?altura-70:altura-30);
    return SafeArea(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
          children:[
            simpleHeader(_scaffoldKey,context,width,(listModel.length>4?200:100)),
            if(listModel.length<5)
              menuTickets(),
            Container(padding:EdgeInsets.only(top:(listModel.length>4?100:170),left:10,right: 10),height: tam, child:_body())
          /**simpleHeader(_scaffoldKey,context,width,200),
           Container(padding:EdgeInsets.only(top:80,left:10,right: 10),height: tam, child:_body())**/
          ])
        ],
      )
    );
  }

  Widget menuTickets(){
    return Container(
        alignment: Alignment.center,
        margin:EdgeInsets.only(left: width*0.04),
        padding:  EdgeInsets.only(top:130),
        width: width*.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: opcoesMenu(),
        )
    );
  }
  List<Widget> opcoesMenu(){
    List<Widget> lst = [];
    lst.add(SizedBox(width: width*0.03,),);
    print("...."+widget.tipo.toString());
    switch(widget.tipo){
      case 0:
        lst.add(TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.42,
          icon:Icon(Icons.mail_rounded,color: Colors.white,size: 24,),
          title: "Mensagens Tickets",ctx: context,r:false,
          action: InnerMessages(2) // <-- document instance
        ));
        lst.add(Spacer());
        lst.add(TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.4,
            title: "Mensaens Siem",ctx: context,r:false,
            action: InnerMessages(1),
            icon:Icon(Icons.mail_rounded,color: Colors.white,size: 24,),),);
        break;
      case 1:
        lst.add(TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.42,
            icon:Icon(Icons.mail_rounded,color: Colors.white,size: 24,),
            title: "Mensagens",ctx: context,r:false,
            action: InnerMessages(0) // <-- document instance
        ));
        lst.add(Spacer());
        lst.add(TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.4,
          title: "Mensagens Tickets",ctx: context,r:false,
          action: InnerMessages(2),
          icon:Icon(Icons.mail_rounded,color: Colors.white,size: 24,),),);
        break;
      case 2:

        lst.add(TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.42,
            icon:Icon(Icons.mail_rounded,color: Colors.white,size: 24,),
            title: "Mensagens",ctx: context,r:false,
            action: InnerMessages(0) // <-- document instance
        ));
        lst.add(Spacer());
        lst.add(TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.4,
          title: "Mensagens Siem",ctx: context,r:false,
          action: InnerMessages(1),
          icon:Icon(Icons.mail_rounded,color: Colors.white,size: 24,),),);
        break;
    }
    return lst;
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
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user!['id'].toString();
        break;
      case 1:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user!['id'].toString()+"/siem";
        break;
      case 2:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user!['id'].toString()+"/moviedesk";
        break;
      case 3:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user!['id'].toString()+"/zabbix";
        break;
      case 4:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user!['id'].toString()+"/lead";
        break;
      default:
        urlApi = Constants.urlEndpoint+"message/chatmsg/"+widget.user!['id'].toString();
    }


    print("****URL API: ");
    print(urlApi);
    print("**********");

    String basicAuth = "Bearer "+widget.user!["token"];

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
    print("response.data "+responseData.statusCode.toString());
    print("response..."+responseData.toString());
    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      print("source..."+source.toString());
      final data = jsonDecode(source);
      setState(() {
        for(Map<String,dynamic> i in data){
          var alert = ChatData.fromJson(i);
          listModel.add(alert);
        }
        loading = false;
      });
    }else{
      if(responseData.statusCode == 401) {
        listModel.clear();
        Message.showMessage("As suas credenciais não são mais válidas...");
        setState(() {
          loading=false;
        });
      }
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
        getAlert((listModel[i].tipo!="padrao"?listModel[i].tipo!:""), listModel[i].data!, listModel[i].texto!, listModel[i].tipo!, (listModel[i].sender!=null?listModel[i].sender!.name!:"-"),i)
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
            //SizedBox(height: 20,),
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
                  GestureDetector(
                    child:
                  Icon(Icons.more_horiz,color: cl,),
                    onTap:(){
                      showAlert(context,i);
                    },
                  )
                ],
              )
            ],
            ),
            SizedBox(height: 2,),
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
            SizedBox(height: 2,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: width*0.65,
                  child:Text(removeAllHtmlTags(event),overflow:TextOverflow.fade,style: TextStyle(color:clTexto),),
                ),
                Column(
                  children: [Text(valid,style:TextStyle(color:clTexto))],
                )
              ],
            )
          ],
        ))));
  }

  String removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(
        r"<[^>]*>",
        multiLine: true,
        caseSensitive: true
    );
    String txt =htmlText.replaceAll(exp,'');
    return txt;
  }

  Future<void> showAlert(BuildContext context,int index) async {
    ChatData d = listModel.elementAt(index);
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            content:
            Stack(
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //crossAxisAlignment: CrossAxisAlignment.,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text("Detalhes da Mensagem",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red))),
                                Spacer(),
                                closePopup()
                              ]
                              ,),
                            SizedBox(height: 20,),
                            detalhes(d),
                          ]))
                ]
            ),
            actions: <Widget>[
            ],
          );
        });
  }

  Widget detalhes(ChatData tech){
    return Card(
        elevation: 0,
        child:
        Container(
            width: 380,
            constraints: BoxConstraints(
                minHeight: 150,
                maxHeight: 300
            ),
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(simpleDate.format(tech.data!), style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))
                      ],)
                  ],
                ),
                SizedBox(height: 15,),
                Row(
                  children: [Column(children: [Text("De:",style:TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(child:
                    Text(tech.sender!.name!,style: TextStyle(color:HexColor(Constants.blue))))
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  children: [Column(children: [Text("Mensagem:",style:TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(child:
                    Text(removeAllHtmlTags(tech.texto!),style: TextStyle(color:HexColor(Constants.blue))))
                  ],
                ),
                SizedBox(height: 15,),
              ],
            )
        )
    );
  }

  void _launchURL(_url) async =>
      await canLaunch(Uri.encodeFull(_url)) ? await launch(Uri.encodeFull(_url)) : throw 'Could not launch $_url';



}