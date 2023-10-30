class Organization{
  String? id;
  String? businessName;

  Organization.fromJson(Map<String, dynamic> json) {
    businessName = json['businessName'];
    id = json["id"];
  }
}