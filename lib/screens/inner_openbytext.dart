
import 'dart:convert';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/utils/HttpsClient.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/SharedPref.dart';
import '../widgets/RadialButton.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
import '../widgets/searchempresa_wdt.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';

void main() => runApp(InnerOpenTicketbytext());

class InnerOpenTicketbytext extends StatelessWidget {

  SharedPref sharedPref = SharedPref();

  static const routeName = '/elastic';
  @override
  Widget build(BuildContext context) {
    return Material(
      child: FutureBuilder(
        future: sharedPref.read("usuario"),
        builder: (context,snapshot){
          return (snapshot.hasData ? new OpenTicketbytextPage(title: 'Abrir Chamado', user: snapshot.data as Map<String, dynamic>): CircularProgressIndicator());
        },
      ),
    );
  }
}

class OpenTicketbytextPage extends StatefulWidget {

  OpenTicketbytextPage({this.title,this.user}) : super();

  final String? title;
  final Map<String, dynamic>? user;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<OpenTicketbytextPage> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  EmpresasSearch _empSearch = new EmpresasSearch();
  Empresa? empSel;

  TextEditingController _textFieldController = TextEditingController();
  String valueText="";
  String codeDialog="";

  bool isLoading = false;
  bool isTecnico = false;
  String idTicket = "-1";

  searchEmpresa? searchEmpresaWdt;


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
    _fabHeight = _initFabHeight;
    empSel=null;
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }

  void setSelectedEmpresa(Empresa e){
    this.empSel = e;
  }

  @override
  Widget build(BuildContext context) {
    Usuario usr = Usuario.fromSharedPref(widget.user!);
    usr.empresas.add(_empSearch.defaultValue);
    _empSearch.setOptions(usr.empresas);
    empSel = _empSearch.defaultOpt;

    /**if(_empSearch.lstOptions.length <3)
      empSel = _empSearch.lstOptions.elementAt(0);**/
    //print("empSel...."+empSel.name);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "elastic");

    searchEmpresaWdt = searchEmpresa(context: context,onchangeF: null,width: width*0.95,notifyParent: setSelectedEmpresa,);

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
        body: SlidingUpPanel(
          color: HexColor(Constants.grey),
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0)),
          onPanelSlide: (double pos) => updateState(pos),
          panelBuilder: (sc) => _panel(sc,width,context),
          body: getMain(width),
        ),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('tickets',widget.user!,textTheme,(width*0.5)),
        )
    );
  }

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user!);
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Stack(
              children: [
                headerAlertas(_scaffoldKey, widget.user!, context, width,200, "Abrir chamados por Texto"),
                Positioned(
                  child: Container(width:width,alignment:Alignment.center,child: searchEmpresaWdt),
                  top:175,
                ),
                _body(width)
              ])],
      ),
    );
  }

  Widget _body(double w){
    return Container(
      padding: EdgeInsets.only(top:250),
      margin: EdgeInsets.only(left:w*0.05,right: w*0.05),
      width: w*0.9,
      height:  MediaQuery.of(context).size.height-180,
      child:
      Column(
        children: [
          Spacer(),
          Row(
              children: [
                Flexible(
                  child: TextField(
                    maxLines: 6,
                    onChanged: (value) {
                      setState(() {
                        valueText = value;
                      });
                    },
                    style: TextStyle(color: HexColor(Constants.blueContainer)),
                    controller: _textFieldController,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(width: 4, color: HexColor(Constants.blueContainer))
                        ),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0),borderSide: BorderSide(width: 4, color: HexColor(Constants.blueContainer)))
                        ,hintText: "Descreva aqui o problema..."),
                  ),
                ),
              ]),
        Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    ),
                    primary: HexColor(Constants.red)
                ),
                icon: Icon(Icons.cloud_upload),
                onPressed: abrirChamado,
                label: Text('Abrir Chamado'),
            ),]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [isLoading? CircularProgressIndicator(color: HexColor(Constants.red)):SizedBox(height: 1,)],
          ),
        ],
      )

    );
  }

  void abrirChamado(){
    if(_textFieldController.value.text!="") {
      if(empSel!=null && empSel!.id!="0") {
        _asyncFileUpload(widget.user!["id"]);
      }else{
        Message.showMessage("Selecione a empresa para abrir o chamado!");
      }
    }else{
      Message.showMessage("Descreva o problema para abrir o chamado!");
    }
  }

  _asyncFileUpload(String text) async{
    setState(() {
      isLoading=true;
    });

    String basicAuth = "Bearer "+widget.user!["token"];
    var ssl = false;
    var response = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    Map params = {
      'cliente': text,
      'org' : empSel!.id,
      'descricao':valueText
    };

    //encode Map para JSON(string)
    var body = json.encode(params);

    var url =Constants.urlEndpoint+'tech/open';

    if(ssl) {
      var client = HttpsClient().httpsclient;
      response = await client.post(Uri.parse(url),
          headers: {
            "Content-Type":"application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Authorization": basicAuth
          },
          body: body).timeout(Duration(seconds: 20));
    }else {
      response = await http.post(Uri.parse(url),
          headers: {
            "Content-Type":"application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Authorization": basicAuth
          },
          body: body).timeout(Duration(seconds: 20));
    }
    print("Response..InnerOpenTicket..Code "+response.statusCode.toString());
    print("Response..InnerOpenTicket.."+response.body);

    if(response.statusCode == 200){
      if(response.body!=null){
        Map<String,dynamic> mapResponse = json.decode(response.body);
        Message.showMessage("Ticket Aberto com o número: "+mapResponse['id'].toString());
        Future.delayed(const Duration(seconds: 1), () {
          goBack();
        });
      }else{
        Message.showMessage("Não foi possível abrir o ticket.\nEntre em contato com o nosso suporte.");
      }
      setState(() {
        isLoading=false;
      });
    }else{
      Message.showMessage("Não foi possível abrir o seu chamado.\nEntre em contato com o suporte.");
      setState(() {
        isLoading=false;
      });
    }
  }

  goBack(){
    Navigator.of(context).maybePop(context).then((value) {
      if (value == false) {
        Navigator.pushReplacement(
            context,
            FadePageRoute(
              builder: (ctx) => HomePage(),
            ));
      }
    });
  }


}