//@dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/SharedPref.dart';
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
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


void main() => runApp(new InnerZabbix());

class InnerZabbix extends StatelessWidget {

  static const routeName = '/zabbix';
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
          home: new ZabbixPage(title: 'Alertas Zabbix', user: snapshot.data),
          ) : CircularProgressIndicator());
          },
          ),
    );
  }
}

class ZabbixPage extends StatefulWidget {
  ZabbixPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _ZabbixPageState createState() => new _ZabbixPageState();
}

class _ZabbixPageState extends State<ZabbixPage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  DateTime minDate = DateTime.now();
  DateTime firstDate;
  DateTime initDate,endDate;

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

  Empresa empSel;

  static List<DropdownMenuItem<Empresa>> _data = [];
  String _selected = '';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime pickedDate = await showDatePicker(
        initialDatePickerMode: DatePickerMode.day,
        initialEntryMode: DatePickerEntryMode.calendar,
        context: context,
        initialDate: minDate,
        firstDate: minDate.subtract(Duration(days:15)),
        lastDate: minDate,
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: HexColor(Constants.red),
              accentColor: HexColor(Constants.red),
              colorScheme: ColorScheme.light(primary: HexColor(Constants.red)),
              buttonTheme: ButtonThemeData(
                  textTheme: ButtonTextTheme.primary
              ),
            ),
            child: child,
          );
        }
    );
    if (pickedDate != null && pickedDate != minDate)
      setState(() {
        initDate = pickedDate;
        txt.text = df.format(initDate);
        dtParam1 = dbFormat.format(initDate);
      });
  }

  Future<void> _selectDate2(BuildContext context) async {
    final DateTime pickedDate2 = await showDatePicker(
        context: context,
        initialDate: initDate,
        firstDate: initDate,
        lastDate: minDate,
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: HexColor(Constants.red),
              accentColor: HexColor(Constants.red),
              colorScheme: ColorScheme.light(primary: HexColor(Constants.red)),
              buttonTheme: ButtonThemeData(
                  textTheme: ButtonTextTheme.primary
              ),
            ),
            child: child,
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
        if(!isConsultor)
          getData();
      });
  }

  Future<Null> getData() async{

    if(!mounted) return;

    setState(() {
      loading = true;
    });
    String urlApi = "";

    /**
     * @GetMapping(value="alert/consultor/{id}/{tipo}/{init}/{fim}")
     */
    print('getData...: $dtParam1 - $dtParam2');


    if(widget.user["tipo"]=="C")
      urlApi = Constants.urlEndpoint + "alert/zabbix/" +
          empSel.id+ "/" + dtParam1 + "/" + dtParam2;
      //urlApi = Constants.urlEndpoint+"alert/consultor/"+widget.user['id'].toString()+"/zabbix/"+dtParam1+"/"+dtParam2;
    else
      if(widget.user["tipo"]=="T"){
        urlApi = Constants.urlEndpoint + "alert/zabbix/" +
            widget.user['empresas'][0]['id'].toString() + "/" + dtParam1 + "/" + dtParam2;
      }else {
        urlApi = Constants.urlEndpoint + "alert/zabbix/" +
            widget.user['id'].toString() + "/" + dtParam1 + "/" + dtParam2;
      }

    print("****URL API: ");
    print(urlApi);
    print("**********");

    try {
      final responseData = await http.get(Uri.parse(urlApi)).timeout(
          Duration(seconds: 5));
      if (responseData.statusCode == 200) {
        String source = Utf8Decoder().convert(responseData.bodyBytes);
        print("zabbix.body "+source);
        final data = jsonDecode(source);
        setState(() {
          listModel.clear();
          for (Map i in data) {
            //var ent = i["company"];
            var alert = AlertData.fromJson(i);
            //alert.setEmpresa(ent["name"]);
            listModel.add(alert);
          }
          loading = false;
        });
      } else {
        loading = false;
      }
    }catch(error, exception){
      print("Zabbix.Erro : $error > $exception ");
    }
  }

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

  void initState() {
    firstDate = minDate.subtract(Duration(days: 2));
    txt.text = df.format(firstDate);
    txt2.text = df.format(minDate);
    dtParam1 = dbFormat.format(firstDate);
    dtParam2 = dbFormat.format(minDate);

    if(widget.user["tipo"]=="C") {
      isConsultor = true;
      loadData();
    }else {
      getData();
    }
    super.initState();
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
          body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        ),
        drawer:  Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: SliderMenu('zabbix',widget.user,textTheme),
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        children: <Widget>[
          _header(width),
          (isConsultor?empresasToShow():SizedBox(height: 1,)),
          rangeDate(),
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
                    'Alertas Zabbix',
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

  Widget rangeDate(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 12,),
        Text(
          'Período:',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 14.0,
            color: HexColor(Constants.red),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 3,),
        Container(
            decoration: BoxDecoration(
              color: HexColor(Constants.red),
              borderRadius: BorderRadius.circular(10.0),
            ),
            width: 137,
            child:TextField(
              enableInteractiveSelection: false,
              controller: txt,
              readOnly: true,
              style: TextStyle(color: HexColor(Constants.red)),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal:2),
                fillColor: Colors.white,filled: true,
                border: InputBorder.none,
                suffixIcon:  IconButton(
                  icon: Icon(Icons.arrow_drop_down),
                  onPressed: ()=>_selectDate(context),
                ),
              ),
            )),
        SizedBox(width: 5,),
        Container(
            width: 137,
            decoration: BoxDecoration(
              color: HexColor(Constants.red),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child:TextField(
              enableInteractiveSelection: false,
              readOnly: true,
              controller: txt2,
              style: TextStyle(color: HexColor(Constants.red)),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal:2),
                fillColor: Colors.white,filled: true,
                border: InputBorder.none,
                suffixIcon:  IconButton(
                  icon: Icon(Icons.arrow_drop_down),
                  onPressed: ()=>_selectDate2(context),
                ),
              ),
            ))
      ],
    );
  }

  Widget listView(){
    return ListView(
      children: <Widget>[
        for (int i = 0; i < listModel.length; i++)
          getAlert(listModel[i])
          //getAlert(listModel[i].title, listModel[i].data, listModel[i].text, listModel[i].empresa)
      ],
    );
  }

  Widget getAlert(AlertData tech){
    Color cl = Colors.green;
    var urg = tech.status;

    //OK (default), Not classified, Information, Warning, Average, High or Disaster

    if(tech.status=="OK" || tech.status=="Not classified")
      cl = Colors.green;
    if(tech.status=="Warning" || tech.status=="Information")
      cl = Colors.yellow;
    if(tech.status=="High" || tech.status=="Disaster")
      cl = Colors.red;

    return Card(
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
                  children: [Text("#", style: TextStyle(fontWeight: FontWeight.w500,color: HexColor(Constants.red)))],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Expanded(child: Text(tech.title,style: TextStyle(fontSize: 16.0)))],
                ),
                SizedBox(height: 5,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(tech.text,style: TextStyle(fontWeight: FontWeight.w500)),
                    )
                    ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text(tech.empresa)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text((tech.status!=null?tech.status:"-"),style: TextStyle(fontWeight: FontWeight.w500))],
                )
              ],

            )
        )
    );
  }
  Widget getAlert_(String title, String date, String event, String empresa){
    return Card(
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(0),
              minLeadingWidth: 10.0,
              title: Column(mainAxisAlignment:MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,children:[Text(title, style: TextStyle(fontWeight: FontWeight.w500)),Text(empresa, style: TextStyle(fontSize: 16))]),
              subtitle: Text(event),
              leading: Container(
                width: 12,
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