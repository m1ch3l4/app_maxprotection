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
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:url_launcher/url_launcher.dart';

import '../model/ChatMessage.dart';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/active_project_card.dart';
import '../widgets/bottom_container.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
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

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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


   /** _empSearch.addListener(() {
      print('detectou a mudança...');
      loadData();
    });**/

    languageCode = Localizations.localeOf(context).languageCode;
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "messages");
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
          panelBuilder: (sc) => _panel(sc,width,context),
          body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        ),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('messages',widget.user,textTheme),
        )
    );
  }

  Widget showContrato(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 12,),
        Text(
          'Ver contrato com a Max Protection:',
         textAlign: TextAlign.start,
           style: TextStyle(
            fontSize: 14.0,
            color: HexColor(Constants.red),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 3,),
        new RaisedButton(
          onPressed: getContrato,
          child: new Text('Exibir',style:TextStyle(color: HexColor(Constants.red), fontWeight: FontWeight.w700, fontSize: 14.0)),
        )
      ],
    );
  }
  Future<Null> getContrato() async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

    if(isConsultor){
      if(empSel!=null)
      urlApi =  Constants.urlEndpoint + "enterprise/showcontrato/" +empSel.id;
    }else {
      urlApi = Constants.urlEndpoint + "enterprise/showcontrato/" +
          widget.user['company_id'].toString();
    }

    print("****URL API: ");
    print(urlApi);
    print("**********");

    if(urlApi!="") {
      final responseData = await http.get(Uri.parse(urlApi)).timeout(
          Duration(seconds: 5));
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
        children: <Widget>[
          _header(width),
            (isConsultor?empresasToShow():SizedBox(height: 1,)),
          showContrato(),
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
    );
  }

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

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

    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      final data = jsonDecode(source);
      setState(() {
        for(Map i in data){
          var serv = Servico.fromJson(i);
          listModel.add(serv);
        }
        loading = false;
      });
    }else{
      loading = false;
    }
  }

  Widget empresasToShow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
            Column(
              children: [Text('Empresas Monitoradas:',
                textAlign: TextAlign.start,
            style: TextStyle(
            fontSize: 14.0,
            color: HexColor(Constants.red),
            fontWeight: FontWeight.w600,
            ),
            )],
            ),
            Column(
            children: [SizedBox(width: 10,)],
            ),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            children: [
              DropdownButton<Empresa>(
                value: empSel,
                isExpanded: true,
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
                    listModel = [];
                    getData();
                  });
                },
                items: _data
              )],
          ),
        )

          ],
        );
  }

  Widget _body(){
    return Expanded(
        child: listView());
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
                    'Serviços Contratados',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 80,)
                ],
              ),
            ),

          ]),
    );
  }

  /**
   * for (int i=0; i<5; i++)
      getAlert('titulo', day.add(Duration(days:i)),
      (i%2<1?"Gostaria de receber mais informações sobre o SonicWall":"Um consultor entrará em contato no seu telefone!"),
      (i%2<1?"":"MaxProtection"))
   */
  Widget listView(){
    DateTime day = DateTime.now().subtract(Duration(days:5));
    return ListView(
      children: <Widget>[
        Row(children: [SizedBox(width: 12,),Text(
          'Serviços contratados:',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 16.0,
            color: HexColor(Constants.red),
            fontWeight: FontWeight.w600,
          ),
        )],),
        for (int i = 0; i < listModel.length; i++)
          getAlert(listModel[i].id,listModel[i].titulo, listModel[i].descricao, listModel[i].contratado)
      ],
    );
  }

  Widget getAlert(String id, String title, String descricao, bool contratado){
    return Card(
        child: Column(
          children: [
            CheckboxListTile(
              title: Text(title),
              subtitle: Text(descricao),
              secondary: const Icon(Icons.miscellaneous_services_outlined),
              autofocus: false,
              activeColor: HexColor(Constants.red),
              checkColor: Colors.white,
              selected: contratado,
              value: contratado,
              onChanged: (bool value) {
                setState(() {
                  if(value && !isConsultor){
                    maisInfoServico(id,title);
                  }
                });
              },
            ),
            SizedBox(height: 20,)
          ],
        )
    );
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