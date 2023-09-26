// @dart=2.9
import 'dart:convert';

import 'package:app_maxprotection/screens/inner_zabbix.dart';
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
  final double width;
  final Function(Empresa) notifyParent;

  searchEmpresa({ this.onchangeF, this.context,this.width,this.notifyParent});

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
  DropdownButtonFormField<Empresa> drop;

  GlobalKey _dropdownButtonKey = GlobalKey();

  void openDropdown() {
    GestureDetector detector;
    void searchForGestureDetector(BuildContext element) {
      element.visitChildElements((element) {
        if (element.widget != null && element.widget is GestureDetector) {
          detector = element.widget;
          return false;

        } else {
          searchForGestureDetector(element);
        }

        return true;
      });
    }
    searchForGestureDetector(_dropdownButtonKey.currentContext);
    assert(detector != null);
    detector.onTap();
  }

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
      drop = new DropdownButtonFormField<Empresa>(
          iconSize: 0,
          value: empSel,
          key: _dropdownButtonKey,
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
              print("----"+newValue.id);
              empSel = newValue;
              _empSearch.setDefaultOpt(newValue);
              widget.notifyParent(newValue);
              widget.onchangeF!=null?widget.onchangeF():print("No Function Onchange...");
            });
          },
          items: _data
      );

 }


  Widget build(BuildContext context){
    double largura = widget.width-26;
    print("search.width: "+largura.toString());

    return Container(
      height: 40,
      //width: 300,
      width: largura,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(child: drop ,height: 38,width:largura-26,
              ),
                  Container(
                    height: 36,
                    width: 26,
                    alignment: Alignment.center,
                    padding:EdgeInsets.only(right: 5),
                    decoration: new BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: HexColor(Constants.red),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.keyboard_arrow_down,size: 26,color: Colors.white),
                      onPressed: openDropdown)
                  ),
            ],
          ),
        ],
      ),
    );
  }


}