// @dart=2.10
import 'package:app_maxprotection/screens/ticketlist-consultor.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';

import '../model/TechSupportModel.dart';
import '../model/TicketDetail.dart';
import '../model/empresa.dart';
import '../model/moviedesk/Action.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
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

  @override
  Widget build(BuildContext context) {
    _fcmInit.configureMessage(context, "tickets");
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return new Scaffold(
      appBar: AppBar(title: Text(widget.title),
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
      ),
      drawer: Drawer(
        child: SliderMenu('tickets',widget.user,textTheme),
      ),
      body:  Container(
        padding: EdgeInsets.fromLTRB(10,10,10,0),
        width: double.maxFinite,
        child: loading ? Center (child: CircularProgressIndicator()) :
        getMain(),
      ),
    );
  }
  Widget getMain(){
    return
      SingleChildScrollView(
        scrollDirection: Axis.vertical,
          child:
    Column(
      children: [
        getTipo(detail.type),
        Container(
          margin: EdgeInsets.only(top:10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Text("Solicitante",style: TextStyle(fontWeight: FontWeight.w500))],
          ),
        ),
        getSolicitante(),
        Container(
            margin: EdgeInsets.only(top:10.0),
            child:Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Serviço",style: TextStyle(fontWeight: FontWeight.w500))],
            )),
        getServico(),
        Container(
            margin: EdgeInsets.only(top:10.0),
            child:Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Categoria",style: TextStyle(fontWeight: FontWeight.w500))],
            )),
        getCategoria(),
        Container(
            margin: EdgeInsets.only(top:10.0),
            child:
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Urgência",style: TextStyle(fontWeight: FontWeight.w500))],
            )),
        getUrgencia(),
        Container(
            margin: EdgeInsets.only(top:10.0),
            child:
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("CC",style: TextStyle(fontWeight: FontWeight.w500))],
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
    return Card(
      color: HexColor(Constants.grey),
          child: Container(
        margin: EdgeInsets.all(10.0),
        child:Column(
            children: [
              Row(children: [Text(detail.client.businessName,style: TextStyle(fontSize: 17),)]),
              Row(children: [Text(detail.client.email!=null?detail.client.email:"-")]),
              Row(children: [Text(detail.client.phone)]),
              Row(children: [Text((detail.client.organization!=null?detail.client.organization.businessName:"-"))]),
            ],
        )),
    );
  }
  Widget getServico(){
    return Card(
        color: HexColor(Constants.grey),
      child: Container(
        margin: EdgeInsets.all(10.0),
        child:Column(
        children: [
          Row(children: [Expanded(child: Text((detail.serviceFirstLevel!=null?detail.serviceFirstLevel:'-'),style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)))]),
          Row(children: [Text((detail.serviceSecondLevel!=null?detail.serviceSecondLevel:'-'))])
        ],
      )),
    );
  }
  Widget getCategoria(){
    return Card(
        color: HexColor(Constants.grey),
      child: Container(
        margin: EdgeInsets.all(10.0),
        child:Column(
        children: [
          Row(children: [Text((detail.category!=null?detail.category:'-'))])
        ],
      )),
    );
  }

  Widget getCc(){
    return Card(
        color: HexColor(Constants.grey),
      child: Container(
        margin: EdgeInsets.all(10.0),
    child:Column(
        children: [
          Row(children: [
            Expanded(
              child: Text((detail.cc!=null?detail.cc:"-")),
            )])]
      )
    ));
  }

  Widget getUrgencia() {
    Color cl;
    if(detail.urgency=="Baixa")
      cl = Colors.green;
    if(detail.urgency=="Média")
      cl = Colors.yellow;
    if(detail.urgency=="Alta")
      cl = Colors.red;
    return Card(
      color: HexColor(Constants.grey),
      child: Container(
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
      )
    );
  }

  Widget getTipo(String tipo){
    print("tipo $tipo");
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        (tipo=="1"?Icon(Icons.done, color: HexColor(Constants.red)): SizedBox(width: 1,)),
        Text("PÚBLICO",
            style: TextStyle(
              decoration: (tipo=="1"?TextDecoration.underline:TextDecoration.none),
              fontWeight: FontWeight.w400,
              fontSize: 18.0
            )),
        SizedBox(width: 5,),
        (tipo=="2"?Icon(Icons.done, color: HexColor(Constants.red)):SizedBox(width: 1,)),
        Text("INTERNO",
            style: TextStyle(
              decoration: (tipo=="2"?TextDecoration.underline:TextDecoration.none),
              fontWeight: FontWeight.w400,
              fontSize: 18.0
            ))
      ],
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