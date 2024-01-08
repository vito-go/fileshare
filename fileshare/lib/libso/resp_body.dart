class RespData<T> {
  int code = 0;
  String message = "";
  T? data;

  RespData({
    this.code = 0,
    this.message = "",
    this.data,
  });

  RespData.dataOK(T d) {
    data = d;
  }

  bool get success => code == 0;

  RespData.fromJson(Map<String, dynamic> m, T Function(dynamic json) fromJson) {
    code = m['code'] ?? 0;
    message = m['message'].toString();
    if (m.containsKey('data')) {
      data = fromJson(m['data']);
    }
  }

  RespData.error() {
    code = -1;
  }
}
