// @dart=2.10
import 'package:flutter/material.dart';

import '../widgets/HexColor.dart';
import '../widgets/constants.dart';

class TicketSeach extends SearchDelegate{


  List<String> searchTerms;
  List<String> searchResult=[];
  Function f;

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

  TicketSeach(List<String> terms,Function ff){
    this.searchTerms = terms;
    this.f = ff;
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(onPressed: () {
      f("!");
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
                  f(item);
                  close(context, item);
                },
              ),
            );
          })),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
    /**searchTerms.sort((a, b) => a.toString().compareTo(b.toString()));

    List<String> matchQuery = [];
    for(var fruit in searchTerms)
    {
      if(fruit.toLowerCase().contains(query.toLowerCase()))
      {
        matchQuery.add(fruit);
      }
    }

    return ListView.builder(itemBuilder: (context,index){
      var result = matchQuery[index];
      return ListTile(title: Text(result),);
    },itemCount: matchQuery.length,);**/
  }
  
}