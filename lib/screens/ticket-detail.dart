// @dart=2.10
import 'package:app_maxprotection/screens/ticketlist-consultor.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/headerDetailTk.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:async';

import '../model/TechSupportModel.dart';
import '../model/TicketDetail.dart';
import '../model/empresa.dart';
import '../model/moviedesk/Action.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/search_box.dart';
import '../widgets/slider_menu.dart';

class TicketDetail extends StatelessWidget {

  final TechSupportData ticket;
  final Empresa emp;
  final int status;
  SharedPref sharedPref = SharedPref();

  TicketDetail(this.ticket,this.emp,this.status){
  }
  static const routeName = '/ticketdetail';
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
            home: new TicketsPage(title: ticket.id+"-"+ticket.title, user: snapshot.data,ticket: ticket, emp:emp,status:status),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class TicketsPage extends StatefulWidget {
  TicketsPage({Key key, this.title,this.user,this.ticket,this.emp,this.status}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;
  final TechSupportData ticket;
  final Empresa emp;
  final int status;

  @override
  _TicketsPageState createState() => new _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  Ticket detail;
  var loading = false;
  bool isConsultor = false;

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  FCMInitConsultor _fcmInit = new FCMInitConsultor();
  Future<Null> getData(TechSupportData tk) async{
    setState(() {
      loading = true;
    });
    String urlApi = "";
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;


    urlApi = Constants.urlEndpoint+"tech/full/"+tk.id;

    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    if(widget.user["tipo"]=="C")
      isConsultor = true;
    else
      isConsultor = false;

    print("****URL API: ");
    print(urlApi);
    print("**********");

    if(ssl){
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5));
    }else {
      responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5));
    }

    if(responseData.statusCode == 200){
      if(responseData.contentLength>0) {
        String source = Utf8Decoder().convert(responseData.bodyBytes);
        //print(source);
        final data = jsonDecode(source);
        setState(() {
          detail = Ticket.fromJson(data);
          loading = false;
        });
      }else{
        Message.showMessage("Ticket não encontrado na base do MoviDesk!\nVerifique o histórico...");
        setState(() {
          loading = false;
        });
      }
    }else{
      Message.showMessage("Link inacessível!\nTente novamente mais tarde.");
      loading = false;
    }
  }


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
    getData(widget.ticket);
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    double width = MediaQuery.of(context).size.width;
    _fcmInit.configureMessage(context, "tickets");
    double _panelHeightOpen = MediaQuery.of(context).size.height * .25;


    return new Scaffold(
      /**appBar: AppBar(title: Text(widget.title),
        backgroundColor: HexColor(Constants.red),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(FadePageRoute(
                builder: (context) => TicketlistConsultor(widget.emp,widget.status),
              ));
            },
          )
        ],
      ),**/
      appBar: AppBar(backgroundColor: HexColor(Constants.blue), toolbarHeight: 0,),
      backgroundColor: HexColor(Constants.grey),
      key: _scaffoldKey,
      body:
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
      drawer: Drawer(
        child: SliderMenu('tickets',widget.user,textTheme,(width*0.5)),
      )
    );
  }

  goBack(){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => TicketlistConsultor(widget.emp,widget.status),
    ));
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
                headerTkDetail(_scaffoldKey,context, width,detail.title,detail.type,detail.id,goBack),
                Container(
                  width: width*.98,
                  height: MediaQuery.of(context).size.height-100,
                  padding:  EdgeInsets.only(left:5),
                  child: getDetail(),
                )
          ]
      ),
    );
  }
  Widget getDetail(){
    return
      SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child:
          Column(
            children: [
              //getTipo(detail.type),
              Container(
                margin: EdgeInsets.only(top:10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text("Solicitante",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],
                ),
              ),
              getSolicitante(),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Serviço",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],
                  )),
              getServico(),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text("Categoria",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],
                  )),
              getCategoria(),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text("Urgência",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],
                  )),
              getUrgencia(),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text("CC",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],
                  )),
              getCc(),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Expanded(child: Text(detail.title,style: TextStyle(fontSize:16, fontWeight: FontWeight.w500)))],
                  )),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text("Ticket aberto em: "+detail.created,style: TextStyle(fontSize:14))],
                  )),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text("Status: ",style: TextStyle(fontSize:14)),Text(detail.status,style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))],
                  )),
              Container(
                  margin: EdgeInsets.only(top:10.0),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text("Ações",style: TextStyle(fontWeight: FontWeight.w500))],
                  )),
              logs()
            ],
          ));
  }
  Widget getSolicitante(){
    return Container(
      padding: EdgeInsets.all((10.0)),
      decoration: BoxDecoration(
          color:Colors.white,
          border: Border(
            left: BorderSide(color:HexColor(Constants.red),width: 4),
            right:BorderSide(color:HexColor(Constants.red),width: 4),
          )
      ),
          margin: EdgeInsets.all(10.0),
          child:Column(
            children: [
              Row(children: [Text(detail.client.businessName,style: TextStyle(fontSize: 17),)]),
              Row(children: [Text(detail.client.email!=null?detail.client.email:"-")]),
              Row(children: [Text(detail.client.phone)]),
              Row(children: [Text((detail.client.organization!=null?detail.client.organization.businessName:"-"))]),
            ],
          ),
    );
  }
  Widget getServico(){
    return Container(
      padding: EdgeInsets.all((10.0)),
        decoration: BoxDecoration(
            color:Colors.white,
            border: Border(
              left: BorderSide(color:HexColor(Constants.red),width: 4),
              right:BorderSide(color:HexColor(Constants.red),width: 4),
            )
        ),
          margin: EdgeInsets.all(10.0),
          child:Column(
            children: [
              Row(children: [Expanded(child: Text((detail.serviceFirstLevel!=null?detail.serviceFirstLevel:'-'),style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)))]),
              Row(children: [Text((detail.serviceSecondLevel!=null?detail.serviceSecondLevel:'-'))])
            ],
          ),
    );
  }
  Widget getCategoria(){
    return
      Container(
        padding: EdgeInsets.all((10.0)),
          decoration: BoxDecoration(
              color:Colors.white,
              border: Border(
                left: BorderSide(color:HexColor(Constants.red),width: 4),
                right:BorderSide(color:HexColor(Constants.red),width: 4),
              )
          ),
          margin: EdgeInsets.all(10.0),
          child:Column(
            children: [
              Row(children: [Text((detail.category!=null?detail.category:'-'))])
            ],
          ),
    );
  }

  Widget getCc(){
    return Container(
        padding: EdgeInsets.all((10.0)),
            margin: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                color:Colors.white,
              border: Border(
                left: BorderSide(color:HexColor(Constants.red),width: 4),
                right:BorderSide(color:HexColor(Constants.red),width: 4),
              )
            ),
            child:Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: Text((detail.cc!=null?detail.cc:"-")),
                    )])]
            )
        );
  }

  Widget getUrgencia() {
    Color cl;
    if(detail.urgency=="Baixa")
      cl = Colors.green;
    if(detail.urgency=="Média")
      cl = Colors.yellow;
    if(detail.urgency=="Alta")
      cl = Colors.red;
    return  Container(
        padding: EdgeInsets.all((10.0)),
        decoration: BoxDecoration(
            color:Colors.white,
            border: Border(
              left: BorderSide(color:HexColor(Constants.red),width: 4),
              right:BorderSide(color:HexColor(Constants.red),width: 4),
            )
        ),
            margin: EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(children: [
                  SizedBox(
                    height: 20,
                    width: 25,
                    child: Container(
                      color:cl,
                      margin: EdgeInsets.only(right: 5),
                    ),
                  ),

                  //Icon(Icons.crop_square_outlined,color: Colors.green),
                  Row(children: [Text(detail.urgency)])],)
              ],
            )
    );
  }

  Widget logs(){
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        for(var i=detail.actions.length-1;i>0;i--)
          cardLog(detail.actions[i])
      ],
    );
  }

  Widget cardLog(ActionLog act){
    return Card(
        color: HexColor(Constants.grey),
        child:
        Container(
          margin: EdgeInsets.all(10.0),
          child:
          Column(
            children: [
              Row(
                children: [Text(act.createdDate),Spacer(),Text("Mensagem",style: TextStyle(fontStyle: FontStyle.italic))],
              ),
              Divider(color: HexColor(Constants.red),),
              Row(
                children: [Text("De:"),Text(
                    (act.createdBy!=null?act.createdBy.businessName:"-")
                )],
              ),
              Row(
                children: [Text("Assunto: "),Text(act.justification)],
              ),
              //Spacer(),
              Row(
                children: [
                  Expanded(
                      child:
                      Text(act.description)
                  )
                ],
              ),
            ],
          ),
        ));
  }


}