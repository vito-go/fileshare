import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fileshare/libso/libgo.dart';
import 'package:fileshare/widgets/stream_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../util/net.dart';
import '../util/util.dart';
import '../widgets/private_ip.dart';
import '../widgets/real_time.dart';

class Server extends StatefulWidget {
  const Server({super.key});

  @override
  State createState() {
    return ServerState();
  }
}

class ServerState extends State<Server> {
  TextEditingController controllerPort = TextEditingController(text: "14444");
  String rootDir = "";

  String? getHomeDir() {
    String? homeDirectory;
    if (Platform.isWindows) {
      homeDirectory = Platform.environment['USERPROFILE'] ?? '';
      if (homeDirectory == "") {
        homeDirectory = Platform.environment['HOME'] ?? '';
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      homeDirectory = Platform.environment['HOME'] ?? '';
    }
    return homeDirectory;
  }

  String getDefaultDir() {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/Download/";
    }
    // 获取可执行文件的路径
    String homeDirectory = getHomeDir() ?? '';
    if (homeDirectory != "") {
      return path.join(homeDirectory, "Downloads");
    }
    throw "home directory is empty";
  }

  @override
  void initState() {
    super.initState();
    rootDir = getDefaultDir();
  }

  Widget textFieldBuild(TextEditingController controller, String labelText) {
    final t = TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        LengthLimitingTextInputFormatter(5),
        FilteringTextInputFormatter(RegExp("[0-9]"), allow: true)
      ],
      // style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(),
          labelText: labelText,
          contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          border: const OutlineInputBorder(),
          suffix: const Text(
            "Allow Upload",
            style: TextStyle(fontSize: 12),
          ),
          suffixIcon: Checkbox(
              value: allowUpload,
              onChanged: (bool? v) {
                if (v == null) return;
                println("allow upload: $v");

                allowUpload = v;
                setState(() {});
              })),
    );
    return t;
  }

  List<int> serverIds = [];
  Map<int, ServerInfo> serverIdxMap = {};
  bool connecting = false;

  void closeServerByIdx(int idx) {
    if (connecting == true) return;
    if (mounted) {
      setState(() {
        connecting = true;
      });
    }
    closeServer(idx);
    if (idx <= 0) {
      serverIdxMap.clear();
      serverIds.clear();
    } else {
      serverIdxMap.remove(idx);
      serverIds.remove(idx);
    }
    if (mounted) {
      setState(() {
        connecting = false;
      });
    }
  }

  void showServerInfo(BuildContext context, ServerInfo serverInfo) async {
    final serverIdx = serverInfo.serverIdx;
    final ips = await getIPv4s();
    List<Widget> children = [];
    children.add(ListTile(
      title:
          Text("Sharing Directory (Allow Upload: ${serverInfo.allowUpload})"),
      subtitle: Text(rootDir),
      onTap: null,
    ));
    children.add(ListTile(
      leading: const Icon(Icons.close, color: Colors.red),
      title: Text("Close the Server (port: ${serverInfo.port})"),
      subtitle: Text("Start Time: ${formatTime(serverInfo.startTime)}"),
      onTap: () {
        Navigator.pop(context);
        closeServerByIdx(serverIdx);
      },
    ));

    for (final ip in ips) {
      final url = "http://$ip:${serverInfo.port}";
      children.add(ListTile(
        leading: const Icon(Icons.open_in_browser),
        title: const Text("Open in Browser"),
        subtitle: Text(url),
        onTap: () async {
          Navigator.pop(context);
          launchUrlString(url);
        },
      ));
    }
    if (!mounted) return;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          );
          return Padding(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(child: column));
        });
  }

  Widget getServersCloseBtn() {
    List<Widget> children = [];
    for (var i = 0; i < serverIds.length; i++) {
      final serverIdx = serverIds[i];
      final serverInfo = serverIdxMap[serverIdx];
      if (serverInfo == null) continue;
      final allowUpload = serverInfo.allowUpload;
      children.add(Padding(
        padding: const EdgeInsets.only(right: 5),
        child: ElevatedButton.icon(
            onPressed: () {
              showServerInfo(context, serverInfo);
            },
            icon: allowUpload
                ? const Icon(Icons.info)
                : const Icon(Icons.info_outline),
            label: Text("${serverInfo.port}")),
      ));
    }
    return Row(children: children);
  }

  Future<bool> checkAndroidStatus() async {
    // 安卓10 必须进行权限状态判断和请求 其他的不用
    var status = await Permission.storage.status;
    status = await Permission.videos.request();
    status = await Permission.photos.request();
    status = await Permission.audio.request();
    // status = await Permission.ignoreBatteryOptimizations.request();
    status = await Permission.manageExternalStorage.request();
    status = await Permission.manageExternalStorage.request();
    if (status != PermissionStatus.granted) {
      status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        println("权限不足");
        // google pixel 7 not supported here
        return false;
      }
    }
    return true;
  }

  void connect(int pp) async {
    if (connecting == true) return;
    if (Platform.isAndroid) {
      final check = await checkAndroidStatus();
      if (!check) {
        return;
      }
    }
    setState(() {
      connecting = true;
    });
    println("sharing directory: $rootDir");
    final rootDirC = rootDir.toNativeUtf8();
    // todo
    final resultServerIdx = startServer(rootDirC, allowUpload, pp);
    setState(() {
      connecting = false;
    });
    malloc.free(rootDirC);
    if (resultServerIdx > 0) {
      serverIds.add(resultServerIdx);
      serverIdxMap[resultServerIdx] = ServerInfo.name(
          port: pp,
          allowUpload: allowUpload,
          startTime: DateTime.now(),
          serverIdx: resultServerIdx,
          dir: rootDir);
      setState(() {});
    }
  }

  Widget get connectBtn {
    return ElevatedButton(
        onPressed: connecting
            ? null
            : () {
                connect(int.parse(controllerPort.text));
              },
        child: const Text("Start"));
  }

  @override
  void dispose() {
    super.dispose();
    closeServer(0);
    controllerPort.dispose();
  }

  Widget connectRow() {
    List<Widget> children = [];
    children.add(CircleAvatar(child: Text("${serverIds.length}")));
    children.add(const SizedBox(width: 5));
    children.add(Expanded(
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: getServersCloseBtn())));
    return Row(children: children);
  }

  void aboutOnTap() async {
    String version = "0.0.1";
    const applicationName = "File Share";
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: applicationName,
      applicationIcon: InkWell(
        child: const FlutterLogo(),
        onTap: () async {},
      ),
      applicationVersion: "version: $version",
      applicationLegalese: '© All rights reserved',
      children: [
        const SizedBox(height: 5),
        const Text("author:liushihao888@gmail.com"),
        const SizedBox(height: 2),
        const Text("address: Beijing, China"),
      ],
    );
  }

  bool allowUpload = true;

  Widget get listTileSharingDir => ListTile(
        title: const Text("Sharing Directory"),
        subtitle: Text(rootDir, style: const TextStyle(color: Colors.blue)),
        onTap: () async {
          final String? initialDirectory = getHomeDir();
          String? selectedDirectory = await FilePicker.platform
              .getDirectoryPath(initialDirectory: initialDirectory);
          if (selectedDirectory == null) {
            return; // User canceled the picker
          }
          setState(() {
            rootDir = selectedDirectory;
          });
        },
        trailing: Tooltip(
            message: "reset sharing dir to default: ${getDefaultDir()}",
            child: IconButton(
                onPressed: () {
                  setState(() {
                    rootDir = getDefaultDir();
                  });
                  println("reset sharing dir to default: ${getDefaultDir()}");
                },
                icon: const Icon(Icons.refresh))),
      );

  Widget get portRow => Row(children: [
        Flexible(child: textFieldBuild(controllerPort, "Http Server Port")),
        const SizedBox(width: 8),
        connectBtn,
        Tooltip(
            message: "Close All Server",
            child: IconButton(
                onPressed: () {
                  closeServerByIdx(0);
                },
                icon: const CircleAvatar(
                    child: Icon(Icons.close, color: Colors.red))))
      ]);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      const RealTime(),
      const PrivateIP(),
      listTileSharingDir,
      const SizedBox(height: 5),
      portRow,
      const SizedBox(height: 5),
      connectRow(),
      const SizedBox(height: 5),
      const Flexible(child: StreamLog(maxLines: 200))
    ];
    final Column column = Column(children: children);
    return Scaffold(
      appBar: AppBar(
        title: const Text("FileShare"),
        actions: [
          IconButton(
              onPressed: aboutOnTap, icon: const Icon(Icons.help_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(child: column),
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: () {
                const skip = 3;
                println("caller doing  $skip");
                setLogCallerSkip(skip);
                println("caller done $skip");
              },
              child: const Icon(Icons.coffee),
            )
          : null,
    );
  }
}


class ServerInfo {
  String dir;
  bool allowUpload;
  int serverIdx;
  DateTime startTime;
  int port;

  ServerInfo.name({
    required this.allowUpload,
    required this.serverIdx,
    required this.dir,
    required this.startTime,
    required this.port,
  });

  Map<String, dynamic> toMap() {
    return {
      "serverIdx": serverIdx,
      "port": port,
    };
  }
}
