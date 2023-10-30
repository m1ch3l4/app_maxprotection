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

GlobalKey<_NoticiasPageState> keyNP = new GlobalKey<_NoticiasPageState>();

class InnerNoticias extends StatelessWidget {

  static const routeName = '/news';
  SharedPref sharedPref = SharedPref();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FutureBuilder(
        future: sharedPref.read("usuario"),
        builder: (context,snapshot){
          return (snapshot.hasData ? new NoticiasPage(key: keyNP, title: 'Noticias', user: snapshot.data as Map<String, dynamic>): CircularProgressIndicator());
        },
      ),
    );
  }
}

class NoticiasPage extends StatefulWidget {
  NoticiasPage({required Key key, this.title,this.user}) : super(key: key);

  final String? title;
  final Map<String, dynamic>? user;

  @override
  _NoticiasPageState createState() => new _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  bool consultant=false;

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

    String urlApi = Constants.urlEndpoint+"news";
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    String basicAuth = "Bearer "+widget.user!["token"];

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
        for(Map<String,dynamic> i in data){
          NoticiaData tmp = NoticiaData.fromJson(i);
          //print("noticia...."+tmp.titulo+"|"+tmp.imageFile);
          listModel.add(tmp);
          if(!categorias.contains(tmp.categoria))
            categorias.add(tmp.categoria!);
        }
        destaques = listModel.sublist(0,2);
        outros = listModel.sublist(2);
        loading = false;
      });
    }else{
      if(responseData.statusCode == 401) {
        Message.showMessage("As suas credenciais não são mais válidas...");
        setState(() {
          loading=false;
        });
      }
      loading = false;
    }
  }

  DateFormat simpleDate = DateFormat('dd/MM/yy');
  String languageCode="pt-br";


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

    languageCode = "pt-br";

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;

    _fcmInit.configureMessage(context, "noticias");

    double _panelPosition = 0;

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.blue),
        body:        SlidingUpPanel(
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0)),
          onPanelSlide: (double pos) => updateState(pos),
          panelBuilder: (sc) => BottomMenu(context,sc,width,widget.user!),
          body: loading ? Center (child: CircularProgressIndicator()) : getMain(width,height),
        ),
        drawer:  Drawer(
          child: SliderMenu('noticias',widget.user!,textTheme,(width*0.5)),
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
                  child: (outros[i].imageFile!=null?
                  Image.network(
                  outros[i].imageFile!,fit:BoxFit.cover,
                  loadingBuilder: (BuildContext? context, Widget? child,
                      ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
            return child!;
            }
            return Center(
            child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
                : null,
            ),
            );
            },
            )
                      :SizedBox(height: 1,)),
                ),
            Text(outros[i].categoria!,style: TextStyle(color:HexColor(Constants.blueTxt)))]),
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
    return GestureDetector(
      onTap: (){Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => noticiaDetail(noticia), // <-- document instance
          ));},
    child:
    Container(
            height: 550,
            width: 200,
            margin: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: HexColor(Constants.greyContainer)
            ),
            child:
            Stack(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child:(noticia.imageFile!=null?
                    Image.network(
                      noticia.imageFile!,fit:BoxFit.cover,
                      loadingBuilder: (BuildContext? context, Widget? child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child!;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                        :Image.asset("images/Fundo.png"))),
        Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.only(bottom: 20),
          child:
                Text(noticia.titulo!,softWrap:true,style: TextStyle(
                  fontSize: 24.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )))
              ],
            )
            /**
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(noticia.titulo!,softWrap:true,style: TextStyle(
                  fontSize: 24.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ))
              ],
            ),**/
        )
    );
  }
  void _launchURL(_url) async =>
      await launch(_url) ? await launch(_url) : Message.showMessage("Não foi possível abrir a URL: "+_url);

}