// @dart=2.9
class DashboardData{
  int siem;
  int zabbix;
  int open;
  int close;
  int waiting;
  int msgSiem;
  int msgZabbix;
  int msgTicket;
  int msgLead;

  DashboardData.data([this.siem,this.zabbix,this.open,this.close,this.waiting]) {
    this.siem ??= 0;
    this.zabbix ??=0;
    this.open ??= 0;
    this.close ??= 0;
    this.waiting ??=0;
  }

  DashboardData.fromJson(Map<String, dynamic> json){
    siem = (json['siem']!=null?json['siem']:0);
    zabbix = (json['zabbix']!=null?json['zabbix']:0);
    open = json['open'];
    close = json['close'];
    waiting = json['waiting'];
    msgLead = (json['msgLead']!=null?json['msgLead']:0);
    msgSiem = (json['msgSiem']!=null?json['msgSiem']:0);
    msgZabbix = (json['msgZabbix']!=null?json['msgZabbix']:0);
    msgTicket = (json['msgTicket']!=null?json['msgTicket']:0);
  }
}