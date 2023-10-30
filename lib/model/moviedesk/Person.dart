import 'Organization.dart';

class Person{
  String? userName;
  String? businessName;
  String? email;
  String? id;
  String? phone;
  Organization? organization;

  Person.data([this.userName,this.businessName,this.email,this.id,this.phone]){
    this.userName ??= "-";
    this.businessName ??= "-";
    this.email ??= "-";
    this.id ??= "0";
    this.phone ??= "-";
  }


  Person.fromJson(Map<String, dynamic> json) {
    userName = json['userName'];
    businessName = (json['businessName']!=null?json['businessName']:'-');
    email = json["email"];
    id = json["id"];
    phone = (json["phone"]!=null?json["phone"]:"-");
    var o = json['organization'];
    if(o!=null)
    organization = Organization.fromJson(json['organization']);
  }
}