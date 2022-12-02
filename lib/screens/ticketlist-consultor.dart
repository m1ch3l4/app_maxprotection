// @dart=2.10
import 'package:app_maxprotection/screens/home_page.dart';
import 'package:app_maxprotection/screens/ticket-detail.dart';
import 'package:app_maxprotection/screens/ticketsview-consultor.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';
import '../model/TechSupportModel.dart';
import '../model/empresa.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';

class TicketlistConsultor extends StatelessWidget {

  final Empresa empresa;
  /**
   * 0 - todos
   * 1 - Novo
   * 2 - Atendimento
   * 3 - Aguardando
   */
  final int status;
  SharedPref sharedPref = SharedPref();

  TicketlistConsultor(this.empresa,this.status){
  }
  static const routeName = '/ticketslist';
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
            home: new TicketsPage(title: (empresa!=null?empresa.name:"Tickets por status"), user: snapshot.data,empresa: empresa,status:status),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class TicketsPage extends StatefulWidget {
  TicketsPage({Key key, this.title,this.user,this.empresa,this.status}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;
  final Empresa empresa;
  final int status;


  @override
  _TicketsPageState createState() => new _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<TechSupportData> listModel = [];
  var loading = false;
  bool isConsultor=false;


  FCMInitConsultor _fcmInit = new FCMInitConsultor();
  Future<Null> getData(Empresa empresa) async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

    if(widget.user["tipo"]=="C"){
      isConsultor = true;
      if(empresa!=null && widget.status<1) {
        urlApi = Constants.urlEndpoint + "tech/list/emp/" + empresa.id;
      }else{
        switch(widget.status) {
          case 0:
            urlApi = Constants.urlEndpoint + "tech/consultor/"+widget.user["id"]+"/all";
            break;
          case 1:
            //urlApi = Constants.urlEndpoint + "tech/consultor/"+widget.user["id"]+"/status/Novo";
            urlApi = Constants.urlEndpoint + "tech/list/emp/"+empresa.id+"/status/Novo";
            break;
          case 2:
            urlApi = Constants.urlEndpoint + "tech/list/emp/"+empresa.id+"/status/Em Atendimento";
            break;
          case 3:
            urlApi = Constants.urlEndpoint + "tech/list/emp/"+empresa.id+"/status/Aguardando";
            break;
        }
      }
    }else{
      isConsultor=false;
      print("widget.status:");
      print(widget.status);
      switch(widget.status){
        case 0:
          if(widget.user["tipo"]=="D") {
            urlApi = Constants.urlEndpoint + "tech/list/emp/" +
                widget.user['company_id'].toString();
          }else{
            urlApi = Constants.urlEndpoint + "tech/list/tecnico/" +
                widget.user['id'].toString();
          }
          break;
        case 1:
          if(widget.user["tipo"]=="D") {
            urlApi = Constants.urlEndpoint + "tech/list/emp/" +
                widget.user['company_id'].toString()+"/status/Novo";
          }else{
            urlApi = Constants.urlEndpoint + "tech/list/tecnico/" +
                widget.user['id'].toString()+"/status/Novo";
          }
          break;
        case 2:
          if(widget.user["tipo"]=="D") {
            urlApi = Constants.urlEndpoint + "tech/list/emp/" +
                widget.user['company_id'].toString()+"/status/Em Atendimento";
          }else{
            urlApi = Constants.urlEndpoint + "tech/list/tecnico/" +
                widget.user['id'].toString()+"/status/Em Atendimento";
          }
          break;
      }
    }

    print("****URL API: ");
    print(urlApi);
    print("**********");

    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));    if(responseData.statusCode == 200){
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
          ticket.setUser(c["name"]);
          ticket.setTecnico((o!=null?o["name"]:""));
          if(!listModel.contains(ticket))
            listModel.add(ticket);
        }
        loading = false;
      });
    }else{
      loading = false;
    }
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    getData(widget.empresa);
  }

  @override
  Widget build(BuildContext context) {
    _fcmInit.configureMessage(context, "tickets");
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    _fcmInit.configureMessage(context, "tickets");
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
                builder: (context) => (isConsultor?TicketsviewConsultor(widget.status):HomePage()),
                //builder: (context) => HomePage(),
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
        child: loading ? Center (child: CircularProgressIndicator()) : getMain(),
      ),
    );
  }
  Widget getMain(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        listView(),
      ],
    );
  }

  Widget listView(){
    return Expanded(child: ListView(
      children: <Widget>[
        for (int i=0; i<listModel.length; i++)
            getAlert(listModel[i])
      ],
    ));
  }

  Widget getAlert(TechSupportData tech){
    Color cl = Colors.green;
    var urg = tech.urgencia;

    if(tech.urgencia=="Baixa")
      cl = Colors.green;
    if(tech.urgencia=="Média")
      cl = Colors.yellow;
    if(tech.urgencia=="Alta")
      cl = Colors.red;

    return GestureDetector(
      onTap: (){
          Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetail(tech,widget.empresa,widget.status), // <-- document instance
          ));},
        child: Card(
        child:
          Container(
              margin: EdgeInsets.all(10.0),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: cl,width: 5))),
        padding: EdgeInsets.only(left:5.0),
        child:
        Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text("#"+tech.id, style: TextStyle(fontWeight: FontWeight.w500,color: HexColor(Constants.red)))],
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                  children: [Expanded(child: Text(tech.title,style: TextStyle(fontSize: 16.0)))],
                ),
                SizedBox(height: 5,),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text(tech.user,style: TextStyle(fontWeight: FontWeight.w500))],
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text(tech.empresa)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(tech.status,style: TextStyle(fontWeight: FontWeight.w500))],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(tech.tecnico)],
                ),
              ],

        )
        )
    ));
  }


}