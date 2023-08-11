//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/screens/noticia_detail.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/headerNoticias.dart';
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
import '../utils/HttpsClient.dart';
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
  List<NoticiaData> destaques = [];
  List<NoticiaData> outros = [];

  var loading=false;

  List<String> categorias = [];

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });

    //String urlApi = Constants.urlEndpoint+"news/last";
    String urlApi = Constants.urlEndpoint+"news";
    print("****URL API: ");
    print(urlApi);
    print("**********");
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));

    print("...u.:"+u);
    print("...p.:"+p);

    Map<String, String> h = {
      "Authorization": basicAuth,
    };
    if(ssl){
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5));
    }else {
      responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5));
    }

    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      final data = jsonDecode(source);
      setState(() {
        for(Map i in data){
          NoticiaData tmp = NoticiaData.fromJson(i);
          listModel.add(tmp);
          if(!categorias.contains(tmp.categoria))
            categorias.add(tmp.categoria);
        }
        destaques = listModel.sublist(0,2);
        outros = listModel.sublist(2);
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
    double height = MediaQuery.of(context).size.height;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;

    _fcmInit.configureMessage(context, "noticias");

    double _panelPosition = 0;

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.blue),
        body:loading ? Center (child: CircularProgressIndicator()) : getMain(width,height),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('noticias',widget.user,textTheme,(width*0.5)),
        )
    );
  }

  Widget getMain(double width, double height){
    return SafeArea(
      child:
      Stack(children:[
        Positioned(
        bottom:0,
        child: Container(width:width,color: HexColor(Constants.grey),child: SizedBox(height: height*0.5,),),
      ),
      Column(
        children: <Widget>[
         headerNoticias(_scaffoldKey, context, width,verTodas),
         Container(
           margin: EdgeInsets.only(top:10.0,bottom:10.0),
            padding: EdgeInsets.only(left:10.0,right: 10.0),
            child: _categorias(),
            height: height*0.04,
          ),
          Container(
            height:height*0.3,
            child: _body(),
          ),
          Row(
            children: [Text("    RECENTES",style: TextStyle(color: HexColor(Constants.blueTxt)),)],),
          Container(
            alignment: Alignment.bottomCenter,
            height: height*0.27,
            child: listOthers(),
          )
        ],
      )])
    );
  }
  Widget _body(){
    return ListView.builder(
      itemCount: destaques.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context,index) =>getNoticia(destaques[index]),
          );
  }

  Widget _categorias(){
    return ListView(
      scrollDirection: Axis.horizontal,
      children: childCategory(),
    );
  }
  List<Widget> childCategory(){
    List<Widget> list = [];
    for(int i=0;i<categorias.length;i++){
      list.add(buttonCategoria(categorias[i], i));
      list.add(SizedBox(width: 10,));
    }
    return list;
  }

  Widget buttonCategoria(String item, int i){
    return GestureDetector(
        child:
        Container(
        width: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [HexColor(Constants.innerRed),HexColor(Constants.red)]
          ),
          color: HexColor(Constants.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(item.toUpperCase(), style:TextStyle(color:Colors.white)),
          ],
        )
    ),
      onTap: (){
          filtroNoticia(i);
      },
    );
  }

  Widget listOthers(){
        return    ListView(
              children: getOthers(),
            );
  }
  List<Widget> getOthers(){
    List<Widget> list=[];
    for(int i=0;i<outros.length;i++){
      list.add(
        GestureDetector(
            onTap: (){Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => noticiaDetail(outros[i]), // <-- document instance
                ));},
          child:
          Container(
            height: 40,
            width: 260,
            margin: EdgeInsets.all(10.0),
            //padding: EdgeInsets.only(left: 10.0,top:10.0),
            child:
            Row(
                children: [
                Container(
                height: 40,
                width: 60,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: HexColor(Constants.greyContainer)
                ),margin: EdgeInsets.only(right: 10),
                  child: (outros[i].imageFile!=null?Image.network (
                      outros[i].imageFile,
                      fit:BoxFit.cover):SizedBox(height: 1,)),
                ),
            Text(outros[i].categoria,style: TextStyle(color:HexColor(Constants.blueTxt)))]),
              decoration: BoxDecoration(
                border: Border.all(
                    color: HexColor(Constants.greyContainer),
                    width: 1.0,
                    style: BorderStyle.solid
                ),
                borderRadius: BorderRadius.circular(10))
      )));
    }
    return list;
  }

  verTodas(){
    setState(() {
      destaques = listModel.sublist(0,2);
      outros = listModel.sublist(2);
    });
  }
  filtroNoticia(int i){
    String cat = categorias[i];
    List<NoticiaData> filtrada = [];

    listModel.forEach((element) {
      if(element.categoria == cat)
        filtrada.add(element);
    });

    setState(() {
      if(filtrada.length<1){
        destaques=[];
        outros=[];
      }
      if(filtrada.length>2) {
        destaques = filtrada.sublist(0, 2);
        outros = filtrada.sublist(2);
      }else{
        destaques = filtrada;
        outros = [];
      }
    });
  }
  Widget getNoticia(NoticiaData noticia){
    DateFormat dayOfWeek = DateFormat('EEEE',languageCode);
    DateTime dia = DateTime.parse(noticia.data);
    return GestureDetector(
      onTap: (){Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => noticiaDetail(noticia), // <-- document instance
          ));},
    child:
    Container(
          margin: EdgeInsets.all(5.0),
          padding: EdgeInsets.all(20),
          //color: HexColor(Constants.greyContainer),
          height: 550,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
              image:(noticia.imageFile!=null?DecorationImage(

                image: Image.network(noticia.imageFile).image,
                fit: BoxFit.cover,
              ):DecorationImage(image:Image.asset("images/Fundo.png").image,opacity:85, fit: BoxFit.fill)),
            color: HexColor(Constants.greyContainer)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [Expanded(child: Text(noticia.titulo,softWrap:true,style: TextStyle(
                  fontSize: 24.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )))],
              )
            ],
          ),
        ));
  }
  void _launchURL(_url) async =>
      await launch(_url) ? await launch(_url) : Message.showMessage("Não foi possível abrir a URL: "+_url);

}