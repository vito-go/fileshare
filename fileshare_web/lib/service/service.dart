import 'dart:convert';
import 'dart:html';

import 'package:dio/dio.dart';
import 'package:fileshare_web/util/util.dart';

class FileInfos {
  List<FileInfo> fileInfos;
  bool allowUpload;

  FileInfos({required this.fileInfos, required this.allowUpload});
}

class FileInfo {
  String name = '';
  String path = '';
  bool isDir = false;
  int size = 0;
  int lastTime = 0;

  FileInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    path = json['path'] ?? '';
    size = json['size'] ?? 0;
    isDir = json['isDir'] ?? false;
    lastTime = json['lastTime'] ?? 0;
  }
}

void downloadFile(
    {required String path, required String name, bool preview = false}) async {
  if (preview) {
    // preview
    window.open("/_download/$path", name);
    return;
  }
  window.open("/_download/$path?preview=0", name); // download
  return;
}

Future<FileInfos?> getFileInfos({required String path}) async {
  final dio = Dio();
  final Response<String> resp = await dio.get("/_fileInfos",
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (_) {
          return true;
        },
      ),
      queryParameters: {
        "path": path,
        "_": DateTime.now().millisecondsSinceEpoch
      });
  if (resp.statusCode != 200) {
    return null;
  }
  if (resp.data == null) return null;
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(resp.data!);
  } catch (e) {
    return null;
  }
  final List<dynamic> items = data['fileInfos'] ?? [];
  final allowUpload = data["allowUpload"] ?? false;
  List<FileInfo> fileInfos = [];
  for (Map<String, dynamic> ele in items) {
    fileInfos.add(FileInfo.fromJson(ele));
  }
  return FileInfos(fileInfos: fileInfos, allowUpload: allowUpload);
}

Future<String> uploadFile(
    {required String dir,
    required String name,
    required Stream<List<int>> body,
    Function(int count, int total)? onSendProgress}) async {
  final dio = Dio();
  final Response<String> resp = await dio.post(
    "/_upload",
    options: Options(
        responseType: ResponseType.plain,
        contentType: "application/octet-stream",
        validateStatus: (_) {
          return true;
        }),
    data: body,
    onSendProgress: onSendProgress,
    queryParameters: {"name": name, "dir": dir},
  );
  if (resp.statusCode != 200) {
    return "statusCode: ${resp.statusCode} ${resp.data}";
  }
  return "";
}

Future<int> boardAdd({
  required String body,
}) async {
  final dio = Dio();
  final Response<String> resp = await dio.post(
    "/_board/add",
    options: Options(
        responseType: ResponseType.plain,
        contentType: "application/octet-stream",
        validateStatus: (_) {
          return true;
        }),
    data: body,
  );
  if (resp.statusCode != 200) {
    return -1;
  }
  return int.parse(resp.data!);
 }

Future<String> boardDel({required int id}) async {
  final dio = Dio();
  final Response<String> resp = await dio.post("/_board/delete",
      options: Options(
          responseType: ResponseType.plain,
          contentType: "application/octet-stream",
          validateStatus: (_) {
            return true;
          }),
      queryParameters: {
        "id": id,
      });
  if (resp.statusCode != 200) {
    return "statusCode: ${resp.statusCode} ${resp.data}";
  }
  return "";
}

class BoardContent {
  String content;
  int id;

  BoardContent(this.id, this.content);
}

Future<List<BoardContent>> boardList() async {
  final dio = Dio();
  final Response<String> resp = await dio.get(
    "/_board/list",
    options: Options(
      responseType: ResponseType.plain,
      validateStatus: (_) {
        return true;
      },
    ),
  );
  if (resp.statusCode != 200) {
    return [];
  }
  if (resp.data == null) return [];
  if (resp.data == "null") return [];
  final List<dynamic> items;
  try {
    items = jsonDecode(resp.data!);
  } catch (e) {
    return [];
  }

  List<BoardContent> result = [];
  for (Map<String, dynamic> ele in items) {
    result.add(BoardContent(ele['id'] as int, ele['content'].toString()));
  }
  return result;
}
