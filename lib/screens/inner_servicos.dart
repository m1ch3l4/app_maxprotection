//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/model/MessageModel.dart';
import 'package:app_maxprotection/model/ServicoModel.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:open_file_safe/open_file_safe.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:url_launcher/url_launcher.dart';

import '../model/ChatMessage.dart';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../widgets/RadialButton.dart';
import '../widgets/active_project_card.dart';
import '../widgets/bottom_container.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
import '../widgets/searchempresa_wdt.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


class InnerServicos extends StatelessWidget {

  static const routeName = '/servicos';
  SharedPref sharedPref = SharedPref();

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
            home: new ServicosPage(title: 'Serviços Contratados', user: snapshot.data,id:"0"),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class ServicosPage extends StatefulWidget {
  ServicosPage({Key key, this.title,this.user,this.id}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;
  _ServicosPageState state;

  String id;

  static _ServicosPageState of(BuildContext context) => context.findAncestorStateOfType<_ServicosPageState>();

  @override
  _ServicosPageState createState(){
    this.state =  new _ServicosPageState();
    return state;
  }
}

class _ServicosPageState extends State<ServicosPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  bool isConsultor=false;
  DateFormat simpleDate = DateFormat('dd/MM/yy');
  String languageCode="pt_BR";
  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  static EmpresasSearch _empSearch = EmpresasSearch();

  Empresa empSel;

  static List<DropdownMenuItem<Empresa>> _data = [];
  String _selected = '';

  List<Servico> listModel = [];
  var loading = false;

  searchEmpresa widgetSearchEmpresa;

  void loadData() {
    if(mounted) {
      setState(() {
        loading = true;
      });
      _data = [];
      print("Num de empresas: ");
      print(_empSearch.lstOptions.length);
      for (Empresa bean in _empSearch.lstOptions) {
        _data.add(
            new DropdownMenuItem(
                value: bean,
                child: Text(bean.name, overflow: TextOverflow.fade,)));
      }
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
    if(widget.user["tipo"]!="C") {
      getData();
    }else{
      loadData();
      isConsultor = true;
      widgetSearchEmpresa =
          searchEmpresa(onchangeF: () => getData(), context: context);
    }
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
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "messages");
    return Scaffold(
        key: _scaffoldKey,
        body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        drawer:  Drawer(
          child: SliderMenu('servicos',widget.user,textTheme,(width*0.6)),
        )
    );
  }

  Widget showContrato(double width){
    return Container(
      width: width,
      alignment: Alignment.center,
      margin: EdgeInsets.only(top:20,bottom: 20),
      child: GestureDetector(child:Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          decoration: new BoxDecoration(color: Colors.transparent),
          alignment: Alignment.center,
          height: 120,
          child: Image.asset("images/pdf.png")
      ),
        onTap: getContrato),
    );
  }
  Future<Null> getContrato() async{
    setState(() {
      //loading = true;
    });
    String urlApi = "";

    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    if(isConsultor){
      if(empSel!=null)
        urlApi =  Constants.urlEndpoint + "enterprise/showcontrato/" +empSel.id;
    }else {
      urlApi = Constants.urlEndpoint + "enterprise/showcontrato/" +
          widget.user['company_id'].toString();
    }


    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    print("****URL API: ");
    print(urlApi);
    print("**********");


    if(urlApi!="") {
      if(ssl){
        var client = HttpsClient().httpsclient;
        responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
            Duration(seconds: 5));
      }else {
        responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
            Duration(seconds: 5));
      }
      if (responseData.statusCode == 200) {
        setState(() {
          if (responseData.contentLength > 0) {
            showFile(responseData);
          } else {
            Message.showMessage(
                "O contrato da sua empresa ainda não foi digitalizado.\nEntre em contato com a Max Protection e solicite.");
          }
          loading = false;
        });
      } else {
        loading = false;
      }
    }else{
      setState(() {
        loading = false;
      });
    }
  }

  void showFile(responseData) async {
    var bytes = responseData;
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/example.pdf");
    await file.writeAsBytes(bytes.bodyBytes);

    print("${output.path}/example.pdf");
    await OpenFile.open("${output.path}/example.pdf");
  }//

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Stack(
              children: [
                headerAlertas(_scaffoldKey, widget.user, context, width, 195, "Serviços Contratados"),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top:170),
                  child: (isConsultor?widgetSearchEmpresa:SizedBox(height: 1,)),
                ),
              ]),
          showContrato(width*0.8),
          _body(width*0.95)
        ],
      ),
    );

  }

  Future<Null> getData() async{
    setState(() {
      //loading = true;
      listModel = [];
    });
    String urlApi = "";
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;


    if(isConsultor) {
      empSel = _empSearch.defaultOpt;
      urlApi = Constants.urlEndpoint + "servico/lista/" + empSel.id;
    }else {
      urlApi = Constants.urlEndpoint + "servico/lista/" +
          widget.user['company_id'].toString();
    }

    print("****URL API: ");
    print(urlApi);
    print("**********");


    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));

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
      //setState(() {
        for(Map i in data){
          var serv = Servico.fromJson(i);
          listModel.add(serv);
        }

      setState(() {
        print("total...."+listModel.length.toString());
        loading=false;
      });
        //loading = false;
      //});
    }else{
      loading = false;
    }
  }

  Widget _body(double width){
    return
      Container(
        height: MediaQuery.of(context).size.height-410,
        width: width,
          child:     SingleChildScrollView(
        child: criaTabela(),
      ));
  }

  criaTabela() {
    return listModel.isNotEmpty?
    SingleChildScrollView(child:Table(
      columnWidths: {
          0: FixedColumnWidth(105.0),// fixed to 100 width
          1: FlexColumnWidth(),
          2: FixedColumnWidth(90.0),//fixed to 100 width
      },
      //defaultColumnWidth: IntrinsicColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(
          color: HexColor(Constants.grey),
          style: BorderStyle.solid,
          width: 12.0,
        ),
      ),
      children: [
        for (int i = 0; i < listModel.length; i++)
          _criarLinhaTable(listModel[i].titulo,listModel[i].descricao,listModel[i].contratado,listModel[i].id,i)
      ],
    ))
        :SizedBox(width: 1,);
  }

  _criarLinhaTable(String titulo, String descricao, bool contatado,String id, int i) {
return TableRow(
        children: [
          col1(titulo,contatado),
          col2(descricao,contatado),
          colCheck(contatado, titulo, id, i)
        ]
    );
  }

  Widget col1(String title, bool isContrato){
    return Container(
        height:70,
        decoration: BoxDecoration(
          //borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color:(isContrato?HexColor(Constants.red):HexColor(Constants.blue)),width: 5),
            )
        ),
        child:
        Container(
            height:70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color:HexColor(Constants.firtColumn)
            ),
            padding: EdgeInsets.all(4.0),
            margin: EdgeInsets.only(right: 1.0),
            child:
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                Icon(Icons.miscellaneous_services_outlined,color:isContrato?HexColor(Constants.red):HexColor(Constants.blue)),
                Expanded(child:
                Text(
                  title,
                  textAlign: TextAlign.start,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: isContrato?HexColor(Constants.red):HexColor(Constants.blue),
                    fontWeight: FontWeight.bold,
                  )
              ))
        ])));
  }
  Widget col2(String desc, bool isContrato){
    return
        Container(
          height:70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color:Colors.white
            ),
            padding: EdgeInsets.all(5.0),
            margin: EdgeInsets.only(left:1.0,right: 1.0),
            child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:[
                  Expanded(child:
            Text(
                desc,
                style: TextStyle(
                  fontSize: 13.0,
                  color: isContrato?HexColor(Constants.red):HexColor(Constants.blue),
                  fontWeight: FontWeight.normal
                )
            ))])
        );
  }
  Widget colCheck(bool isContrato, String title, String id, int index){
    return
      Container(
          height:70,
          decoration: BoxDecoration(
            //borderRadius: BorderRadius.circular(10),
              border: Border(
                right: BorderSide(color:(isContrato?HexColor(Constants.red):HexColor(Constants.blue)),width: 5),
              )
          ),
          child:
          Container(
              height:70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color:Colors.white
              ),
              padding: EdgeInsets.all(4.0),
              margin: EdgeInsets.only(left:1.0,right: 1.0),
              child:
              CheckboxListTile(
                autofocus: false,
                activeColor: HexColor(Constants.red),
                checkColor: Colors.white,
                selected: isContrato,
                value: isContrato,
                onChanged: (bool value) {
                  setState(() {
                    if(value && !isConsultor){
                      maisInfoServico(id,title);
                    }
                  });
                },
              )
          ));
  }

  void maisInfoServico(id, title){
    AlertDialog alert;
    BuildContext dialogContext;

    alert = AlertDialog(
      title: Text("Informações sobre Serviços"),
      content: Text("Gostaria que um de nossos consultores entrasse em contato para falar mais sobre "+title+"?"),
      actions: [
        FlatButton(
          onPressed: () {
            sendMessage("Quero receber mais informações sobre "+title);
            Navigator.pop(dialogContext, false);
          }, // passing false
          child: Text('Sim, por favor.'),
        ),
        FlatButton(
          onPressed: () => Navigator.pop(dialogContext, true), // passing true
          child: Text('Não, obrigada.'),
        ),
      ],
    );  // show the dialog
    showDialog(
        context: context,
        builder: (context) {
          dialogContext = context;
          return alert;
        }
    );
  }

  Future<String> sendMessage(String assunto) async{
    var url =Constants.urlEndpoint+'message/app';

    print("url $url");
    int tipo = 3;

    Map params = {
      'userid':widget.user["id"],
      'nome': widget.user["name"],
      'email' : widget.user["login"],
      'celular': '00000',
      'tipo': tipo,
      'assunto':assunto
    };

    //encode Map para JSON(string)
    var body = json.encode(params);

    var response = await http.post(Uri.parse(url),
        headers: {"Access-Control-Allow-Origin": "*", // Required for CORS support to work
          "Access-Control-Allow-Credentials": "true", // Required for cookies, authorization headers with HTTPS
          "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
          "Access-Control-Allow-Methods": "POST, OPTIONS"},
        body: body).timeout(Duration(seconds: 5));

    if(response.statusCode==200){
      Message.showMessage(response.body);
    }
    return response.body;
  }

  void _launchURL(_url) async =>
      await canLaunch(Uri.encodeFull(_url)) ? await launch(Uri.encodeFull(_url)) : throw 'Could not launch $_url';

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return MediaQuery.removePadding(
        context: ctx,
        removeTop: true,
        child: ListView(
          controller: sc,
          children: <Widget>[
            SizedBox(
              height: 12.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                ),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            BottomContainer(
              height: 30,
              width: width,
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      'Mais Serviços',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: HexColor(Constants.red),
                        fontWeight: FontWeight.w400,
                      )
                  ),
                  SizedBox(width:20),
                  Icon(Icons.arrow_upward,
                      color: HexColor(Constants.red), size: 30.0),
                ],
              ),
            ),
            Column(
                children: <Widget>[
                  Container(
                      color: HexColor(Constants.grey),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                ActiveProjectsCard(
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.support,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets Abertos',
                                ),
                                SizedBox(width: 20.0),
                                ActiveProjectsCard(
                                  cardColor: Colors.white,
                                  icon:Icon(Icons.watch_later_outlined,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets em Atendimento',
                                ),
                              ],
                            ),
                          ]))]),
            SizedBox(
              height: 5,
            ),
          ],
        ));
  }

}