// @dart=2.9
import 'dart:convert';

import 'package:flutter/material.dart';


import '../model/empresa.dart';
import '../utils/EmpresasSearch.dart';
import '../utils/HexColor.dart';
import '../utils/Message.dart';
import 'constants.dart';

// ignore: must_be_immutable
class searchEmpresa extends StatefulWidget {

  final Function onchangeF;
  final BuildContext context;

  searchEmpresa({ this.onchangeF, this.context});

  _searchEmpresa state;

  _searchEmpresa createState() {
    state = _searchEmpresa();
    return state;
  }
}

class _searchEmpresa extends State<searchEmpresa>{
  static EmpresasSearch _empSearch = EmpresasSearch();
  Empresa empSel;

  static List<DropdownMenuItem<Empresa>> _data = [];

  void initState() {
    super.initState();
   loadData();
  }

  void loadData() {
      _data = [];
      setState(() {
      });
      //empSel = _empSearch.defaultOpt;
      for (Empresa bean in _empSearch.lstOptions) {
        if(!_data.contains(bean)){
        _data.add(
            new DropdownMenuItem(
                value: bean,
                child: Text(bean.name, overflow: TextOverflow.fade,)));}
      }
 }

  Widget build(BuildContext context){
    //loadData();
    return Container(
      height: 40,
      width: 300,
      margin: EdgeInsets.only(left:10,right:10, top:5, bottom:5),
      decoration: BoxDecoration(
        color: HexColor(Constants.red),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: HexColor(Constants.red),
            blurRadius: 1.0, // soften the shadow
            spreadRadius: 1.0, //extend the shadow
            offset: Offset(
              1.0, // Move to right 5  horizontally
              1.0, // Move to bottom 5 Vertically
            ),
          )
        ],
      ),
      padding: EdgeInsets.only(top:1,bottom: 1),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(child:
              DropdownButtonFormField<Empresa>(
                  iconSize: 0,
                  value: empSel,
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(top:2,left:10),
                      fillColor: Colors.white,filled: true,
                      hintStyle: TextStyle(color:HexColor(Constants.red),fontSize: 13),
                      border: new OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20.0),
                            topLeft: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                            topRight: Radius.circular(20.0)
                        ),
                      )),
                  isDense: true,
                  style: TextStyle(color: HexColor(Constants.red),fontStyle: FontStyle.italic),
                  onChanged: (Empresa newValue) {
                    setState(() {
                      empSel = newValue;
                      _empSearch.setDefaultOpt(newValue);
                      widget.onchangeF!=null?widget.onchangeF():print("No Function Onchange...");
                    });
                  },
                  items: _data
              )
                ,height: 38,width: 270,
              ),
              GestureDetector(
                  onTap: () {
                    print("teste....");
                  },
                  child: Container(
                    height: 36,
                    width: 28,
                    decoration: new BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: HexColor(Constants.red),
                      //border: Border.all(color:Colors.white,width: 1)
                    ),
                    child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 36,
                        color: Colors.white),
                  )),
            ],
          ),
        ],
      ),
    );
  }


}