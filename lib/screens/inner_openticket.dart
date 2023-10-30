import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app_maxprotection/model/ChamadoMp3.dart';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/utils/HttpsClient.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:app_maxprotection/widgets/searchempresa_wdt.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../model/Idbean.dart';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../utils/SharedPref.dart';
import '../utils/chart_bubble.dart';
import '../widgets/SeekBar.dart';
import '../widgets/WaveAudio.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/headerAlertas.dart';
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
          return (snapshot.hasData ? new OpenTicketPage(title: 'Abrir Chamado', user: snapshot.data as Map<String, dynamic>) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class OpenTicketPage extends StatefulWidget {

  OpenTicketPage({this.title,this.user}) : super();

  final String? title;
  final Map<String, dynamic>? user;

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
  Empresa? empSel;

  int pos = 0;
  double dbLevel = 0;
  double _mSubscriptionDuration = 0;
  String statusText = "Pronto para gravar";
  bool isComplete = false;
  bool isGravando = false;
  String? recordFilePath;

  String currentTime = "", endTime = "";
  double minDuration = 0, maxDuration = 0, currentDuration = 0;

  AudioPlayer _player = AudioPlayer();

  bool isLoading = false;
  bool isTecnico = false;
  String idTicket = "-1";

  searchEmpresa? searchEmpresaWdt;
  SeekBar? _seekBar;

  bool flag = true;
  late Stream<int> timerStream;
  late StreamSubscription<int> timerSubscription;

  String minutesStr = '00';
  String secondsStr = '00';
  String hoursStr = '00';

  Directory? appDirectory;

  WaveAudio? wave;

  Stream<int> stopWatchStream() {
    late StreamController<int> streamController;
    late Timer timer;
    Duration timerInterval = Duration(seconds: 1);
    int counter = 0;

    void stopTimer() {
      if (timer != null) {
        timer!.cancel();
        //timer = null;
        counter = 0;
        streamController!.close();
      }
    }

    void tick(_) {
      counter++;
      streamController!.add(counter);
      if (!flag) {
        stopTimer();
      }
    }

    void startTimer() {
      timer = Timer.periodic(timerInterval, tick);
    }

    streamController = StreamController<int>(
      onListen: startTimer,
      onCancel: stopTimer,
      onResume: startTimer,
      onPause: stopTimer,
    );

    return streamController.stream;
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  /**Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
              (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero)); **/

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

  Future<void> requestForPermission() async {
    await Permission.microphone.request();
  }


  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    _fabHeight = _initFabHeight;
    empSel = null;
  }

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  void updateState(double pos){
    _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
  }

  void setSelectedEmpresa(Empresa e){
    this.empSel = e;
  }

  @override
  Widget build(BuildContext context) {
    Usuario usr = Usuario.fromSharedPref(widget.user!);
    usr.empresas.add(_empSearch.defaultValue);
    _empSearch.setOptions(usr.empresas);
    empSel = _empSearch.defaultOpt;

    isTecnico = (usr.tipo=="T"?true:false);
    /**if(_empSearch.lstOptions.length <3)
      empSel = _empSearch.lstOptions.elementAt(0);
    print("empSel...."+empSel.name); **/

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    double width = MediaQuery.of(context).size.width;
    _panelHeightOpen = MediaQuery.of(context).size.height * .25;
    _fcmInit.configureMessage(context, "elastic");

    searchEmpresaWdt = searchEmpresa(context: context,onchangeF: null,width: width*0.95,notifyParent: setSelectedEmpresa,);

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(Constants.grey),
        body: getMain(width),
        drawer:  Drawer(
          child: SliderMenu('openticket',widget.user!,textTheme,(width*0.5)),
        )
    );
  }

  Widget getMain(double width){
    return SafeArea(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
      Stack(
      children: [
          headerAlertas(_scaffoldKey, widget.user!, context, width,200, "Abrir chamados por voz"),
          Positioned(
          child: Container(width:width,alignment:Alignment.center,child: searchEmpresaWdt),
        top:175,
      ),
        _body(width)
        ])],
      ),
    );
  }

  Widget _body(double width){
    return Container(
        padding:  EdgeInsets.only(top: 250),
      child: Column(
        children: [
          recButton(),
          SizedBox(height: 13,),
          Text("$hoursStr.$minutesStr.$secondsStr",style:TextStyle(fontWeight:FontWeight.bold,fontSize: 24)),
          SizedBox(height: 13,),
          if(isComplete && recordFilePath!=null)
            wave = WaveAudio(
            path: recordFilePath,
            isSender: true,
            appDirectory: appDirectory,
          ),
          SizedBox(height: 24,),
          controlBar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [isLoading? CircularProgressIndicator(color: HexColor(Constants.red)):SizedBox(height: 1,)],
          )
        ],
      )
    );
  }

  void startCronometer(){
    timerStream = stopWatchStream();
    timerSubscription = timerStream.listen((int newTick) {
      setState(() {
        hoursStr = ((newTick / (60 * 60)) % 60)
            .floor()
            .toString()
            .padLeft(2, '0');
        minutesStr = ((newTick / 60) % 60)
            .floor()
            .toString()
            .padLeft(2, '0');
        secondsStr =
            (newTick % 60).floor().toString().padLeft(2, '0');
      });
    });
  }
  void stopCronometer(){
    timerSubscription.cancel();
    //timerStream = null;
    setState(() {
      hoursStr = '00';
      minutesStr = '00';
      secondsStr = '00';
    });
    }
  Widget recButton(){
    return GestureDetector(
        child:
            Container(
                decoration: new BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("images/mic.png"),
                      fit: BoxFit.fill
                    )),
                alignment: Alignment.center,
                height: 180,
                width: 180,
                child: !isGravando? Icon(Icons.mic,size: 62, color: Colors.white,) : Icon(Icons.mic_off,size: 62, color: Colors.white,)
            ),
    onTap: (){
          print("Gravando? "+isGravando.toString());
          if(!isGravando){
            startRecord();
            //incrementTick();
          }else{
            stopCronometer();
            stopRecord();
          }
      }
          );
  }

  Widget controlBar(){
    return Container(
      width: 400,
      padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/controlbg.png"),
            //fit: BoxFit.fill
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
        SizedBox( //<-- SEE HERE
            width: 30,
            height: 30,
            child: FittedBox(
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {delete();},
                  child: Icon(
                    Icons.close,
                    size: 36,
                    color: HexColor(Constants.red),
                  ),
                )))]),
            Column(
                        children: [CircleAvatar(
                          backgroundColor: HexColor(Constants.red),
                          radius: 28,
                          child: IconButton(
                            icon:  isComplete? Icon(Icons.play_arrow): Icon(Icons.stop),
                            iconSize: 24,
                            color: Colors.white,
                            onPressed: () {
                              isComplete ? WaveAudio.state!.controller!.startPlayer(
                                finishMode: FinishMode.pause,
                              ):WaveAudio.state!.controller!.pausePlayer();
                                  //play() :
                              //pauseRecord();
                            },
                          ),
                        )]),
            Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                SizedBox( //<-- SEE HERE
                    width: 30,
                    height: 30,
                    child: FittedBox(
                        child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          onPressed: () {abrirChamado();},
                          child: Icon(
                            Icons.check,
                            size: 36,
                            color: HexColor(Constants.blue),
                          ),
                        )))]
            )
          ],
        )
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

  Future<void> startRecord() async {
    setState(() {
      isGravando=true;
      isComplete=false;
      if(searchEmpresaWdt!.state!=null)
      empSel = searchEmpresaWdt!.state!.empSel;
    });
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      if(empSel!=null && empSel!.id !="0") {
        startCronometer();
        print("Recording...");
        recordFilePath = await getFilePath();
        RecordMp3.instance.start(recordFilePath!, (type) {
          print("Record error--->$type");
          setState(() {
            print('startRecording...');
          });
        });
      }else{
        setState(() {
          isGravando=false;
          isComplete=false;
        });
        Message.showMessage("Selecione a Empresa para qual deseja abrir o chamado!");
        return;
      }
    } else {
      statusText = "Permissão ao microfone desativada";
    }
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Gravando...";
        setState(() {
          print('startRecord...');
        });
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
      }
    }
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    print("stopRecord....");
    setState(() {
      isComplete = true;
      isGravando = false;
    });
    if (s) {
      statusText = "Gravação Finalizada";
      setState(() {
        _player.setFilePath(recordFilePath!);
      });
    }
  }

  void abrirChamado(){
    if(!isGravando && recordFilePath!=null) {
      if (isTecnico) {
        _OpenTicket(widget.user!["id"]);
      } else {
        _asyncFileUpload(widget.user!["id"]);
      }
    }else{
      Message.showMessage("Não é possível abrir o chamado sem um aúdio completo.");
    }
  }

  _OpenTicket(String text) async{
    setState(() {
      isLoading=true;
    });

    String basicAuth = "Bearer "+widget.user!["token"];

    var ssl = false;
    var response = null;

    if(Constants.protocolEndpoint == "https://")
      ssl = true;

    Map<String, String> h = {
      "Authorization": basicAuth,
    };

    Map params = {
      'cliente': text,
      'org' : empSel!.id,
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
      if(response.statusCode == 401) {
        Message.showMessage("As suas credenciais não são mais válidas...");
      }
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

    String basicAuth = "Bearer "+widget.user!["token"];

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
    File file = File(recordFilePath!);

    print("arquivo..."+recordFilePath!);

    if(ssl){
      Dio dio = HttpsClient().dioClient;

      var len = await file.length();

      var formData = FormData.fromMap({
        "id":text,
        "empresa":empSel!.name,
        "file":await multipart.MultipartFile.fromFile(recordFilePath!,filename:'file.mp3')
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
      request.fields["empresa"] = empSel!.name;
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

    print("response.;..."+responseString);

    final data = jsonDecode(responseString);
    ChamadoMp3 cmp3 = ChamadoMp3.fromJson(data);
    if(cmp3!=null && cmp3.name!=null && cmp3.size!>0){
      Message.showMessage("Chamado enviado para servidor.\nEm breve entrará listagem da empresa.");
      delete();
      Future.delayed(const Duration(seconds: 1), () {
        goBack();
      });
    }else{
      Message.showMessage("Erro ao enviar o chamado para o servidor.\nPor favor entre em contato com nosso suporte.");
    }
  }

  goBack(){
    Navigator.of(context).maybePop(context).then((value) {
      if (value == false) {
        Navigator.pushReplacement(
            context,
            FadePageRoute(
              builder: (ctx) => HomePage(),
            ));
      }
    });
  }
  _updateTicket() async{
    setState(() {
      isLoading=true;
    });


    String basicAuth = "Bearer "+widget.user!["token"];

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
    File file = File(recordFilePath!);

    print("updateTicket...arquivo..."+recordFilePath!);

    if(ssl){
      Dio dio = HttpsClient().dioClient;

      var len = await file.length();

      var formData = FormData.fromMap({
        "idticket":idTicket,
        "file":await multipart.MultipartFile.fromFile(recordFilePath!,filename:'file.mp3')
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
          "Chamado ID "+idTicket+" enviado para servidor.\nEm breve entrará listagem da empresa.");
      delete();
      Future.delayed(const Duration(seconds: 1), () {
        goBack();
      });
    }

    idTicket="-1";
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    print("resumeRecord....");
    if (s) {
      statusText = "Gravando...";
      setState(() {
        //textDuration = format();
        isComplete = true;
      });
    }
  }

  void play() async{
    print("playRecord....");
    if (recordFilePath != null && File(recordFilePath!).existsSync()) {
      _player.setFilePath(recordFilePath!);
      _player.play();
      setState(() {
        isComplete=false;
      });
    }
  }

  void delete(){
    print("deleteRecord....");
    File f = File(recordFilePath!);
    if(f!=null){
      f.deleteSync(recursive: true);
      recordFilePath = null;
      statusText = "Gravação apagada";
    }
    setState(() {
      recordFilePath = null;
      isComplete=false;
    });
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    appDirectory = storageDirectory;
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }
}