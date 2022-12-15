//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/NoticiaModel.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


void main() => runApp(new InnerNoticias());

class InnerNoticias extends StatelessWidget {

  static const routeName = '/news';
  SharedPref sharedPref = SharedPref();

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
          home: new NoticiasPage(title: 'Noticias', user: snapshot.data),
          ) : CircularProgressIndicator());
          },
          ),
    );
  }
}

class NoticiasPage extends StatefulWidget {
  NoticiasPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _NoticiasPageState createState() => new _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  bool consultant;

  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  List<NoticiaData> listModel = [];
  var loading=false;

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });

    //String urlApi = Constants.urlEndpoint+"news/last";
    String urlApi = Constants.urlEndpoint+"news";
    print("****URL API: ");
    print(urlApi);
    print("**********");

    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      final data = jsonDecode(source);
      setState(() {
        for(Map i in data){
          listModel.add(NoticiaData.fromJson(i));
        }
        loading = false;
      });
    }else{
      loading = false;
    }
  }

  DateFormat simpleDate = DateFormat('dd/MM/yy');
  String languageCode="pt-br";


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
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

    languageCode = "pt-br";

    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;

    _fcmInit.configureMessage(context, "noticias");
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
          panelBuilder: (sc) => BottomMenu(context,sc,width,widget.user),
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
                  Expanded(child: Text(
                    'Notícias de TI & Segurança',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  )),
                  SizedBox(width: 60,)
                ],
              ),
            ),

          ]),
    );
  }

  Widget listView(){
    return ListView(
      children: getChildren(),
    );
  }

  List<Widget> getChildren(){
    final df = new DateFormat('yyyy-MM-dd');
    final DateTime now = DateTime.now();
    final String formatada = df.format(now);
    List<Widget> lista = List<Widget>();
    if(listModel.length>0){
      for (int i = 0; i < listModel.length; i++)
        lista.add(getNoticia(listModel[i].titulo, listModel[i].data, listModel[i].texto,listModel[i].url));
    }else{
      lista.add(getNoticia("Sem Notícias", formatada, "Nenhuma notícia cadastrada",""));
    }

    return lista;
  }
  Widget getNoticia(String title, String date, String text, String url){
    DateFormat dayOfWeek = DateFormat('EEEE',languageCode);
    DateTime dia = DateTime.parse(date);
    return Card(
        child: Column(
          children: [
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [SizedBox(width: 18,),Text(simpleDate.format(dia)+" | "+dayOfWeek.format(dia),style: TextStyle(
                fontSize: 14.0,
                color: Colors.black45,
                fontWeight: FontWeight.w400,
              ))],
            ),
            ListTile(
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(text),
                leading: Container(
                  width: 12,
                  decoration: BoxDecoration(
                      color: HexColor(Constants.red),
                      borderRadius:BorderRadius.only(
                          topLeft: Radius.circular(3.0),
                          bottomLeft: Radius.circular(3.0))
            ))),
            ListTile(
                title: Text((url!=""?"Leia Mais":""),style: TextStyle(fontSize: 12.0)),
                onTap: (){
                  _launchURL(url);
                }
            )
          ],
        )
    );
  }
  void _launchURL(_url) async =>
      await launch(_url) ? await launch(_url) : Message.showMessage("Não foi possível abrir a URL: "+_url);

  Widget getAlert(String title, DateTime date, String event, String justify){
    DateFormat dayOfWeek = DateFormat('EEEE',languageCode);
    return Card(
        child: Column(
          children: [
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: (justify!=""?MainAxisAlignment.end:MainAxisAlignment.start),
              children: [Text(simpleDate.format(date)+" | "+dayOfWeek.format(date),style: TextStyle(
                fontSize: 14.0,
                color: Colors.black45,
                fontWeight: FontWeight.w400,
              ))],
            ),
            ListTile(
              contentPadding: EdgeInsets.all(0),
              minLeadingWidth: 10.0,
              title: Text(""),
              subtitle: Text(event),
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



}