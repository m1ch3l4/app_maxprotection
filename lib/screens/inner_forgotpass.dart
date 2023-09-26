//@dart=2.10
import 'package:app_maxprotection/api/ChangPassApi.dart';
import 'package:app_maxprotection/model/usuario.dart';
import 'package:app_maxprotection/utils/Message.dart';
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import '../widgets/RadialButton.dart';
import '../widgets/constants.dart';

class ForgotScreen extends StatefulWidget {
  static const routeName = '/forgot';

  ForgotScreenState createState() => ForgotScreenState();
}

class ForgotScreenState extends State<ForgotScreen>{

  final double _initFabHeight = 90.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 50.0;

  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  String login='';
  bool firstLogin = false;
  final loginCtrl = TextEditingController();

  double tam=0.0;
  int _value = -1;

  Map<String,int> radioValue = {"T":1,"C":2,"D":3};
  Map<int,String> userValue = {1:"T",2:"C",3:"D"};

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    //throw UnimplementedError();
    return buildForgotScrenn(context);
  }

  Widget buildForgotScrenn(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    tam = height;
    return
      Scaffold(
        resizeToAvoidBottomInset : false,
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/Fundo.png"),fit: BoxFit.cover),),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                width: width*0.9,
                child: _formUI(width,(height*0.75)),
              ),
              SizedBox(height: 80,),
              _footer(width, (height*0.25)),
            ],
          ),

        ),
        backgroundColor: Colors.transparent,
      )
    ;
  }



  Widget _formUI(double width, double height) {
    return Form(
        key: _key,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new TextFormField(
              controller: loginCtrl,
              cursorColor: HexColor(Constants.red),
              style: TextStyle(color: HexColor(Constants.red)),
              decoration: new InputDecoration(hintText: 'E-mail', hintStyle: TextStyle(color: HexColor(Constants.red)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                  ),
                  filled:true,
                  fillColor: Colors.white),
              validator: (value){
                String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                RegExp regExp = new RegExp(pattern);
                if(value==null || value.isEmpty){
                  return "Preencha o seu e-mail";
                }else {
                  if (!regExp.hasMatch(value)) {
                    return "Email inválido";
                  }
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              maxLength: 40,
            ),
            SizedBox(height: 5,),
            RadialButton(buttonText: "ENVIAR", width: width, onpressed: ()=>forgotPass()
                ),
          ],
        ));
  }

  forgotPass() async {
    List<Usuario> founded=[];
    String login = loginCtrl.value.text;

    String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);

    if(login!=null && regExp.hasMatch(login)){

      await ChangePassApi.checkLogin(login).then((value) => founded=value.result);
      if(founded.length>1){
        _value = radioValue[founded[0].tipo];
        AlertDialog alert;
        Widget cancelButton = FlatButton(
          child: Text("OK"),
          onPressed:  () {
            ChangePassApi.forgotPassTipo(login, userValue[_value]).then((value){
              Message.showMessage(value.result);
              Navigator.of(context, rootNavigator: true).pop('dialog');
            });
          },
        );
        alert = AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          title: Text("ATENÇÃO", style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red))),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(height: tam * 0.3, child:
                Column(children:[Text("Para qual tipo de usuário você quer receber uma nova senha?",style: TextStyle(color:HexColor(Constants.blue)),softWrap: true),
                  for(int i=0;i<founded.length;i++)
                    ListTile(
                      title: Text(label(founded[i].tipo),
                        style: TextStyle(color:HexColor(Constants.blue)),
                      ),
                      leading: Radio(
                        value: radioValue[founded[i].tipo],
                        groupValue: _value,
                        activeColor: HexColor(Constants.red),
                        onChanged: (value){
                          setState(() {
                            _value = value;
                            print("....."+value.toString());
                          });
                        },
                      ),
                    )
                ])
                );
              }),
          actions: [
            cancelButton
          ],
        );  // show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );

      }else{
        String msg = "";
        await ChangePassApi.forgotPass(login).then((value) => msg = value.result);
        AlertDialog alert;
        Widget cancelButton = FlatButton(
          child: Text("OK"),
          onPressed:  () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        );
        alert = AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          title: Text("ATENÇÃO", style: TextStyle(fontWeight: FontWeight.bold,color: HexColor(Constants.red))),
          content: Text(msg,style: TextStyle(color:HexColor(Constants.blue)),softWrap: true),
          actions: [
            cancelButton
          ],
        );  // show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      }
    }else{
      Message.showMessage("Preencha um login válido!");
    }
  }

String label(String tipo){
    String lbl = "T";

    switch(tipo){
      case "D":
        lbl = "Diretor";
        break;
      case "C":
        lbl = "Consultor";
        break;
      default:
        lbl = "Analista";
        break;
    }
    return lbl;
  }

  _footer(double width, double height){
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
    Row(children: [SizedBox(height:80)],),
    Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
    Image.asset("images/lg.png",width: 300,height: 138,),
    ],
    ),
    SizedBox(height: 40,),
    ]);
  }

}