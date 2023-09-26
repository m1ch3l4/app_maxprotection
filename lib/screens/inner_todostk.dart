//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/model/MessageModel.dart';
import 'package:app_maxprotection/screens/ticket-detail.dart';
import 'package:app_maxprotection/screens/ticketlist-consultor.dart';
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
import '../model/TechSupportModel.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../widgets/TopHomeWidget.dart';
import '../widgets/active_project_card.dart';
import '../widgets/bottom_container.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


class InnerTodosTk extends StatelessWidget {

  static const routeName = '/tickets';
  SharedPref sharedPref = SharedPref();

  InnerTodosTk();

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
            home: new TodosTkPage(title: '', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class TodosTkPage extends StatefulWidget {
  TodosTkPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _TodosTkPageState createState() => new _TodosTkPageState();
}

class _TodosTkPageState extends State<TodosTkPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  DateFormat simpleDate = DateFormat('dd/MM/yy');
  String languageCode="pt_BR";
  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  List<TechSupportData> listModel = [];
  var loading = false;
  double width=0.0;
  double altura = 0.0;


  /** bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => HomePage(),
    ));
    return true;
  }**/

  void initState() {
    super.initState();
    //BackButtonInterceptor.add(myInterceptor);
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
    width = MediaQuery.of(context).size.width;
    altura = MediaQuery.of(context).size.height;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "tickets");
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
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
          child: SliderMenu('tickets',widget.user,textTheme,(width*0.5)),
        )
    );
  }

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user);
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
                  simpleHeader(_scaffoldKey,context,width,(listModel.length>4?200:150)),
                  if(listModel.length<5)
                  menuTickets(),
                  Container(padding:EdgeInsets.only(top:(listModel.length>4?100:240),left:10,right: 10),height: tam, child:_body())
                ])
          ],
        )
    );
  }

  Widget menuTickets(){
    return Container(
        alignment: Alignment.center,
        margin:EdgeInsets.only(left: width*0.04),
        padding:  EdgeInsets.only(top:250),
        width: width*.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: width*0.03,),
            TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.42,icon:ImageIcon(
                AssetImage("images/tkaberto.png"),
                color: Colors.white, size:22
            ),
              title: "Tickets abertos",ctx: context,r:false,
              action: TicketlistConsultor(null,1), // <-- document instance
            ),
            Spacer(),
            TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.4,title: "Tickets em atendimento",ctx: context,r:false,
                action: TicketlistConsultor(null,1),
                icon: Image.asset("images/tkatendimento.png",color: Colors.white,fit:BoxFit.contain,width: 24,)),
            //SizedBox(width: width*0.05,),
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

    if(widget.user["tipo"]=="D") {
      urlApi = Constants.urlEndpoint + "tech/list/emp/" +
          widget.user['company_id'].toString();
    }else{
      urlApi = Constants.urlEndpoint + "tech/list/tecnico/" +
          widget.user['id'].toString();
    }

    print("****URL API: ");
    print(urlApi);
    print("**********");

    String basicAuth = "Bearer "+widget.user["token"];

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
      print("source..."+source);
      final data = jsonDecode(source);
      setState(() {
        for(Map i in data){
          var c = i["cliente"];
          var e = i["empresa"];
          var o = i["owner"];
          var ticket = TechSupportData.fromJson(i);
          ticket.setEmpresa(e!=null?e["name"]:"");
          ticket.setUser(c!=null?c["name"]:"");
          ticket.setTecnico((o!=null?o["name"]:""));
          if(!listModel.contains(ticket))
            listModel.add(ticket);
        }
        print("Total de Tickets...."+listModel.length.toString());
        loading = false;
      });
    }else{
      if(responseData.statusCode == 401) {
        Message.showMessage("As suas credenciais não são mais válidas...");
        setState(() {
          listModel.clear();
          loading=false;
        });
      }
      loading = false;
    }
  }


  Widget _body(){
    return listView();
  }

  Widget listView(){
    return  //SingleChildScrollView(
      //child:
      ListView(
        shrinkWrap: true,
        //physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          for (int i=0; i<listModel.length; i++)
            getAlert(listModel[i],i)
        ],
      );
  }

  Widget getAlert(TechSupportData tech, int i){

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

    return GestureDetector(
        onTap: (){
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetail(tech,widget.user["empresa"],0), // <-- document instance
              ));},
        child: Card(
            child:
            ClipPath(
                clipper: ShapeBorderClipper(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3))),
                child:
                Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: cl, width: 5),
                      ),
                    ),
                    //margin: EdgeInsets.all(12.0),
                    padding: EdgeInsets.only(right:5.0,top:5.0,bottom:5.0,left:10),
                    //height: 300,
                    child:
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [Text("#"+tech.id, style: TextStyle(fontWeight: FontWeight.w500,color: cl))],
                        ),
                        SizedBox(height: 1.5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [Text(tech.user,style: TextStyle(fontWeight: FontWeight.w500, color:clTexto))],
                        ),
                        SizedBox(height: 1.5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [Expanded(child: Text(tech.title,style: TextStyle(fontSize: 16.0, color: clTexto)))],
                        ),
                        SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [Text(tech.status,style: TextStyle(fontWeight: FontWeight.w500, color:clTexto))],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                    color: HexColor(Constants.grey),
                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child: Expanded(child:Text(tech.empresa,style:TextStyle(color:HexColor(Constants.darkGrey),fontWeight: FontWeight.bold)))
                            ),
                            Text(tech.tecnico,style:TextStyle(fontWeight: FontWeight.w500))],
                        ),
                        SizedBox(height: 3,)
                      ],
                    )
                ))

        ));
  }


}