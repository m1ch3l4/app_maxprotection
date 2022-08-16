// @dart=2.10
import 'dart:io';

import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/AlertModel.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';


void main() => runApp(new InnerElastic());

class InnerElastic extends StatelessWidget {

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
            home: new ElasticPage(title: 'Alertas SIEM', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class ElasticPage extends StatefulWidget {
  ElasticPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _ElasticPageState createState() => new _ElasticPageState();
}

class _ElasticPageState extends State<ElasticPage> {

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime pickedDate = await showDatePicker(
        initialDatePickerMode: DatePickerMode.day,
        initialEntryMode: DatePickerEntryMode.calendar,
        context: context,
        initialDate: minDate,
        firstDate: minDate.subtract(Duration(days:30)),
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
        getData();
      });
  }

  Future<Null> getData() async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

    //TODO: aqui fazer a condicão se é consultour ou cliente
    if(widget.user["tipo"]=="C")
      urlApi = Constants.urlEndpoint+"alert/consultor/"+widget.user['id'].toString()+"/elastic/"+dtParam1+"/"+dtParam2;
    else
      urlApi = Constants.urlEndpoint+"alert/elastic/"+widget.user['id'].toString()+"/"+dtParam1+"/"+dtParam2;

    print("****URL API: ");
    print(urlApi);
    print("**********");

    final responseData = await http.get(Uri.parse(urlApi)).timeout(Duration(seconds: 5));    if(responseData.statusCode == 200){
      String source = Utf8Decoder().convert(responseData.bodyBytes);
      final data = jsonDecode(source);
      setState(() {
        for(Map i in data){
          var ent = i["company"];
          var alert = AlertData.fromJson(i);
          alert.setEmpresa(ent["name"]);
          listModel.add(alert);
        }
        loading = false;
      });
    }else{
      loading = false;
    }
  }


  void initState() {
    firstDate = minDate.subtract(Duration(days: 30));
    txt.text = df.format(firstDate);
    txt2.text = df.format(minDate);
    dtParam1 = dbFormat.format(firstDate);
    dtParam2 = dbFormat.format(minDate);
    getData();
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
          body: loading ? Center (child: CircularProgressIndicator()) : getMain(width),
        ),
        drawer:  Drawer(
          child: SliderMenu('elastic',widget.user,textTheme),
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
        children: <Widget>[
          _header(width),
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
                    widget.title,
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

  Widget getAlert(AlertData tech){
    Color cl = Colors.green;
    var urg = tech.status;

    if(tech.status=="LOW")
      cl = Colors.green;
    if(tech.status=="MEDIUM")
      cl = Colors.yellow;
    if(tech.status=="HIGH")
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
                      children: [Text("-",style: TextStyle(fontWeight: FontWeight.w500))],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Text(tech.empresa)],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text(tech.status,style: TextStyle(fontWeight: FontWeight.w500))],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text(tech.total)],
                    ),
                  ],

                )
            )
        );
  }

}