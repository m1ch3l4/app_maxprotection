// @dart=2.10
import 'dart:convert';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/utils/HttpsClient.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/SharedPref.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
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
          return (snapshot.hasData ? new MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TI & Segurança',
            theme: new ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: new OpenTicketbytextPage(title: 'Abrir Chamado', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class OpenTicketbytextPage extends StatefulWidget {

  OpenTicketbytextPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

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
  Empresa empSel;

  TextEditingController _textFieldController = TextEditingController();
  String valueText="";
  String codeDialog="";

  bool isLoading = false;


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }

  void initState() {
    super.initState();
    _fabHeight = _initFabHeight;
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }

  @override
  Widget build(BuildContext context) {
    Usuario usr = Usuario.fromSharedPref(widget.user);
    usr.empresas.add(_empSearch.defaultValue);
    _empSearch.setOptions(usr.empresas);
    empSel = _empSearch.defaultOpt;

    if(_empSearch.lstOptions.length <3)
      empSel = _empSearch.lstOptions.elementAt(0);

    print("empSel...."+empSel.name);

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "elastic");
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
          body: getMain(width),
        ),
        drawer:  Drawer(
          child: SliderMenu('opentickettext',widget.user,textTheme),
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
          empresasToShow(),
          //_body(),
          makeBody(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [isLoading? CircularProgressIndicator(color: HexColor(Constants.red)):SizedBox(height: 1,)],
          )
        ],
      ),
    );
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
                  Text(
                    'Abrir Chamados',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 40,)
                ],
              ),
            ),

          ]),
    );
  }

  Widget empresasToShow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DropdownButton<Empresa>(
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          style: TextStyle(color: HexColor(Constants.red)),
          underline: Container(
            height: 2,
            color: HexColor(Constants.blue),
          ),
          onChanged: (Empresa newValue) {
            setState(() {
              empSel = newValue;
              _empSearch.setDefaultOpt(newValue);
            });
          },
          items: _empSearch.lstOptions.map((Empresa bean) {
            return  DropdownMenuItem<Empresa>(
                value: bean,
                child: SizedBox(width: 310.0,child: Text(bean.name,overflow: TextOverflow.ellipsis,)));}
          ).toList(),
          value: empSel,
        ),
      ],
    );
  }

  Widget makeBody() {
    //return Column(
    //children: [
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(3),
      height: 185,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HexColor(Constants.grey),
        border: Border.all(
          color: HexColor(Constants.red),
          width: 3,
        ),
      ),
      child: Column(children: [
        Row(children: [SizedBox(height: 5,)],),
        Row(children: [
          SizedBox(
            width: 5
          ),
          Expanded(
            child: TextField(
              maxLines: 4,
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder:OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0),borderSide: BorderSide(width: 1, color: HexColor(Constants.red)))
                  ,hintText: "Descreva aqui o problema..."),
            ),
          ),
          SizedBox(width: 5,),
          SizedBox(height: 10,)
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
                icon: Icon(Icons.cloud_upload),
                onPressed: abrirChamado,
                label: Text('Abrir Chamado'),
                style: ElevatedButton.styleFrom(
                    primary: HexColor(Constants.red)
                )
            ),
            SizedBox(width: 5,)
          ],
        ),
      ]),
      //),
      //],
    );}


  void abrirChamado(){
    if(_textFieldController.value.text!="") {
      _asyncFileUpload(widget.user["id"]);
    }else{
      Message.showMessage("Descreva o problema para abrir o chamado!");
    }
  }

  _asyncFileUpload(String text) async{
    setState(() {
      isLoading=true;
    });

    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));
    var ssl = false;
    var response = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    Map params = {
      'cliente': text,
      'org' : empSel.id,
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


}