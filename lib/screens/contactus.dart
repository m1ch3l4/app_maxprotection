import 'package:contactus/contactus.dart';
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import '../widgets/constants.dart';


void main() => runApp(ContatcusScreen());

class ContatcusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: ContactUsBottomAppBar(
          companyName: '',
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          email: 'atendimento@maxprotection.com.br',
          textFont: 'Metropolis',
        ),
        body: Container(
    decoration: const BoxDecoration(
    image: DecorationImage(
    image: AssetImage("images/Fundo.png"),fit: BoxFit.cover),),
            child:ContactUs(
            cardColor: HexColor(Constants.red),
            textColor: Colors.white,
            logo: AssetImage('images/lg.png'),
            email: 'atendimento@maxprotection.com.br',
            companyName: '',
            companyFontSize: 32.0,
            companyFont: 'Metropolis',
            companyColor: Colors.transparent,
            dividerColor: Colors.transparent,
            phoneNumber: '+555137104050',
            website: 'https://www.maxprotection.com.br',
            //tagLine: 'Gestão de Segurança da Informação',
            taglineColor: Colors.transparent,
            //linkedinURL: 'https://www.linkedin.com/company/maxprotectionsecuritysolutions',
            instagram: 'maxprotectionsecurity',
            facebookHandle: 'maxprotectionsolutions'),
      )),
    );
  }
}