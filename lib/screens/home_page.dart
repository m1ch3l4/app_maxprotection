// @dart=2.10
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_maxprotection/api/CallTecnicoApi.dart';
import 'package:app_maxprotection/api/ChangPassApi.dart';
import 'package:app_maxprotection/model/RoleModel.dart';
import 'package:app_maxprotection/screens/inner_tecnicos.dart';
import 'package:app_maxprotection/screens/inner_todostk.dart';
import 'package:app_maxprotection/utils/HomeSearchDelegate.dart';
import 'package:app_maxprotection/utils/HttpsClient.dart';
import 'package:app_maxprotection/utils/Logoff.dart';
import 'package:app_maxprotection/widgets/BlockButtonWidget.dart';
import 'package:app_maxprotection/widgets/HexColor.dart';
import 'package:app_maxprotection/widgets/TopHomeWidget.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:app_maxprotection/screens/inner_messages.dart';
import 'package:app_maxprotection/screens/ticketlist-consultor.dart';
import 'package:app_maxprotection/screens/ticketsview-consultor.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/BlinkIcon.dart';
import 'package:flutter/cupertino.dart';
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
import '../utils/Message.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/search_box.dart';
import '../widgets/slider_menu.dart';

import 'package:http/http.dart' as http;

import '../widgets/top_container.dart';
import 'inner_elastic.dart';
import 'inner_noticias.dart';
import 'inner_user.dart';
import 'inner_zabbix.dart';

import 'package:url_launcher/url_launcher.dart';

final GlobalKey<_MyHomePageState> keyHP = new GlobalKey<_MyHomePageState>();

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
  static _MyHomePageState state;

  @override
  _MyHomePageState createState() {
    state = new _MyHomePageState();
    return state;
  }
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
  Timer alarm;
  double tam = 0.0;

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

  List<String> searchTerms = ["zabbix","siem","tickets","senha","dados","abrir","falar","fale","leads","noticias","servuços"];

  void searchExecute(String query){
    print("queryTerm..."+query);
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }
    print(">>>>"+matchQuery.toString());
  }

  /**bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }**/


  Future<void> initFCM() async {
    EmpresasSearch _empSearch = new EmpresasSearch();
    List<Empresa> lstEmpresas = [];
    var a = widget.user;
    if(a!=null) {
      if(a['empresas']!=null) {
        //print('empresa...'+a['empresas'].toString());
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
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    if(!mounted)
      return;

    setState(() {
      loading = true;
      initFCM();
    });

    String urlApi = "";

    //widget.user.forEach((k,v) => print("got key $k with $v"));

    if(widget.user['tipo']=="C") {
      urlApi = Constants.urlEndpoint + "dashboard/consultor/" +
          widget.user['id'].toString();
      isConsultor=true;
      perfil="Consultor";
    } else {
      if(widget.user['tipo']=='D'){
        urlApi = Constants.urlEndpoint + "dashboard/diretor/" +
            widget.user['company_id'].toString() + "/" +
            widget.user['id'].toString() ;
        perfil="Diretor";
      }else {
        urlApi = Constants.urlEndpoint + "dashboard/tecnico/" +
            widget.user['id'].toString() ;
        print("Tecnico: "+urlApi);
        perfil = "Analista";
      }
      print("URLAPI...."+urlApi);
      isConsultor=false;
    }

    String basicAuth = "Bearer "+widget.user["token"];

    Map<String, String> h = {
    "Authorization": basicAuth,
    };

    if(ssl) {
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 8), onTimeout: _onTimeout);
    }else {
      responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 8), onTimeout: _onTimeout);
    }

    if(responseData!=null && responseData.statusCode == 200){
      if(responseData.body.length>0){
        String source = Utf8Decoder().convert(responseData.bodyBytes);
        final data = jsonDecode(source);
        //print('dashboard...'+data.toString());
        if(!mounted) return;

        setState(() {
          dashboard = DashboardData.fromJson(data);
          //data.forEach((k,v) => print("Dashboard.got key $k with $v"));

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
        Logoff.logoff();
      }
    }else{
      if(responseData!=null && responseData.statusCode==401){
        Message.showMessage("As suas credenciais não são mais válidas!");
        sleep(Duration(seconds:8));
        Logoff.logoff();
      }
      loading = false;
      dashboard = new DashboardData.data(0,0,0,0,0,0);
      dashboard.msgTicket=0;
      dashboard.msgLead=0;
      dashboard.msgZabbix=0;
      dashboard.msgSiem=0;
      Message.showMessage("Não foi possível sincronizar com a nuvem.\nVerifique sua conexão com a Internet.");
    }
  }

  FutureOr<http.Response> _onTimeout(){
    setState(() {
      loading=false;
      print("não foi possível conectar em 8sec");
    });
  }
  void refreshUser() async{
    print("******chamou refreshUser....");

    final prefs = await SharedPreferences.getInstance();
    String urlApi = "";
    urlApi = Constants.urlEndpoint + "dashboard/consultor/refresh/" +
          widget.user['id'].toString();

    try{

      String p = widget.user["password"];
      String basicAuth = "Bearer "+widget.user["token"];
      var ssl = false;
      var responseData = null;

      if(Constants.protocolEndpoint == "https://")
        ssl = true;

      Map<String, String> h = {
        "Authorization": basicAuth,
      };

    if(ssl){
      var client = HttpsClient().httpsclient;
      responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 8), onTimeout: _onTimeout);
    }else {
      responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
          Duration(seconds: 8), onTimeout: _onTimeout);
    }
    if(responseData!=null && responseData.statusCode == 200) {
      if (responseData.body.length > 0) {
        String source = Utf8Decoder().convert(responseData.bodyBytes);

        Map<String, dynamic> mapResponse = jsonDecode(source);
        Usuario refresh = Usuario.fromJson(mapResponse);
        Usuario doSistema = Usuario.fromSharedPref(widget.user);
        refresh.senha = p;

        Role rAtual = doSistema.role;
        Role rNova = refresh.role;

        if (!refresh.hasAccess && refresh.tipo == "T") {
          Message.showMessage("A sua credencial não é mais válida!");
          Logoff.logoff();
        }

        double width = MediaQuery.of(context).size.width;
        if (rAtual.nome != rNova.nome) {
          setState(() {
            mnu = SliderMenu('index', refresh.toJson(), textTheme,(width*0.5));
            prefs.setString('usuario', json.encode(refresh));
          });
        }

        if (doSistema.tipo == "C") {
          List<Empresa> eNova = refresh.empresas;
          List<Empresa> eOld = doSistema.empresas;
          eNova.sort((a, b) => a.name.compareTo(b.name));
          eOld.sort((a, b) => a.name.compareTo(b.name));

          if (!DeepCollectionEquality().equals(eNova, eOld)) {
            List<Empresa> lstEmpresas = [];
            lstEmpresas.add(Empresa("0", "Todas"));
            lstEmpresas.addAll(refresh.empresas);
            print("Se entrou aqui encontrou mudança na lista de empresas...");
            _empSearch.setOptions(lstEmpresas);
            FCMInitConsultor().unRegisterAll();
            FCMInitConsultor().setConsultant(refresh.toJson());
          }
          prefs.setString('usuario', json.encode(refresh));

          eNova = null;
          eOld = null;
        }
      } else {
        Message.showMessage("A sua credencial não é mais válida!");
        Logoff.logoff();
      }
    }
    }catch(error, exception){
      print("Home.Erro : $error > $exception ");
    }

  }

  void initState(){
    getDashboardData();
    _fabHeight = _initFabHeight;
    super.initState();
    taskRefresh();
    //BackButtonInterceptor.add(myInterceptor);
  }

  void taskRefresh(){
    const fiveSec = const Duration(minutes: 5);
    if(alarm == null) {
      alarm = new Timer.periodic(fiveSec, (Timer t) {
        getDashboardData();
        refreshUser();
      });
    }
  }

  void dispose(){
    //BackButtonInterceptor.remove(myInterceptor);
    alarm.cancel();
    super.dispose();
  }

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  //double width = 150.0;
  TextEditingController _textFieldController = TextEditingController();
  String valueText="";
  String codeDialog="";

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
    print("_fabheight..."+_fabHeight.toString());
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    textTheme = theme.textTheme;

    _fcmInit.configureMessage(context, "elastic");

    double width = MediaQuery.of(context).size.width;

    tam = MediaQuery.of(context).size.height;

    print("tamanho da tela: "+tam.toString());

    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    mnu = SliderMenu('home',widget.user,textTheme,width);
    return Scaffold(
      appBar: AppBar(backgroundColor: HexColor(Constants.blue), toolbarHeight: 0,),
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
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
          child: mnu,
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
              Stack(
                children: [
                  _header(width),
                  Positioned(child: SearchBox(
                      cardColor: Colors.white,
                      title: "Pesquisar",
                      usr: widget.user,
                    width: width*0.9,
                    f:searchExecute,
                    searchDelegate: HomeSearchDelegate(isConsultor),
                  ),
                    top:188,
                    left: width*0.05,
                  ),
                  Container(
                    height:tam,
                    padding:  EdgeInsets.only(top: 220),
                    child: _body(width),
                  )
                ],
              )
              ]
      ),
    );
  }

  void ticketsOpen(){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
    ));
  }

  void cadastro(){
    Navigator.of(context).pushReplacement(FadePageRoute(
      builder: (context) => (InnerUser()),
    ));
  }

  Widget _header(double width){
    return TopContainer(
      height: 208,
      width: width,
      color: HexColor(Constants.blue),
      child: Column(
          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [SizedBox(height: 10,)],),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.menu, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    _scaffoldKey.currentState.openDrawer();
                  },
                ),
                Spacer(),
                Image.asset("images/lg.png",width: 150,height: 69,),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    _scaffoldKey.currentState.openDrawer();
                  },
                ),
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
                    cadastro();
                    //print("perfil");
                    //Message.showMessage("Em construção");
                  },
                ),
               Expanded(child: Text(
                  'Olá, '+widget.user['name'].toString()+" | "+perfil,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.exit_to_app_outlined, color:Colors.white,size: 20.0),
                  tooltip: 'Sair',
                  onPressed: () {
                    Logoff.confirmarLogoff(context);
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: [
                    Text(
                      ' Seus tickets abertos',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      child: Text(
                        dashboard.novo.toString(),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 18.0,
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
                    Navigator.of(context).push(FadePageRoute(
                      builder: (context) => (isConsultor?TicketsviewConsultor(0):InnerTodosTk()),
                    ));},
                  child: Text(
                    'Ver todos',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_outlined, color:Colors.white,size: 18.0),
                  tooltip: 'Ver todos',
                  onPressed: () {
                    Navigator.of(context).push(FadePageRoute(
                      builder: (context) => (isConsultor?TicketsviewConsultor(0):InnerTodosTk()),
                    ));
                  },
                )
              ],
            )
          ]),
    );
  }

  callTecnico() async{
    CallTecnicoApi.callTecnico(widget.user["token"],widget.user["id"])
    .then((resp){
    print('callTecnicoAPI. ${resp.ok}');
    if(!resp.ok){
      Message.showMessage(resp.msg);
    }else {
      Usuario u = resp.result;
      if(u.id!="-1") {
        if (u.phone != null) {
          Message.showMessage(
              "Ligando para " + u.name + ", telefone: " + u.phone);
          String ph = "0" + u.phone.replaceAll(RegExp('[^0-9]'),
              ''); // 25/08/2022 - adicionando o ZERO pela questão da operadora...
          if (ph.length > 10) {
            FlutterPhoneDirectCaller.callNumber(ph);
          } else {
            Message.showMessage(
                "O número de telefone parece estar incorreto: \n" +
                    ph); //considerando um número de celular com dd
          }
        } else {
          Message.showMessage(
              "Telefone do técnico de plantão não foi informado!");
        }
      }else{
        Message.showMessage("Fora do horário de Plantão.\nPor favor entre em contato com o nosso suporte.");
      }
    }
    });
  }

  Widget _body(double width){
    double bheight = MediaQuery.of(context).size.height-290;
    print("altura para o body...."+bheight.toString());
    double rowHeight = (bheight/4)-80;
    print("altura de cada linha: "+rowHeight.toString());
    bool extraRow =(widget.user["tipo"]=="T"||widget.user["tipo"]=="D"?true:false);

    return //Expanded(
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: width,
              color: Colors.transparent,
              height: bheight,
              /**padding: EdgeInsets.only(
                  left:width*0.1,right:width*0.1),**/
              child: Column(
                children: <Widget>[
                  //SizedBox(height: 25,),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: width*0.06,),
                      TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.42,icon:Icon(Icons.phone_forwarded,color: Colors.white),title: "Fale com o Diretor",ctx: context,r:true,
                        onclickF: ()=>faleComDiretor(context),),
                      Spacer(),
                      TopHomeWidget(cardColor: HexColor(Constants.grey),width: width*0.4,title: "Leads",ctx: context,r:false,
                        action: InnerMessages(4),
                          icon: (dashboard.msgLead>0?BlinkIcon():Icon(Icons.people_outline,color: Colors.white)),
                          disableBlink: (){this.diableBlink();},
                      ),
                      SizedBox(width: width*0.05,),
                    ],
                  ),
                  (bheight<400 && extraRow?SizedBox(height: 15,):Spacer()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: width*0.06,),
                      BlockButtonWidget(cardColor: Colors.white,width: width*0.4,title: "TICKETS\nABERTOS",ctx: context,image: "images/tkaberto.png",action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),r:false,bheight: bheight),
                      Spacer(),
                      BlockButtonWidget(cardColor: Colors.white,width: width*0.4,title: "TICKETS EM\nATENDIMENTO",ctx: context,image: "images/tkatendimento.png", action:(isConsultor?TicketsviewConsultor(2):TicketlistConsultor(null,2)),r:false,bheight: bheight),
                      SizedBox(width: width*0.06,),
                    ],
                  ),
                  (bheight<400 && extraRow?SizedBox(height: 15,):Spacer()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: width*0.06,),
                      BlockButtonWidget(cardColor: Colors.white,width: width*0.4,title: "SIEM",ctx: context,image: "images/siem.png",action: InnerElastic(null,null),r:false,bheight: bheight),
                      Spacer(),
                      BlockButtonWidget(cardColor: Colors.white,width: width*0.4,title: "ZABBIX",ctx: context,image: "images/zabbix.png", action: InnerZabbix(null,null),r:false,bheight: bheight),
                      SizedBox(width: width*0.06,),
                    ],
                  ),
                  (bheight<400 && extraRow?SizedBox(height: 15,):Spacer()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: width*0.06,),
                      BlockButtonWidget(cardColor: Colors.white,width: width*0.4,title: "MENSAGENS\nTICKETS",ctx: context,image: "images/message.png",action:InnerMessages(2),r:false,bheight: bheight),
                      Spacer(),
                      BlockButtonWidget(cardColor: Colors.white,width: width*0.4,title: "MENSAGENS\nSIEM",ctx: context,image: "images/message.png",action:InnerMessages(1),r:false,bheight: bheight),
                      SizedBox(width: width*0.06,),
                    ],
                  ),
                  (bheight<400 && extraRow?SizedBox(height: 15,):Spacer()),
                  if(widget.user["tipo"]=="T")
                    Row(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[BlockButtonWidget(cardColor: Colors.white,width: width*0.875,title: "Ligar para Plantonista",ctx: context,icon:Icon(Icons.phone_forwarded,color: HexColor(Constants.blueButton),size:40),onclickF: ()=>callTecnico(),r:true,bheight: bheight)]),
                  if(widget.user["tipo"]=="D")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[BlockButtonWidget(cardColor: Colors.white,width: width*0.875,title: "TÉCNICOS",ctx: context,icon:Icon(Icons.people_outline,color: HexColor(Constants.blueButton),size: 40,),action:InnerTecnicos(),r:false,bheight: bheight)
                      ],
                    ),
                  (bheight<400 && extraRow?SizedBox(height: 15,):SizedBox(height: 10,)),
                ],
              ),
            ),
          ],
        ),
      //),
    );
  }


  Future<void> faleComDiretor(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[Text('Fale com o Diretor', style: TextStyle(color: HexColor(Constants.blueTxt))),
            GestureDetector(
              onTap: (){
                Navigator.of(context).pop();
              },
              child: Align(
                alignment: Alignment.topRight,
                child:
                CircleAvatar(
                    radius: 16,
                    backgroundColor: HexColor(Constants.grey),
                  child:CircleAvatar(
                  radius: 14.0,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, color: Colors.red),
                )),
              ),
            ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("A sua mensagem será enviada para o e-mail do Diretor",style: TextStyle(color:HexColor(Constants.red),fontSize: 16.0, fontWeight: FontWeight.bold),textAlign: TextAlign.start),
                SizedBox(height: 10.0,),
                TextField(
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() {
                      valueText = value;
                    });
                  },
                  controller: _textFieldController,
                  decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0),borderSide: BorderSide(width: 2, color: HexColor(Constants.blueTxt)))
                      ,hintText: ""),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: EdgeInsets.only(left:13, right:13),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: HexColor(Constants.red),
                  minimumSize: Size.fromHeight(40), // NEW
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)
                  ),
                ),
                child: Text("ENVIAR", style:TextStyle(color:Colors.white)),
                onPressed: () {
                  if(_textFieldController.value.text!="") {
                  ChangePassApi.sendMessageDiretor(
                  widget.user["id"], valueText).then((resp) {
                  if (resp.ok) {
                  Message.showMessage("Mensagem enviada com sucesso!");
                  } else {
                  Message.showMessage(
                  "Problemas ao enviar mensagem!\nTente novamente em instantes.");
                  }
                  });
                  }else{
                  Message.showMessage("Escreva a mensagem que deseja enviar ao Diretor.");
                  }
                  setState(() {
                  codeDialog = valueText;
                  valueText="";
                  _textFieldController.text = "";
                  Navigator.pop(context);
                  });
          },
              ),
              SizedBox(height: 20,)
            ],
          );
        });
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
