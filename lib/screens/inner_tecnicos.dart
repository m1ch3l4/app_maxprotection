// @dart=2.10
import 'dart:io';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/AlertModel.dart';
import '../model/usuario.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../utils/Message.dart';
import '../utils/SharedPref.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


void main() => runApp(new InnerTecnicos());

class InnerTecnicos extends StatelessWidget {

  static const routeName = '/tecnicos';
  SharedPref sharedPref = SharedPref();

  @override
  Widget build(BuildContext context){
    return Material(child: FutureBuilder
      (future: sharedPref.read("usuario"),
  builder: (context,snapshot){
  return (snapshot.hasData ? new MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'TI & Segurança',
  theme: new ThemeData(
  primarySwatch: Colors.blue,
  ),
  home: new TecnicosPage(title: 'Técnicos', user: snapshot.data),
  ) : CircularProgressIndicator());
  },),
  );
}
}

class TecnicosPage extends StatefulWidget {
  TecnicosPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _TecnicosPageState createState() => new _TecnicosPageState();
}

class _TecnicosPageState extends State<TecnicosPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  List<Usuario> listModel = [];
  List<bool> checked = [];
  var loading = false;

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

    String basicAuth = "Bearer "+widget.user["token"];
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    Map<String, String> h = {
      "Authorization": basicAuth,
    };
    //widget.user.forEach((k,v) => print("chave $k valor $v"));

    urlApi = Constants.urlEndpoint+"diretor/tecnicos/"+widget.user['id'].toString();

    print("****URL API: ");
    print(urlApi);
    print("**********");

    if(ssl){
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h);
    }else {
      responseData = await http.get(Uri.parse(urlApi), headers: h);
    }

    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      print("source...."+source);
      if(source!=null && source!="") {
        final data = jsonDecode(source);
        print("data " + data.toString());
        setState(() {
          for (Map i in data) {
            var alert = Usuario.fromJson(i);
            listModel.add(alert);
            checked.add(alert.role.nome == "tec-nivel1" ? false : true);
          }
          loading = false;
        });
      }else{
        setState(() {
          loading=false;
        });
      }
    }else{
      if(responseData.statusCode == 401) {
        Message.showMessage("As suas credenciais não são mais válidas...");
        setState(() {
          loading=false;
        });
      }
    }
  }


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => HomePage(),
    ));
    return true;
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  void initState() {
    getData();
    super.initState();
    //BackButtonInterceptor.add(myInterceptor);
    _fabHeight = _initFabHeight;
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;

    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset : false,
        body: getMain(width),
        drawer:  Drawer(
          child: SliderMenu('tecnicos',widget.user,textTheme,(width*0.6)),
        )
    );
  }

  Widget getMain(double width){
    double height = MediaQuery.of(context).size.height-215;
    /**return SafeArea(
      child: Column(
        children: <Widget>[
          _header(width),
          //rangeDate(),
          Divider(
            height: 5,
            thickness: 1,
            indent: 5,
            endIndent: 5,
            color: HexColor(Constants.grey),
          ),
          _body(),
        ],
      ),
    );**/
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          headerAlertas(_scaffoldKey, widget.user, context, width, 185, 'Técnicos da '+(widget.user["company_name"]!=null?widget.user["company_name"]:"-")),
          Spacer(),
          Container(
              width: width*0.9,
              height: height,
              child: _body(),),
          Spacer()
        ],
      ),
    );
  }

  Widget _body(){
    return Expanded(
        child: listView());
  }

 /** Widget _header(double width){
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
                  //TODO: ver aqui.
                  Expanded(child: Text(
                    'Técnicos da '+(widget.user["company_name"]!=null?widget.user["company_name"]:"-"),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  )),
                ],
              ),
            ),

          ]),
    );
  }**/

  Widget listView(){
    return ListView(
      children: <Widget>[
        for (int i = 0; i < listModel.length; i++)
          getUsuario(i,listModel[i].id, listModel[i].name, listModel[i].login)
          //getAlert(listModel[i].name, listModel[i].login)
      ],
    );
  }

  Widget getUsuario(int i, String id, String nome, String login){
  //bool checked = contratado;
    return Card(
        child: Column(
          children: [
            CheckboxListTile(
              isThreeLine: true,
              title: Text(nome),
              subtitle: Text(login+"\n\nAcesso à serviços e contrato?"),
              autofocus: false,
              activeColor: HexColor(Constants.red),
              checkColor: Colors.white,
              value: checked[i],
              onChanged: (bool value) {
                setState(() {
                  if(value){
                    permitirAcessoContrato(id,value);
                    checked[i] = value;
                  }
                });
              },
            ),
            SizedBox(height: 20,)
          ],
        )
    );
  }


  void permitirAcessoContrato(String idtecnico,bool value) {
    acessoServicosContrato(idtecnico, value);
  }

  Future<String> acessoServicosContrato(String idTecnico, bool permitir) async{
    var url =Constants.urlEndpoint+'diretor/acesso';

    var ssl = false;
    var response = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    String basicAuth = "Bearer "+widget.user["token"];

    Map<String, String> h = {
      "Authorization": basicAuth,
      "Access-Control-Allow-Origin": "*", // Required for CORS support to work
      "Access-Control-Allow-Credentials": "true", // Required for cookies, authorization headers with HTTPS
      "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      "Access-Control-Allow-Methods": "POST, OPTIONS"
    };

    print("url $url");

    Map params = {
      'userid':idTecnico,
      'acesso': permitir
    };

    //encode Map para JSON(string)
    var body = json.encode(params);

    if(ssl){
      var client = HttpsClient().httpsclient;
      response = await client.post(Uri.parse(url),
          headers: h,
          body: body).timeout(Duration(seconds: 5));
    }else{
      response = await http.post(Uri.parse(url),
          headers: h,
          body: body).timeout(Duration(seconds: 5));
    }

    if(response.statusCode==200){
      Message.showMessage(response.body);
    }
    return response.body;
  }


  Widget getAlert(String title, String date){
    return Card(
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(0),
              minLeadingWidth: 10.0,
              title: Column(mainAxisAlignment:MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,children:[Text(title, style: TextStyle(fontWeight: FontWeight.w500))]),
              leading: Container(
                width: 10,
                decoration: BoxDecoration(
                    color: HexColor(Constants.red),
                    borderRadius:BorderRadius.only(
                        topLeft: Radius.circular(3.0),
                        bottomLeft: Radius.circular(3.0))
                ),
              ),
              trailing: Text(date, style: TextStyle(fontWeight: FontWeight.w400,color: HexColor(Constants.red))),
            )
          ],
        )
    );
  }

}