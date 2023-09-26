// @dart=2.10
import 'package:app_maxprotection/screens/home_page.dart';
import 'package:app_maxprotection/screens/ticket-detail.dart';
import 'package:app_maxprotection/screens/ticketsview-consultor.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/utils/TicketSearch.dart';
import 'package:app_maxprotection/widgets/header.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:async';
import '../model/TechSupportModel.dart';
import '../model/empresa.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../utils/Message.dart';
import '../widgets/TopHomeWidget.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/search_box.dart';
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
  List<TechSupportData> originalListModel = [];
  var loading = false;
  bool isConsultor=false;

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  double width = 150.0;

  String perfil="Analista";
  String stats = "Abertos";

  Empresa emp=null;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  FCMInitConsultor _fcmInit = new FCMInitConsultor();


  List<String> termos = [];
  List<String> excludeTerms = ["ao","da","de","e","em","está","no","não","o","a","os","para","que","é","--"," ","os","as","novo","Fwd:","FW:","envio","chamado","adicionar","a.","-"];
  Map<String,String> filterResults ={}; //"links":"1,3,6" = termo e index dos itens na lista de resultados


  filtraPesquisa(String query){
    if(query!="!"){
    String index = filterResults[query];
    print("filta Pesquisa...."+query);
    List<String> ids = index.split(",");
    if(ids!=null) {
      listModel = [];
      ids.forEach((element) {
        originalListModel.forEach((el) {
          if (el.id == element) {
            listModel.add(el);
          }
        });
      });
      setState(() {});
    }}else{
      listModel = originalListModel;
      setState(() {});
    }
  }

  Future<Null> getData(Empresa empresa) async{
    setState(() {
      loading = true;
    });
    String urlApi = "";
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    emp = empresa;

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

    String basicAuth = "Bearer "+widget.user["token"];

    Map<String, String> h = {
      "Authorization": basicAuth,
    };
    if(ssl){
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5), onTimeout: _onTimeout);
    }else {
      responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 5), onTimeout: _onTimeout);
    }

    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      print("source..."+source);
      final data = jsonDecode(source);
      termos = [];
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
          List<String> palavras = ticket.title.split(" ");
          palavras.forEach((element) {
            if(!termos.contains(element) && !excludeTerms.contains(element.toLowerCase())) {
              termos.add(element);
              var val = filterResults[element];
              if(val!=null)
                val+=","+ticket.id;
              else
                val = ticket.id;
              filterResults[element]=val;
            }
          });
        }
        loading = false;
        originalListModel = listModel;
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


  FutureOr<http.Response> _onTimeout(){
    setState(() {
      loading=false;
      print("não foi possível conectar em 8sec");
    });
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    /**Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => HomePage(),
    ));**/
    return true;
  }

  void initState() {
    super.initState();
    //BackButtonInterceptor.add(myInterceptor);
    getData(widget.empresa);
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user);
  }

  @override
  Widget build(BuildContext context) {
    if(widget.user["tipo"]=="C")
      perfil = "Consultor";
    if(widget.user["tipo"]=="T")
      perfil = "Analista";
    if(widget.user["tipo"]=="D")
      perfil = "Diretor";

    switch(widget.status) {
      case 0:
        stats = "Abertos";
        break;
      case 1:
        stats = "Novos";
        break;
      case 2:
        stats = "em Atendimento";
        break;
    }


    double width = MediaQuery.of(context).size.width;
    _fcmInit.configureMessage(context, "tickets");
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    _fcmInit.configureMessage(context, "tickets");
    width = MediaQuery.of(context).size.width;
    double _panelHeightOpen = MediaQuery.of(context).size.height * .25;

    return Scaffold(
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
        drawer:  Drawer(
          width: width*0.6,
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('tickets',widget.user,textTheme,(width*0.5)),
        )
    );

    /**return new Scaffold(
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
        child: SliderMenu('tickets',widget.user,textTheme,(width*0.5)),
      ),
      body:  Container(
        padding: EdgeInsets.fromLTRB(10,10,10,0),
        width: double.maxFinite,
        child: loading ? Center (child: CircularProgressIndicator()) : getMain(),
      ),
    );**/
  }

  goBack(){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => (isConsultor?TicketsviewConsultor(widget.status):HomePage()),
    ));
  }
  Widget getMain(double width){
    /**return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        headerTk(widget.key, widget.user, "Consultor", listModel.length),
        listView(),
      ],
    );**/
    return SafeArea(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: [
                headerTk(_scaffoldKey, widget.user,context, perfil, listModel.length,width,stats,goBack),
                Positioned(child:
                SearchBox(
                    cardColor: Colors.white,
                    title: "Pesquisar",
                    usr: widget.user,
                  width: width*0.9,
                  searchDelegate: TicketSeach(termos,filtraPesquisa),
                ),
                  top:188,
                  left: width*0.05,
                ),
               Container(
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
                        action: TicketlistConsultor(emp,1), // <-- document instance
                        ),
                      Spacer(),
                      TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.4,title: "Tickets em atendimento",ctx: context,r:false,
                          action: TicketlistConsultor(emp,2),
                          icon: Image.asset("images/tkatendimento.png",color: Colors.white,fit:BoxFit.contain,width: 24,)),
                      //SizedBox(width: width*0.05,),
                    ],
                  )
                ),
                Container(
                  margin:EdgeInsets.only(left: width*0.04),
                  //alignment: Alignment.center,
                  width: width*.9,
                  height: MediaQuery.of(context).size.height-100,
                  padding:  EdgeInsets.only(left:5,top:290),
                  child: (listModel.length>0?listView():Container(height: 20,)),
                )
              ],
            )
          ]
      ),
    );
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
            builder: (context) => TicketDetail(tech,widget.empresa,widget.status), // <-- document instance
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
                    Text(tech.tecnico,style: TextStyle(fontWeight: FontWeight.w500),)],
                ),
                SizedBox(height: 3,)
              ],
        )
    ))

        ));
  }


}