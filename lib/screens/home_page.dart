// @dart=2.10
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_maxprotection/api/CallTecnicoApi.dart';
import 'package:app_maxprotection/model/RoleModel.dart';
import 'package:collection/collection.dart';
import 'package:app_maxprotection/screens/inner_messages.dart';
import 'package:app_maxprotection/screens/inner_servicos.dart';
import 'package:app_maxprotection/screens/inner_tecnicos.dart';
import 'package:app_maxprotection/screens/ticketlist-consultor.dart';
import 'package:app_maxprotection/screens/ticketsview-consultor.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/BlinkIcon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/DashboardModel.dart';
import '../model/NoticiaModel.dart';
import '../model/empresa.dart';
import '../model/usuario.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/Message.dart';
import '../widgets/active_project_card.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/row_card.dart';
import '../widgets/search_box.dart';
import '../widgets/slider_menu.dart';

import 'package:http/http.dart' as http;

import '../widgets/top_container.dart';
import 'inner_elastic.dart';
import 'inner_noticias.dart';
import 'inner_zabbix.dart';

import 'package:url_launcher/url_launcher.dart';

final keyHP = new GlobalKey<_MyHomePageState>();

class HomePage extends StatelessWidget {
  static const routeName = '/dashboard';
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
            home: new MyHomePage(key:keyHP,title: 'MaxProtection E-Seg', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }

}

class MyHomePage extends StatefulWidget{
  MyHomePage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{

  List<NoticiaData> listModel = [];
  DashboardData dashboard;
  var loading=false;
  int totalSiem = 0;
  int totalAberto = 0;
  int totalFechado = 0;
  int msgSiem = 0;
  int msgZabbix = 0;
  int msgTicket = 0;
  bool isConsultor = false;
  String perfil = "Analista";

  DashboardData get dashboardDados=>dashboard;

  static EmpresasSearch _empSearch = EmpresasSearch();

  FCMInitConsultor _fcmInit = new FCMInitConsultor();
  SliderMenu mnu;
  TextTheme textTheme;
  final df = new DateFormat('dd/MM HH:mm');

  diableBlink(){
    print("chamou disableBlink da Home...");
    setState(() {
      this.dashboard.msgLead = 0;
      loading = false;
    });

  }

  void initFCM(){
    EmpresasSearch _empSearch = new EmpresasSearch();
    List<Empresa> lstEmpresas = [];
    var a = widget.user;
    if(a!=null) {
      if(a['empresas']!=null) {
        print('empresa...'+a['empresas'].toString());
        for (Map<String, dynamic> i in a['empresas']) {
          lstEmpresas.add(Empresa.fromJson(i));
        }
        _empSearch.setOptions(lstEmpresas);
      }
    }
    FCMInitConsultor _fcmInit = new FCMInitConsultor();
    _fcmInit.setConsultant(a);
  }
  Future<Null> getDashboardData() async{
    if(!mounted)
      return;

    setState(() {
      loading = true;
      initFCM();
    });

    String urlApi = "";

    if(widget.user['tipo']=="C") {
      urlApi = Constants.urlEndpoint + "dashboard/consultor/" +
          widget.user['id'].toString() + "/30";
      isConsultor=true;
      perfil="Consultor";
    } else {
      if(widget.user['tipo']=='D'){
        urlApi = Constants.urlEndpoint + "dashboard/diretor/" +
            widget.user['company_id'].toString() + "/" +
            widget.user['id'].toString() + "/30";
        perfil="Diretor";
      }else {
        urlApi = Constants.urlEndpoint + "dashboard/tecnico/" +
            widget.user['id'].toString() + "/30";
        print("Tecnico: "+urlApi);
        perfil = "Analista";
      }
      isConsultor=false;
    }

    //print('urlApi...'+urlApi);
    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));
    if(responseData.statusCode == 200){
      if(responseData.body.length>0){
        String source = Utf8Decoder().convert(responseData.bodyBytes);
        final data = jsonDecode(source);
        //print('dashboard...'+data.toString());
        setState(() {
          dashboard = DashboardData.fromJson(data);
          if(data!=null && data['infoNewsList']!=null) {
            for (Map i in data['infoNewsList']) {
              listModel.add(NoticiaData.fromJson(i));
            }
          }
          loading = false;
        });
      }else{
        loading = false;
        Message.showMessage("A sua credencial não é mais válida!");
        logoff();
      }
    }else{
      loading = false;
    }
  }

  void refreshUser() async{
    final prefs = await SharedPreferences.getInstance();
    String urlApi = "";
    urlApi = Constants.urlEndpoint + "dashboard/consultor/refresh/" +
          widget.user['id'].toString();

    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));
    if(responseData.statusCode == 200) {
      if(responseData.body.length>0){
        String source = Utf8Decoder().convert(responseData.bodyBytes);

        Map<String,dynamic> mapResponse  = jsonDecode(source);
        Usuario refresh = Usuario.fromJson(mapResponse);
        Usuario doSistema = Usuario.fromSharedPref(widget.user);

        Role rAtual = doSistema.role;
        Role rNova = refresh.role;

        if(!refresh.hasAccess && refresh.tipo == "T"){
          Message.showMessage("A sua credencial não é mais válida!");
          logoff();
        }

        if(rAtual.nome != rNova.nome){
          setState(() {
            mnu = SliderMenu('index',refresh.toJson(),textTheme);
            prefs.setString('usuario', json.encode(refresh));
          });
        }

        if(doSistema.tipo=="C") {
          List<Empresa> eNova = refresh.empresas;
          List<Empresa> eOld = doSistema.empresas;
          eNova.sort((a, b) => a.name.compareTo(b.name));
          eOld.sort((a, b) => a.name.compareTo(b.name));

          if (!DeepCollectionEquality().equals(eNova, eOld)) {
            List<Empresa> lstEmpresas = [];
            lstEmpresas.add(Empresa("0", "Todas"));
            lstEmpresas.addAll(refresh.empresas);
            _empSearch.setOptions(lstEmpresas);
            FCMInitConsultor().unRegisterAll();
            FCMInitConsultor().setConsultant(refresh.toJson());
          }
          prefs.setString('usuario', json.encode(refresh));

          eNova = null;
          eOld = null;
        }
      }else{
          Message.showMessage("A sua credencial não é mais válida!");
          logoff();
      }
    }
  }

  void initState(){
    getDashboardData();

    _fabHeight = _initFabHeight;
    super.initState();
    const fiveSec = const Duration(minutes: 5);
    new Timer.periodic(fiveSec, (Timer t) {
      getDashboardData();
      refreshUser();
    });
  }


  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;


  Text subheading(String title) {
    return Text(
      title,
      style: TextStyle(
          color: Colors.blue,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
    );
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    textTheme = theme.textTheme;

    _fcmInit.configureMessage(context, "elastic");

    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    mnu = SliderMenu('index',widget.user,textTheme);
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
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
          child: mnu,
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        children: <Widget>[
          _header(width),
          _body(width),
        ],
      ),
    );
  }

  void ticketsOpen(){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
    ));
  }

  Widget _header(double width){
    return TopContainer(
      height: 208,
      width: width,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.menu, color:Colors.white,size: 30.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    _scaffoldKey.currentState.openDrawer();
                  },
                ),
                SizedBox(width:5),
                Text(
                  'Max Protection | '+perfil,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.person_outline_outlined, color:Colors.white,size: 20.0),
                  tooltip: 'Perfil',
                  onPressed: () {
                    print("perfil");
                    Message.showMessage("Em construção");
                  },
                ),
                Text(
                  'Olá, '+widget.user['name'].toString(),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app_outlined, color:Colors.white,size: 20.0),
                  tooltip: 'Sair',
                  onPressed: () {
                    confirmarLogoff(context);
                    //exit(0);
                  },
                )
              ],
            ),
            const Divider(
              height: 3,
              thickness: 1,
              indent: 5,
              endIndent: 5,
              color: Colors.white,
            ),
            Row(
              children: <Widget>[
                Column(
                  children: [
                    Text(
                      'Seus tickets abertos',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      child: Text(
                        dashboard.open.toString(),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 24.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => ticketsOpen()
                    )
                    ,
                  ],
                ),
                Spacer(),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(FadePageRoute(
                      builder: (context) => (isConsultor?TicketsviewConsultor(0):TicketlistConsultor(null, 0)),
                    ));},
                  child: Text(
                    'Ver todos',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_outlined, color:Colors.white,size: 18.0),
                  tooltip: 'Ver todos',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(FadePageRoute(
                      builder: (context) => (isConsultor?TicketsviewConsultor(0):TicketlistConsultor(null, 0)),
                    ));
                  },
                )
              ],
            ),
            //Spacer(flex:2),
            SearchBox(
                cardColor: Colors.white,
                title: "Fale Conosco",
                iconsufix: Icon(Icons.send_outlined, color: Colors.white, size: 18.0),
              usr: widget.user
            ),
          ]),
    );
  }

  confirmarLogoff(BuildContext context) {  // se
    AlertDialog alert;
    Widget cancelButton = FlatButton(
      child: Text("Cancelar"),
      onPressed:  () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
    Widget launchButton = FlatButton(
      child: Text("Quero sair!"),
      onPressed:  () {
        logoff();
      },
    );  // set up the AlertDialog
    alert = AlertDialog(
      title: Text("ATENÇÃO"),
      content: Text("Ao Sair você fará logoff no App e precisará fazer login novamente. Tem certeza que deseja sair?"),
      actions: [
        cancelButton,
        launchButton,
      ],
    );  // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  logoff() async {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      FCMInitConsultor().unRegisterAll();
      exit(0);
  }

  callTecnico() async{
    CallTecnicoApi.callTecnico(widget.user["id"])
    .then((resp){
    print('callTecnicoAPI. ${resp.ok}');
    if(!resp.ok){
      Message.showMessage(resp.msg);
    }else {
      Usuario u = resp.result;
      if(u.phone!=null){
        Message.showMessage("Ligando para "+u.name+", telefone: "+u.phone);
        String ph = "0"+u.phone.replaceAll(RegExp('[^0-9]'), ''); // 25/08/2022 - adicionando o ZERO pela questão da operadora...
        if(ph.length>10) {
          FlutterPhoneDirectCaller.callNumber(ph);
        }else{
          Message.showMessage("O número de telefone parece estar incorreto: \n"+ph); //considerando um número de celular com dd
        }
      }else{
        Message.showMessage("Telefone do técnico de plantão não foi informado!");
      }
    }
    });
  }

  Widget _body(double width){
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.transparent,
              padding: EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        ctx:context,
                        r:false,
                        action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
                        cardColor: Colors.white,
                        icon: Icon(Icons.support,
                            color: HexColor(Constants.red), size: 20.0),
                        title: 'Tickets Abertos',
                      ),
                      SizedBox(width: 20.0),
                      ActiveProjectsCard(
                          ctx:context,
                          r:false,
                          action: (isConsultor?TicketsviewConsultor(2):TicketlistConsultor(null,2)),
                        cardColor: Colors.white,
                        icon:Icon(Icons.watch_later_outlined,
                            color: HexColor(Constants.red), size: 20.0),
                        title: 'Tickets em Atendimento',
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        ctx:context,
                        r:false,
                        action: InnerElastic(),
                        cardColor: Colors.white,
                        icon: Icon(Icons.volume_down_sharp,
                            color: HexColor(Constants.red), size: 20.0),
                        title: 'SIEM',
                      ),
                      SizedBox(width: 20.0),
                      ActiveProjectsCard(
                        ctx:context,
                        r:false,
                        action: InnerZabbix(),
                        cardColor: Colors.white,
                        icon: Icon(Icons.web,
                            color: HexColor(Constants.red), size: 20.0),
                        title: 'Zabbix',
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        r:false,
                        ctx:context,
                        action: InnerMessages(2),
                        cardColor: Colors.white,
                        icon: (dashboard.msgTicket>0?BlinkIcon():null),
                        title: 'Mensagens sobre Tickets',
                      ),
                      SizedBox(width: 20.0),
                      ActiveProjectsCard(
                        r:false,
                        ctx:context,
                        action: InnerMessages(1),
                        cardColor: Colors.white,
                        icon:(dashboard.msgSiem>0?BlinkIcon():null),
                        title: 'Mensagens sobre SIEM',
                      ),
                    ],
                  ),
                  (widget.user["tipo"]=="C"?
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        r:false,
                        ctx:context,
                        action: InnerMessages(4),
                        cardColor: Colors.white,
                        icon: (dashboard.msgLead>0?BlinkIcon():null),
                        title: 'Leads',
                        disableBlink: (){this.diableBlink();},
                      ),
                    ],
                  )
                      :
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        ctx:context,
                        r:false,
                        action: InnerMessages(3),
                        cardColor: Colors.white,
                        icon: (dashboard.msgZabbix>0?Icon(Icons.email_outlined,
                            color: HexColor(Constants.red), size: 20.0):null),
                        title: 'Mensagens sobre Zabbix',
                      ),
                    ],
                  ))
                  ,
                  (widget.user["tipo"]=="T"?
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        ctx:context,
                        r:true,
                        onclickF: ()=>callTecnico(),
                        cardColor: Colors.white,
                        icon: Icon(Icons.call_outlined, color: HexColor(Constants.red),size:20.0),
                        title: 'Ligar para Técnico Plantonista!',
                      ),
                    ],
                  )
                      : SizedBox(height: 1,)),
                  (widget.user["tipo"]=="D"?
                  Row(
                    children: <Widget>[
                      ActiveProjectsCard(
                        r:false,
                        ctx:context,
                        action: InnerTecnicos(),
                        cardColor: Colors.white,
                        icon: Icon(Icons.person_outline_outlined, color: HexColor(Constants.red),size:20.0),
                        title: 'Técnicos',
                      ),
                    ],
                  )
                      : SizedBox(height: 1,)),
                  buildTileNoticia(width),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(ScrollController sc, double width, BuildContext ctx) {
    return BottomMenu(ctx,sc,width,widget.user);
  }


  Widget buildTileNoticia(double width){
    return Container(
            alignment: Alignment.topCenter,
            width: width,
            height: 120,
            child: loading ? Center (child: CircularProgressIndicator()) : (listModel.length>0? getSwiper(width):Center(
                child: Text(
                  "Nenhuma notícia atual",
                  style: TextStyle(color: HexColor(Constants.red), fontWeight: FontWeight.w700, fontSize: 24.0),
                  textAlign: TextAlign.center,
                ))));
  }
  Widget getSwiper(double width){
    return Swiper(
      itemBuilder: (BuildContext context, int index) {
        return getNoticia(listModel[index].titulo, listModel[index].data, listModel[index].texto,listModel[index].url);
      },
      itemCount: listModel.length,
      itemWidth: width,
      itemHeight: 120.0,
      layout: SwiperLayout.DEFAULT,
      //control: new SwiperControl(),
    );
  }
  void gotToNoticias(){
    Navigator.of(this.context).pushReplacement(FadePageRoute(
      builder: (context) => InnerNoticias(),
    ));
  }
  Widget getNoticia(String title, String date, String text, String url){
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            ListTile(
                onTap: gotToNoticias,
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(df.format(DateTime.parse(date))),
                leading: Icon(
                    Icons.book_outlined,
                    color: HexColor(Constants.red)
                )),
            /**ListTile(
                title: Text("Leia Mais",style: TextStyle(fontSize: 12.0)),
                onTap: (){
                  _launchURL(url);
                }
            )**/
          ],
        )
    );
  }

  void _launchURL(_url) async =>
      await canLaunch(Uri.encodeFull(_url)) ? await launch(Uri.encodeFull(_url)) : throw 'Could not launch $_url';
}
