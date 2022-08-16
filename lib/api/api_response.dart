class ApiResponse<T>{
  late bool ok;
  late String msg;
  late T result;

  ApiResponse.ok(this.result){
    ok=true;
  }

  ApiResponse.error(this.msg){
    ok=false;
  }
}