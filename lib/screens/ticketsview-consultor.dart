// @dart=2.10
import 'package:app_maxprotection/screens/ticketlist-consultor.dart';
import 'package:app_maxprotection/utils/SharedPref.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';
import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/FCMInitialize-consultant.dart';
import '../utils/HexColor.dart';
import '../widgets/constants.dart';
import '../widgets/custom_route.dart';
import '../widgets/slider_menu.dart';
import 'home_page.dart';

class TicketsviewConsultor extends StatelessWidget {

  static const routeName = '/tickets';
  SharedPref sharedPref = SharedPref();

  /**
   * 0 - todos
   * 1 - Novo
   * 2 - Atendimento
   * 3 - Aguardando
   */
  final int tipo;

  TicketsviewConsultor(this.tipo);

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
            home: new TicketsPage(title: 'Tickets MovieDesk', user: snapshot.data, tipo:tipo),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }
}

class TicketsPage extends StatefulWidget {
  TicketsPage({Key key, this.title,this.user,this.tipo}) : super(key: key);

  final String title;
  final Map<String, dynamic> user;
  final int tipo;

  @override
  _TicketsPageState createState() => new _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  var loading = false;
  EmpresasSearch _empSearch = new EmpresasSearch();
  List<Empresa> lstEmpresa;
  List<Empresa> loaded = [];
  var novo = 0;
  var aguardando = 0;
  var atendimento = 0;
  int lastIndex = 0;
  bool ultimo = false;
  int tamanho = 10;
  int ultimoIndex = 0;
  
  FCMInitConsultor _fcmInit = new FCMInitConsultor();

  final ScrollController _controller = ScrollController();


  _onScroll() {
    if (_controller.offset >=
        _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange && !ultimo) {
      setState(() {
        loading = true;
      });
      lazyLoad();
    }
  }

  Future lazyLoad() async{
    lastIndex = loaded.length;
    if(lstEmpresa.elementAt(lastIndex)!=null) {
      await getData(lastIndex);

      setState(() {
        loaded.addAll(
            lstEmpresa.sublist(lastIndex, ultimoIndex)
        );
        loading = false;
      });
    }else{
      ultimo = true;
      setState(() {
        loading=false;
      });
    }
  }

  Future<Null> getData(int index) async{
    setState(() {
      loading = true;
    });
    String urlApi = "";

    var total = index+tamanho;

      for(var i=index;i<(index+tamanho);i++){
        if(lstEmpresa.asMap().containsKey(i)) {
          ultimoIndex = i;
          Empresa emp = lstEmpresa[i];
          emp.setNovo(0);
          emp.setAtendimento(0);
          emp.setAguardando(0);

          urlApi = Constants.urlEndpoint + "enterprise/stat/" + emp.id;

          final responseData = await http.get(Uri.parse(urlApi)).timeout(
              Duration(seconds: 3));

          if (responseData.statusCode == 200) {
            String source = Utf8Decoder().convert(responseData.bodyBytes);
            final data = jsonDecode(source);
            emp.setAguardando(data["aguardando"]);
            emp.setNovo(data["novos"]);
            emp.setAtendimento(data["atendimento"]);
            loading = false;
          } else {
            loading = false;
          }
        }else{
          ultimo = true;
        }
      }
    setState(() {
      loading=false;
    });
}

  void dispose(){
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    print("BACK BUTTON!"); // Do some stuff.
    return true;
  }

  void initState() {
    _controller.addListener(_onScroll);
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    lstEmpresa = _empSearch.lstOptions;
    lazyLoad();
    //getData(lastIndex);
  }

  @override
  Widget build(BuildContext context) {
    _fcmInit.configureMessage(context, "tickets");
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return new Scaffold(
      appBar: AppBar(title: Text(widget.title),
        backgroundColor: HexColor(Constants.red),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(FadePageRoute(
                builder: (context) => HomePage(),
              ));
            },
          )
        ],
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: SliderMenu('tickets',widget.user,textTheme),
      ),
      body:  Container(
        padding: EdgeInsets.fromLTRB(10,10,10,0),
        width: double.maxFinite,
        child: loading ? Center (child: CircularProgressIndicator()) : getMain(),
      ),
    );
  }
  Widget getMain(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        lazyListView()
        //listView(),
      ],
    );
  }

  Widget listView(){
    return Expanded(child: ListView(
      children: <Widget>[
        for(var i=0;i<lstEmpresa.length;i++)
          getAlert(lstEmpresa[i])
      ],
    ));
  }

  Widget lazyListView(){
    return Expanded(child:
    ListView.builder(
      controller: _controller,
      itemCount: loading ? loaded.length + 1 : loaded.length,
      itemBuilder: (context, index) {
        if (loaded.length == index)
          return Center(
              child: CircularProgressIndicator()
          );
        return getAlert(loaded[index]);
      },
    )
    );
  }

  Widget getAlert(Empresa emp){
    GestureDetector gd;
    //print("widget.tipo ");print(widget.tipo);
    //print("Empresa: ");print(emp.id);
    switch(widget.tipo){
      case 0:
        gd = GestureDetector(
            onTap: (){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketlistConsultor(emp,0), // <-- document instance
                  ));
            },
            child:
            Card(
                color: HexColor(Constants.grey),
                child: Container(
                    margin: EdgeInsets.all(10.0),
                    child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(emp.novo>0?"Novo":"",style:TextStyle(color: HexColor(Constants.red)))
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(child: Text(emp.name, overflow:TextOverflow.ellipsis,style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)))
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(emp.aguardando>0?"Aguardando":"",style:TextStyle(color: HexColor(Constants.red)))
                            ],
                          )
                        ]
                    )
                ))
        );
        break;
      case 1:
        gd = GestureDetector(
            onTap: (){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketlistConsultor(emp,1), // <-- document instance
                  ));
            },
            child:
            Card(
                color: HexColor(Constants.grey),
                child: Container(
                    margin: EdgeInsets.all(10.0),
                    child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(emp.novo>0?"Novo":"",style:TextStyle(color: HexColor(Constants.red)))
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(child: Text(emp.name, overflow:TextOverflow.ellipsis,style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)))
                            ],
                          )
                        ]
                    )
                ))
        );
        break;
      case 2:
        gd = GestureDetector(
            onTap: (){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketlistConsultor(emp,2), // <-- document instance
                  ));
            },
            child:
            Card(
                color: HexColor(Constants.grey),
                child: Container(
                    margin: EdgeInsets.all(10.0),
                    child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(emp.atendimento>0?"Atendimento":"",style:TextStyle(color: HexColor(Constants.red)))
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(child: Text(emp.name, overflow:TextOverflow.ellipsis,style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)))
                            ],
                          ),
                        ]
                    )
                ))
        );
        break;
      case 3:
        gd = GestureDetector(
            onTap: (){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketlistConsultor(emp,3), // <-- document instance
                  ));
            },
            child:
            Card(
                color: HexColor(Constants.grey),
                child: Container(
                    margin: EdgeInsets.all(10.0),
                    child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(emp.aguardando>0?"Aguardando":"",style:TextStyle(color: HexColor(Constants.red)))
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(child: Text(emp.name, overflow:TextOverflow.ellipsis,style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)))
                            ],
                          ),
                        ]
                    )
                ))
        );
        break;
    }
    return gd;
  }



}