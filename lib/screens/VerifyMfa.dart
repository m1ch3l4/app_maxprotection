import 'package:animated_widgets/widgets/rotation_animated.dart';
import 'package:animated_widgets/widgets/shake_animated_widget.dart';
import 'package:app_maxprotection/screens/inner_pwd.dart';
import 'package:app_maxprotection/screens/inner_user.dart';
import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/RadialButton.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_login.dart';
import '../utils/Message.dart';
import '../utils/SharedPref.dart';
import '../widgets/custom_route.dart';
import 'home_page.dart';

final GlobalKey<VerfiyMfaState> keyHP = new GlobalKey<VerfiyMfaState>();

class verifyTwoFactor extends StatelessWidget {
  static const routeName = '/dashboard';
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
            home: new VerfiyMfa(key:keyHP,title: 'MaxProtection E-Seg', user: snapshot.data as Map<String, dynamic>),
          ) : CircularProgressIndicator());
        },
      ),
    );
  }

}

class VerfiyMfa extends StatefulWidget {
  VerfiyMfa({required Key key, this.title,this.user}) : super(key: key);

  final String? title;
  final Map<String, dynamic>? user;

  @override
  VerfiyMfaState createState() => VerfiyMfaState();
}

class VerfiyMfaState extends State<VerfiyMfa> {
  String? code;
  bool? loaded;
  bool? shake;
  bool valid=false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textNode = FocusNode();

  SharedPref sharedPref = SharedPref();

  double? tamanho;

  String? firstLogin="";

  @override
  void initState() {
    super.initState();
    code = '';
    loaded = true;
    shake = false;
    valid = true;
  }

  void onCodeInput(String value) {
    setState(() {
      code = value;
    });
  }

  Future<void> verifyMfaAndNext() async {
    setState(() {
      loaded = false;
    });

    firstLogin = await sharedPref.getValue("fl");

    await LoginApi.verifymfa(widget.user!["id"],code!).then((resp){
      print('LoginAPI. ${resp.ok}');
      if(!resp.ok){
        Message.showMessage(resp.msg);
        valid=false;
      }else {
        valid = true;
      }
      loaded=true;
    });

    if (valid) {
      if(firstLogin=="true"){
        Message.showMessage("É o seu primeiro login. Você deve alterar sua senha.");
        Navigator.of(context).pushAndRemoveUntil(FadePageRoute(
          builder: (context) => InnerPwd(),
        ), (Route<dynamic> route) => false);
      }else {
        Navigator.of(context).pushAndRemoveUntil(FadePageRoute(
          builder: (context) => HomePage(),
        ), (Route<dynamic> route) => false);
      }
    } else {
      setState(() {
        shake = true;
        code='';
        _controller.clear();
        //code='';
      });
      await Future<String>.delayed(
          const Duration(milliseconds: 300), () => '1');
      setState(() {
        shake = false;
      });
    }
  }

  List<Widget> getField() {
    final List<Widget> result = <Widget>[];
    for (int i = 1; i <= 6; i++) {
      result.add(
        ShakeAnimatedWidget(
          enabled: shake!,
          duration: const Duration(
            milliseconds: 100,
          ),
          shakeAngle: Rotation.deg(
            z: 20,
          ),
          curve: Curves.linear,
          child: Column(
            children: <Widget>[
              if (code!.length >= i)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                  ),
                  child: Text(
                    code![i - 1],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: Container(
                  height: 5.0,
                  width: 30.0,
                  color: shake! ? Colors.red : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    tamanho = height;

    return Scaffold(
      backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset : false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          SystemChannels.textInput.invokeMethod<String>('TextInput.hide');
        },
        child: Container(
          height: height,
          width: width,
            constraints: const BoxConstraints.expand(),
            decoration: const BoxDecoration(
            image: DecorationImage(
            image: AssetImage("images/Fundo.png"),fit: BoxFit.cover),),
            child: Column(
            children: <Widget>[
              _logo(context, width, height*0.25),
              const SizedBox(
                height: 25,
              ),
              Text(
                'Informe o pin de 6 digitos\nenviado no seu e-mail',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              if (!valid)
                Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                      ),
                      child: Text(
                        'Inválido!',
                        style: TextStyle(
                          color: HexColor(Constants.red),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(
                height: valid ? 68 : 10,
              ),
              if (!valid)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                  ),
                  child: Text(
                    'Você inseriu o pin errado. Por favor tente novamente.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),

              Container(
                height: 90,
                width: 300,
                child: Stack(
                  children: <Widget>[
                    Opacity(
                      opacity: 1.0,
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: InputBorder.none
                        ),
                        cursorColor: Colors.transparent,
                        style: TextStyle(color:Colors.transparent),
                        controller: _controller,
                        focusNode: _textNode,
                        keyboardType: TextInputType.number,
                        onChanged: onCodeInput,
                        maxLength: 6,
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: getField(),
                      ),
                    )
                  ],
                ),
              ),
              RadialButton(buttonText: "Verificar", width: width*0.8, onpressed: verifyMfaAndNext)
            ],
          ),
        ),
        )
    );
  }
  Widget _logo(BuildContext context, double width, double height){
    return Container(
        height: height,
        width: width,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        alignment: Alignment.center,
        child:
        Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset("images/lg.png",width: (tamanho!<700?280:300),height: (tamanho!<700?128:138),),
                ],
              ),
              Spacer()]));
  }
}