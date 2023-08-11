// @dart=2.10
import 'package:app_maxprotection/screens/home_page.dart';
import 'package:app_maxprotection/screens/inner_messages.dart';
import 'package:app_maxprotection/screens/inner_noticias.dart';
import 'package:app_maxprotection/screens/inner_openticket.dart';
import 'package:app_maxprotection/screens/inner_pwd.dart';
import 'package:app_maxprotection/screens/inner_servicos.dart';
import 'package:app_maxprotection/screens/inner_user.dart';
import 'package:app_maxprotection/screens/inner_zabbix.dart';
import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:flutter/material.dart';

import '../screens/inner_elastic.dart';
import '../screens/ticketlist-consultor.dart';
import '../screens/ticketsview-consultor.dart';
import '../widgets/custom_route.dart';

class HomeSearchDelegate extends SearchDelegate{

  final bool isConsultor;

  List<String> searchTerms = ["zabbix","siem","tickets","senha","dados","abrir","falar","fale","leads","noticias","serviços"];

  Map<String,Route> searchScreen = {
    'zabbix':FadePageRoute(
      builder: (context) =>InnerZabbix(null, null),
    ),
    'siem': FadePageRoute(
      builder: (context) =>InnerElastic(null, null),
    ),
    'senha':FadePageRoute(
      builder: (context) =>InnerPwd(),
    ),
    'dados':FadePageRoute(
      builder: (context) =>InnerUser(),
    ),
    'abrir':FadePageRoute(
      builder: (context) =>InnerOpenTicket(),
    ),
    'falar':null,
    'fale':null,
    'leads':FadePageRoute(
      builder: (context) =>InnerMessages(4),
    ),
    'noticias':FadePageRoute(
      builder: (context) =>InnerNoticias(),
    ),
    'servicos':FadePageRoute(
      builder: (context) =>InnerServicos(),
    ),
  };

  HomeSearchDelegate(this.isConsultor) {
    searchScreen.putIfAbsent('tickets', () => FadePageRoute(
        builder: (context) =>(isConsultor?TicketsviewConsultor(0):TicketlistConsultor(null, 0))
    ));
  }

  List<String> searchResult=[];


  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(onPressed: () {
      close(context, null);
    }, icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    searchResult.clear();
    searchResult =
    searchTerms.where((element) => element.startsWith(query)).toList();

    return Container(
    margin: EdgeInsets.all(20),
    child: ListView(
    padding: EdgeInsets.only(top: 8, bottom: 8),
    scrollDirection: Axis.vertical,
    children: List.generate(searchResult.length, (index) {
    var item = searchResult[index];
    return Card(
      color: Colors.white,
      child: GestureDetector(
        child:
        Container(padding: EdgeInsets.all(16), child: Text(item,style: TextStyle(color: HexColor(Constants.red)),)),
        onTap: (){
          if(item!="fale"&&item!="falar")
            Navigator.of(context).push(searchScreen[item]);
          else
            MyHomePage.state.faleComDiretor(context);
        },
      ),
    );
    })),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    print("Build Suggestions......");
    return buildResults(context);
  }
  
}