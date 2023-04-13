// @dart=2.10
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app_maxprotection/model/ChamadoMp3.dart';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/utils/HttpsClient.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/Idbean.dart';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/SharedPref.dart';
import '../widgets/SeekBar.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import '../widgets/top_container.dart';
import 'home_page.dart';

import 'package:dio/src/multipart_file.dart' as multipart;

void main() => runApp(InnerOpenTicket());

class InnerOpenTicket extends StatelessWidget {

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
            home: new OpenTicketPage(title: 'Abrir Chamado', user: snapshot.data),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class OpenTicketPage extends StatefulWidget {

  OpenTicketPage({Key key, this.title,this.user}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<OpenTicketPage> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;
  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  EmpresasSearch _empSearch = new EmpresasSearch();
  Empresa empSel;

  int pos = 0;
  double dbLevel = 0;
  double _mSubscriptionDuration = 0;
  String statusText = "Pronto para gravar";
  bool isComplete = false;
  String recordFilePath;

  String currentTime = "", endTime = "";
  double minDuration = 0, maxDuration = 0, currentDuration = 0;


  final _player = AudioPlayer();

  bool isLoading = false;
  bool isTecnico = false;
  String idTicket = "-1";

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
              (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));



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

    isTecnico = (usr.tipo=="T"?true:false);
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
          child: SliderMenu('openticket',widget.user,textTheme),
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
                    'Abrir Chamados por Voz',
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
      height: 180,
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
        Row(children: [
          ElevatedButton.icon(
            icon: (RecordMp3.instance.status == RecordStatus.RECORDING?Icon(Icons.fiber_manual_record): Icon(Icons.stop)),
            onPressed: (RecordMp3.instance.status == RecordStatus.RECORDING ? stopRecord : startRecord),
            label: Text(RecordMp3.instance.status == RecordStatus.RECORDING ? 'Parar' : 'Gravar'),
            style: ElevatedButton.styleFrom(
                  primary: HexColor(Constants.red)
              )
          ),
          SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 20,
          ),
          //Text('Pos: $pos  dbLevel: ${((dbLevel * 100.0).floor()) / 100}'),
        ]),
        Text(statusText,style: TextStyle(color: HexColor(Constants.red),fontWeight: FontWeight.w500),),
        StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return SeekBar(
              duration: positionData?.duration ?? Duration.zero,
              position: positionData?.position ?? Duration.zero,
              bufferedPosition:
              positionData?.bufferedPosition ?? Duration.zero,
              onChangeEnd: _player.seek,
            );
          },
        ),
        Row(
          children: [
            (isComplete && recordFilePath!=""? makeControles()
        : SizedBox(height: 1,))

          ],
        ),
      ]),
      //),
      //],
    );}

    Widget makeControles(){
    return Row(
      children: [
        ElevatedButton(
          onPressed: abrirChamado,
          child: Text('Abrir Chamado'),
            style: ElevatedButton.styleFrom(
                primary: HexColor(Constants.red)
            )
        ),
        SizedBox(width: 2,),
        ElevatedButton.icon(
          icon: Icon(Icons.play_arrow),
          onPressed: play,
          label: Text('Play'),
          style: ElevatedButton.styleFrom(
            primary: HexColor(Constants.red)
          )
        ),
        SizedBox(width: 2,),
        ElevatedButton.icon(
          icon: Icon(Icons.delete_forever),
          onPressed: delete,
          label: Text('Delete'),
            style: ElevatedButton.styleFrom(
                primary: HexColor(Constants.red)
            )
        )
      ],
    );
    }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      if(empSel.id !="0") {
        statusText = "Recording...";
        recordFilePath = await getFilePath();
        isComplete = false;
        RecordMp3.instance.start(recordFilePath, (type) {
          statusText = "Record error--->$type";
          setState(() {});
        });
      }else{
        Message.showMessage("Selecione a Empresa para qual deseja abrir o chamado!");
        return;
      }
    } else {
      statusText = "Permissão ao microfone desativada";
    }
    setState(() {});
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Gravando...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
        setState(() {});
      }
    }
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "Gravação Finalizada";
      isComplete = true;

      setState(() {
      });
    }
  }

  void abrirChamado(){
    if(isTecnico){
      _OpenTicket(widget.user["id"]);
    }else {
      _asyncFileUpload(widget.user["id"]);
    }
  }

  _OpenTicket(String text) async{
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
      'descricao':'Abertura de chamado pelo SecurityApp'
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
        idTicket = mapResponse['id'].toString();
        await _updateTicket();
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

  _asyncFileUpload(String text) async{
    setState(() {
      isLoading=true;
    });

    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));
    var ssl = false;
    var request  = null;
    var response = null;
    var responseData = null;
    var responseString = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    await Future.delayed(Duration(seconds: 3));

    var url =Constants.urlEndpoint+'tech/upload';
    File file = File(recordFilePath);

    print("arquivo..."+recordFilePath);

    if(ssl){
      Dio dio = HttpsClient().dioClient;

      var len = await file.length();

      var formData = FormData.fromMap({
        "id":text,
        "empresa":empSel.name,
        "file":await multipart.MultipartFile.fromFile(recordFilePath,filename:'file.mp3')
      });

      response = await dio.post(url,
          data: formData,
          options: Options(headers: {
            Headers.contentLengthHeader: len,
            "Authorization": basicAuth,
          } // set content-length
          ));
      setState(() {
        isLoading=false;
      });
    }else {
      request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(h);
      //add text fields
      request.fields["id"] = text;
      request.fields["empresa"] = empSel.name;
      //create multipart using filepath, string or bytes
      var mp3 = await http.MultipartFile.fromPath("file", file.path);
      //add multipart to request
      request.files.add(mp3);
      response = await request.send();
      setState(() {
        isLoading=false;
      });
    }

    if(ssl){
      responseString = response.data;
    }else {
      responseData = await response.stream.toBytes();
      responseString = String.fromCharCodes(responseData);
    }

    final data = jsonDecode(responseString);
    ChamadoMp3 cmp3 = ChamadoMp3.fromJson(data);
    if(cmp3!=null && cmp3.name!=null && cmp3.size>0){
      Message.showMessage("Chamado enviado para servidor.\nEm breve entrará listagem da empresa.");
      delete();
    }else{
      Message.showMessage("Erro ao enviar o chamado para o servidor.\nPor favor entre em contato com nosso suporte.");
    }
  }

  _updateTicket() async{
    setState(() {
      isLoading=true;
    });

    String u = widget.user["login"]+"|"+widget.user["password"];
    String p = widget.user["password"];
    String basicAuth = "Basic "+base64Encode(utf8.encode('$u:$p'));
    var ssl = false;
    var request  = null;
    var response = null;
    var responseData = null;
    var responseString = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    var url =Constants.urlEndpoint+'tech/updateTicket';
    File file = File(recordFilePath);

    print("updateTicket...arquivo..."+recordFilePath);

    if(ssl){
      Dio dio = HttpsClient().dioClient;

      var len = await file.length();

      var formData = FormData.fromMap({
        "idticket":idTicket,
        "file":await multipart.MultipartFile.fromFile(recordFilePath,filename:'file.mp3')
      });

      response = await dio.post(url,
          data: formData,
          options: Options(headers: {
            Headers.contentLengthHeader: len,
            "Authorization": basicAuth,
          } // set content-length
          ));
      setState(() {
        isLoading=false;
      });
    }else {
      request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(h);
      //add text fields
      request.fields["idticket"] = idTicket;
      //create multipart using filepath, string or bytes
      var mp3 = await http.MultipartFile.fromPath("file", file.path);
      //add multipart to request
      request.files.add(mp3);
      response = await request.send();
      setState(() {
        isLoading=false;
      });
    }
    if(ssl){
      responseString = response.data;
    }else {
      responseData = await response.stream.toBytes();
      responseString = String.fromCharCodes(responseData);
    }
    print("resposta do update...."+responseString.toString());
    if(responseString.toString().contains("Erro")){
     Message.showMessage("Falha ao enviar arquivo de aúdio para Nuvem.\nEntre em contato com o nosso suporte.");
    }else {
      Message.showMessage(
          "Chamado enviado para servidor.\nEm breve entrará listagem da empresa.");
      delete();
    }
    
    idTicket="-1";
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Gravando...";
      setState(() {});
    }
  }

  void play() async{
    if (recordFilePath != null && File(recordFilePath).existsSync()) {
      _player.setFilePath(recordFilePath);
      _player.play();
      setState(() {});
    }
  }

  void delete(){
    File f = File(recordFilePath);
    if(f!=null){
      f.deleteSync(recursive: true);
      recordFilePath = "";
      statusText = "Gravação apagada";
    }
    setState(() {});
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }
}