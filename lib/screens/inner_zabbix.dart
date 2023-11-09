import 'dart:collection';
import 'dart:io';

import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:app_maxprotection/widgets/closePopup.dart';
import 'package:app_maxprotection/widgets/headerAlertas.dart';
import 'package:app_maxprotection/widgets/searchempresa_wdt.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/AlertModel.dart';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/HttpsClient.dart';
import '../utils/Message.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';

//void main() => runApp(new InnerZabbix());

class InnerZabbix extends StatelessWidget {

  final String? eid;
  final String? aid;

  InnerZabbix(this.eid,this.aid);

  static const routeName = '/zabbix';
  SharedPref sharedPref = SharedPref();
  @override
  Widget build(BuildContext context) {
    return Material(
      child: FutureBuilder(
        future: sharedPref.read("usuario"),
        builder: (context,snapshot){
          return (snapshot.hasData ? new ZabbixPage(title: 'Alertas Zabbix', user: snapshot.data as Map<String, dynamic>,eid:eid,aid:aid) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class ZabbixPage extends StatefulWidget {
  ZabbixPage({this.title,this.user,this.eid,this.aid});

  final String? eid;
  final String? aid;
  final String? title;
  final Map<String, dynamic>? user;

  @override
  _ZabbixPageState createState() => new _ZabbixPageState();
}

class _ZabbixPageState extends State<ZabbixPage> {

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  DateTime minDate = DateTime.now();
  DateTime firstDate= DateTime.now();
  DateTime initDate=DateTime.now(),endDate=DateTime.now();

  final df = new DateFormat('dd/MM/yyyy');
  final dbFormat = new DateFormat('yyyy-MM-dd');

  var txt = TextEditingController();
  var txt2 = TextEditingController();

  var dtParam1="";
  var dtParam2="";

  List<AlertData> listModel = [];
  var loading = false;

  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  bool isConsultor = false;
  static EmpresasSearch _empSearch = EmpresasSearch();

  late Empresa empSel;

  static List<DropdownMenuItem<Empresa>> _data = [];
  String _selected = '';

  List<_ChartData> data = [];
  late TooltipBehavior _tooltip;
  late HashMap<String,int> dados;

  Color clOK = HexColor(Constants.blue);
  Color clFALHA = HexColor(Constants.red);

  searchEmpresa? widgetSearchEmpresa;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        initialDatePickerMode: DatePickerMode.day,
        initialEntryMode: DatePickerEntryMode.calendar,
        context: context,
        initialDate: minDate,
        firstDate: minDate.subtract(Duration(days:180)),
        lastDate: minDate,
        builder: (BuildContext? context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: HexColor(Constants.red),
              colorScheme: ColorScheme.light(primary: HexColor(Constants.red)),
              buttonTheme: ButtonThemeData(
                  textTheme: ButtonTextTheme.primary
              ),
            ),
            child: child!,
          );
        }
    );
    if (pickedDate != null && pickedDate != minDate)
      setState(() {
        initDate = pickedDate;
        txt.text = df.format(initDate);
        dtParam1 = dbFormat.format(initDate);
        getData();
      });
  }

  Future<void> _selectDate2(BuildContext context) async {
    final DateTime? pickedDate2 = await showDatePicker(
        context: context,
        initialDate: initDate,
        firstDate: initDate,
        lastDate: minDate,
        builder: (BuildContext? context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: HexColor(Constants.red),
              colorScheme: ColorScheme.light(primary: HexColor(Constants.red)),
              buttonTheme: ButtonThemeData(
                  textTheme: ButtonTextTheme.primary
              ),
            ),
            child: child!,
          );
        }
    );
    if (pickedDate2 != null && pickedDate2 != minDate)
      setState(() {
        endDate = pickedDate2;
        txt2.text = df.format(endDate);
        dtParam2 = dbFormat.format(endDate);
        var i = txt.text;
        var j = txt2.text;
        getData();
      });
  }

  void setSelectedEmpresa(Empresa e){
    this.empSel = e;
  }

  Future<Null> getData() async{
    if(!mounted) return;

    setState(() {
      //loading = true;
    });
    String urlApi = "";
    var ssl = false;
    var responseData = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    //empSel = widgetSearchEmpresa.state.empSel;

    if(widget.user!["tipo"]=="C")
      urlApi = Constants.urlEndpoint + "alert/zabbix/" +
          empSel.id!+ "/" + dtParam1 + "/" + dtParam2;
    //urlApi = Constants.urlEndpoint+"alert/consultor/"+widget.user['id'].toString()+"/zabbix/"+dtParam1+"/"+dtParam2;
    else
    if(widget.user!["tipo"]=="T"){
      urlApi = Constants.urlEndpoint + "alert/zabbix/" +
          widget.user!['empresas'][0]['id'].toString() + "/" + dtParam1 + "/" + dtParam2;
    }else {
      urlApi = Constants.urlEndpoint + "alert/zabbix/" +
          widget.user!['company_id'].toString() + "/" + dtParam1 + "/" + dtParam2; //é Diretor!
    }

    print("****URL API: ");
    print(urlApi);
    print("**********");

    String basicAuth = "Bearer "+widget.user!["token"];

    Map<String, String> h = {
      "Authorization": basicAuth,
    };
    try {
      if(ssl){
        var client = HttpsClient().httpsclient;
        responseData = await client.get(Uri.parse(urlApi), headers: h).timeout(
            Duration(seconds: 5), onTimeout: _onTimeout);
      }else {
        responseData = await http.get(Uri.parse(urlApi), headers: h).timeout(
            Duration(seconds: 5), onTimeout: _onTimeout);
      }

      if (responseData.statusCode == 200) {
        String source = Utf8Decoder().convert(responseData.bodyBytes);
        print("zabbix.body "+source);
        final dataJ = jsonDecode(source);
        data = [];
        dados = new HashMap<String,int>();
        setState(() {
          listModel.clear();
          for (Map<String,dynamic> i in dataJ) {
            var alert = AlertData.fromJson(i);
            if(widget.aid!=null && isConsultor){
              if(alert.id == widget.aid)
                listModel.add(alert);
            }else {
              listModel.add(alert);
            }
            if(alert.zstatus==null)alert.zstatus="OK";
            if(!dados.containsKey(alert.zstatus)){
              dados.putIfAbsent(alert.zstatus!, () => 1);
            }else{
              dados.update(alert.zstatus!, (value) => value+1);
            }
          }
          //loading = false;
          //widgetSearchEmpresa.state.empSel = empSel;
        });
        //dados.forEach((k,v) => data.add(_ChartData(k, v)));
        dados.forEach((k,v) {
          if(k == "OK")
            data.add(_ChartData(k, v, clOK));
          if(k == "FALHA")
            data.add(_ChartData(k, v, clFALHA));
        });
      } else {
        if(responseData.statusCode == 401) {
          Message.showMessage("As suas credenciais não são mais válidas...");
          setState(() {
            listModel = [];
            data = [];
            loading=false;
          });
        }
        loading = false;
      }
    }catch(error, exception){
      print("Zabbix.Erro : $error > $exception ");
    }
    //print(">>>>"+widgetSearchEmpresa.state.empSel.toString());
  }


  FutureOr<http.Response> _onTimeout(){
    http.Response r = http.Response('Timeout',403);

    setState(() {
      loading=false;
      print("não foi possível conectar em 8sec");
    });
    return r;
  }

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

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    firstDate = minDate.subtract(Duration(days: 30));
    txt.text = df.format(firstDate);
    txt2.text = df.format(minDate);
    dtParam1 = dbFormat.format(firstDate);
    dtParam2 = dbFormat.format(minDate);

    if(widget.user!["tipo"]=="C") {
      isConsultor = true;
    }else {
      getData();
    }

    if(widget.eid!=null) {
      firstDate = minDate.subtract(Duration(days:2));
      dtParam1 = dbFormat.format(firstDate);
      Empresa e = Empresa(widget.eid,"");
      setSelectedEmpresa(e);
      getData();
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
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "zabbix");
    try {
      widgetSearchEmpresa =
          searchEmpresa(onchangeF: () => getData(), context: context,width: MediaQuery.of(context).size.width*0.95,notifyParent: setSelectedEmpresa,);
    }catch(e){
      print("erro searchEmpresa..."+e.toString());
    }
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
        body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('zabbix',widget.user!,textTheme,(width*0.6)),
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child:
      Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: [
                headerAlertas(_scaffoldKey, widget.user!, context, width, 200, "Alertas Zabbix"),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top:170),
                  child: (isConsultor?widgetSearchEmpresa:SizedBox(height: 1,)),
                  //child: (isConsultor?empresasToShow():SizedBox(height: 1,)),
                )
              ],
            ),
          rangeDate(),
          graph(context),
          _body()
        ],
     )
    );
  }

  Widget _body(){
    return
    Expanded(child:     SingleChildScrollView(
      child: criaTabela(),
    ));
  }

  Widget rangeDate(){
    return Container(
        height: 58,
        margin: EdgeInsets.only(left:6.0,right: 6.0, top:10.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color:HexColor(Constants.red),width:5),
            right: BorderSide(color:HexColor(Constants.red),width:5),
          ),
          color:HexColor(Constants.firtColumn),
        ),
        padding: EdgeInsets.zero,
        child:
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                padding: EdgeInsets.only(right: 10,left: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 10,),
                    SizedBox(height: 17,),
                    Text(
                      'Período:',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: HexColor(Constants.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    //SizedBox(width:15,),
                  ],
                )
            ),
            Spacer(),
            Container(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                width: 125,
                child:
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(height: 1,),
                      Text("De",style: TextStyle(color:HexColor(Constants.blue),fontSize: 9),textAlign: TextAlign.start),
                      TextField(
                        enableInteractiveSelection: false,
                        controller: txt,
                        readOnly: true,
                        style: TextStyle(color: HexColor(Constants.blue),fontSize: 12),
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: Colors.white,filled: true,
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.calendar_month,color:HexColor(Constants.blue),size: 16,),
                          prefixIconConstraints: BoxConstraints(
                              maxWidth: 18,
                              maxHeight: 18
                          ),
                          suffixIcon:  IconButton(
                            icon: Icon(Icons.keyboard_arrow_down,color:HexColor(Constants.red), size:16),
                            onPressed: ()=>_selectDate(context),
                          ),
                          suffixIconConstraints: BoxConstraints(
                              maxWidth: 22,
                              maxHeight: 22
                          ),
                        ),
                      )
                    ])
            ),
            SizedBox(width: 4,),
            Container(
                width: 125,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(height: 1,),
                    Text("Até",style: TextStyle(color:HexColor(Constants.blue),fontSize: 9),textAlign: TextAlign.start,),
                    TextField(
                      enableInteractiveSelection: false,
                      readOnly: true,
                      controller: txt2,
                      style: TextStyle(color: HexColor(Constants.blue),fontSize: 12),
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        isDense: true,
                        //contentPadding: EdgeInsets.symmetric(vertical: 8),
                        fillColor: Colors.white,filled: true,
                        border: InputBorder.none,
                        prefix: Icon(Icons.calendar_month,color:HexColor(Constants.blue),size: 14,),
                        prefixIconConstraints: BoxConstraints(
                            maxWidth: 18,
                            maxHeight: 18
                        ),
                        suffixIcon:  IconButton(
                          icon: Icon(Icons.keyboard_arrow_down,color:HexColor(Constants.red),size:16),
                          onPressed: ()=>_selectDate2(context),
                        ),
                        suffixIconConstraints: BoxConstraints(
                            maxWidth: 22,
                            maxHeight: 22
                        ),
                      ),
                    )
                  ],
                )
            )
          ],
        ));
  }

  criaTabela() {
    return listModel.isNotEmpty?Table(
      defaultColumnWidth: FractionColumnWidth(.33),
      border: TableBorder(
        horizontalInside: BorderSide(
          color: HexColor(Constants.grey),
          style: BorderStyle.solid,
          width: 8.0,
        ),
      ),
      children: [
        _criarLinhaTable("Título, Data, Severidade",0,"-1"),
        for (int i = 0; i < listModel.length; i++)
          _criarLinhaTable(listModel[i].title!+","+listModel[i].data!+","+listModel[i].zstatus!,(i+1),listModel[i].id!),
      ],
    ):SizedBox(width: 1,);
  }


  _criarLinhaTable(String listaNomes,int index,String id) {
    List<String> itens = listaNomes.split(",");

    return TableRow(
      decoration: BoxDecoration(
            color:(index>0?HexColor(Constants.firtColumn):HexColor(Constants.grey)),
      ),
      children: [
        for(int i=0;i<itens.length;i++)
          (index>0?rowContent(itens[i], i, (itens.length-1), index,id):rowHeather(itens[i], i, index, id))
      ]
    );
  }

  Widget rowHeather(String columnValue, int column, int index,id){
    return GestureDetector(
      child:
      Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              color: HexColor(Constants.grey)
          ),
          padding: (column>1?EdgeInsets.only(left:2.0,right: 2.0):EdgeInsets.only(right: 2.0)),
          child: Text(
              columnValue,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 16.0,
                color: HexColor(Constants.red),
                fontWeight: FontWeight.bold,
              )
          ),
          margin: EdgeInsets.only(bottom:5.0)
      ),
      onTap: (){
        print("Indice do alert: "+index.toString());
      },);
  }
  Widget rowContent(String columnValue, int column, int tam, int index,id){
    return GestureDetector(
      child:
          Container(
          height: 45,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color:(column<1?HexColor(Constants.red):Colors.transparent),width: (column<1?5:0)),
              right: BorderSide(color:(column==tam?HexColor(Constants.red):Colors.transparent),width: (column==tam?5:0)),
            )
          ),
          child:
      Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color:(column<1?HexColor(Constants.firtColumn):Colors.white)
        ),
        padding: EdgeInsets.all(4.0),
        margin: (column>0?EdgeInsets.only(left:1.0,right: 1.0):EdgeInsets.only(right: 1.0)),
        child:
            Text(
            columnValue,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 15.0,
              color: HexColor(Constants.blue),
              fontWeight: FontWeight.bold,
            )
            )
        )),
      onTap: (){
        print("Indice do alert: "+index.toString());
          showAlert(context,index-1);
      },);
  }

  Future<void> showAlert(BuildContext context,int index) async {
    AlertData d = listModel.elementAt(index);
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            content:
            Stack(
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //crossAxisAlignment: CrossAxisAlignment.,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text("Detalhes do Alert",style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red))),
                                Spacer(),
                                closePopup()
                              ]
                              ,),
                            SizedBox(height: 20,),
                            detalhes(d),
                          ]))
                ]
            ),
            actions: <Widget>[
            ],
          );
        });
  }

  Widget graph(BuildContext context) {
    return (data.isNotEmpty?Container(
        height: 250,
        width: 250,
        constraints: BoxConstraints(
          minHeight: 180,
          maxHeight: 180
        ),
        color:HexColor(Constants.grey),
        child:SfCircularChart(
          margin: EdgeInsets.zero,
            legend: Legend(isVisible: true),
            series: <PieSeries<_ChartData, String>>[
              PieSeries<_ChartData, String>(
                  //explode: true,
                  //explodeIndex: 0,
                  dataSource: data,
                  xValueMapper: (_ChartData data, _) => data.x,
                  yValueMapper: (_ChartData data, _) => data.y,
                  dataLabelMapper: (_ChartData data, _) => data.y.toString(),
                  pointColorMapper: (_ChartData data, _)=>data.color,
                  dataLabelSettings: DataLabelSettings(isVisible: true)),
            ]
        )
    ):SizedBox(width: 1,));
  }

  Widget detalhes(AlertData tech){
    return Card(
        elevation: 0,
        child:
        Container(
            width: 380,
            constraints: BoxConstraints(
              minHeight: 205,
              maxHeight: 300
            ),
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Column(children: [Text("Evento:",style:TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],),
                    Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tech.data!, style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red)))
                      ],)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                        child:
                        Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Text(tech.title!,style: TextStyle(color:HexColor(Constants.blue)),softWrap: true),
                            ])),
                  ],
                ),
                SizedBox(height: 15,),
                Row(
                  children: [Column(children: [Text("Descrição:",style:TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(child:
                    Text(tech.text!,style: TextStyle(color:HexColor(Constants.blue))))
                  ],
                ),
                SizedBox(height: 15,),
                Row(
                  children: [Column(children: [Text("Host:",style:TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: HexColor(Constants.red)))],),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(child:
                    Text((tech.zhost!=null?tech.zhost!:"-"),style: TextStyle(color:HexColor(Constants.blue))))
                  ],
                ),
                SizedBox(height: 15,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Status:",style:TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: HexColor(Constants.red)))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text((tech.zstatus!=null?tech.zstatus!:"-"),style: TextStyle(color:HexColor(Constants.blue)))
                  ],
                )
              ],
            )
        )
    );
  }

}
class _ChartData {
  _ChartData(this.x, this.y,this.color);
  final String x;
  final int y;
  final Color color;
}