class ActionCreator{
  String? businessName;
  String? email;
  String? id;
  String? phone;

  ActionCreator.data([this.businessName,this.email,this.id,this.phone]){
    this.businessName ??= "-";
    this.email ??="-";
    this.id ??= "0";
    this.phone ??="-";
  }

  ActionCreator.fromJson(Map<String, dynamic> json) {
    businessName = (json['businessName']!=null?json['businessName']:"-");
    email = (json["email"]!=null?json['email']:"-");
    id = (json["id"]!=null?json["id"]:"-");
    phone = (json["phone"]!=null?json['phone']:"-");
  }
}