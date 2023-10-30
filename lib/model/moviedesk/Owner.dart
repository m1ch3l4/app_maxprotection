class Owner{
  String? id;
  int? personType;
  int? profileType;
  String? businessName;
  String? email;
  String? phone;

  Owner.data([this.businessName,this.email,this.id,this.phone]){
    this.businessName ??= "-";
    this.email ??="-";
    this.id ??= "0";
    this.phone ??="-";
  }


  Owner.fromJson(Map<String, dynamic> json) {
    phone = (json['phone']!=null?json['phone']:'-');
    businessName = json['businessName'];
    email = json["email"];
    id = json["id"];
  }
}