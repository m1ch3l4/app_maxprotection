// @dart=2.10
import 'package:app_maxprotection/screens/inner_noticias.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

import '../api/PushConfirmApi.dart';
import '../model/NoticiaModel.dart';
import '../model/usuario.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/Message.dart';
import '../utils/SharedPref.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';

class noticiaDetail extends StatelessWidget {

final NoticiaData ticket;
SharedPref sharedPref = SharedPref();

noticiaDetail(this.ticket){
}
static const routeName = '/noticiadetail';
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
          home: new NoticiaPage(title: ticket.titulo, user: snapshot.data,ticket: ticket),
        ) : CircularProgressIndicator());
      },
    ),
  );
}
}

class NoticiaPage extends StatefulWidget {
  NoticiaPage({Key key, this.title, this.user, this.ticket}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;
  final NoticiaData ticket;


  @override
  _NoticiaPageState createState() => new _NoticiaPageState();
}

class _NoticiaPageState extends State<NoticiaPage> {
  NoticiaData detail;
  var loading = false;
  bool isConsultor = false;

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  DateFormat simpleDate = DateFormat('dd/MM/yy');
  String languageCode="pt-br";

  Usuario usr;

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
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

    double _panelPosition = 0;

    usr = Usuario.fromSharedPref(widget.user);
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.blue),
        body:loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('noticias',widget.user,textTheme,(width*0.5)),
        )
    );
  }
  Widget getMain(double width){
    return SafeArea(
        child:
        Stack(children:[
          Positioned(
            bottom:0,
            child: Container(width:width,color: Colors.white,child: SizedBox(height: 80,),),
          ),
        Column(
          children: <Widget>[
            _header(width),
        Container(
          height: 520,
              margin: EdgeInsets.only(top:100),
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(left: 20.0,right: 20.0,top: 25.0,bottom: 25),
              decoration: BoxDecoration(
                  color:Colors.white,
                  borderRadius: BorderRadius.circular(50)
              ),
              child:
              _body())
          ],
        ),
        ])
    );
  }
  Widget _header(double width){
    return TopContainer(
      height: 100,
      width: width,
      color: HexColor(Constants.blue),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(children: [SizedBox(height: 10,)],),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.redAccent,size: 20.0),
                    tooltip: 'Voltar',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(FadePageRoute(
                        builder: (ctx) => InnerNoticias(),
                      ));
                    },
                  ),
                ),
                Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HexColor(Constants.red),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.thumb_up_alt_outlined, color:Colors.white,size: 20.0),
                    tooltip: 'Abrir Menu',
                    onPressed: () {
                      curtiu();
                    },
                  ),
                ),
              ],
            )
          ]),
    );
  }

  Future<String> curtiu(){
    return PushApi.curtirNoticia(usr.login,usr.senha,widget.ticket.id).then((resp){
      if(resp.ok){
        Message.showMessage("Curtiu!!!");
        return "OK";
      }else{
        Message.showMessage(resp.result);
        return "Falha";
      }
    });
  }
  Widget _body(){
    DateFormat dayOfWeek = DateFormat('EEEE',languageCode);
    DateTime dia = DateTime.parse(widget.ticket.data);
    String data = simpleDate.format(dia)+" | "+dayOfWeek.format(dia);
    return SingleChildScrollView(child:
      Column(
        children:[
          Row(children:[Expanded(child: Text(widget.ticket.titulo,style:TextStyle(fontWeight: FontWeight.bold,fontSize:24,color:HexColor(Constants.blueContainer)),softWrap: true,))]),
          SizedBox(height: 20,),
          Row(children:[Text(data,style:TextStyle(fontWeight: FontWeight.normal,fontSize:14, color:HexColor(Constants.greyContainer)))]),
          SizedBox(height: 20,),
          Row(children:[Expanded(child: Text(widget.ticket.texto,style:TextStyle(fontWeight: FontWeight.normal,fontSize:14,color:HexColor(Constants.blueContainer)),softWrap: true,))]),
        ]
    ));
  }
}
