import 'dart:html';

import 'package:fileshare_web/pages/clip_board.dart';
import 'package:fileshare_web/pages/fileshare.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../service/service.dart';
import '../util/util.dart';
import '../widgets/get_scaffold.dart';

class FileList extends StatefulWidget {
  const FileList({super.key, required this.dir});

  final String dir;

  @override
  State<StatefulWidget> createState() {
    return FileListState();
  }
}

class FileListState extends State<FileList> {
  List<FileInfo> listFiles = [];
  late final String dir = widget.dir;
  bool allowUpload = false;
  String filter = "";
  bool fileSelected = true;
  bool folderSelected = true;

  int get totalSize {
    int total = 0;
    for (var f in listFiles) {
      total += f.size;
    }
    return total;
  }

  TextEditingController controller = TextEditingController();

  bool init = false;

  void previewOrDownload({required String path, required String name}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Preview or Download?'),
            content: const Text(
                "Attention Please! Not all file types support previewing, and downloading may occur directly after previewing."),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        downloadFile(path: path, name: name, preview: false);
                      },
                      child: const Text("Download")),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        downloadFile(path: path, name: name, preview: true);
                      },
                      child: const Text("Preview")),
                ],
              )
            ],
          );
        });
  }

  List<Widget> get buildListFiles {
    List<Widget> items = [];
    for (var f in listFiles) {
      final name = f.name;
      if (filter != "") {
        if (!name.toLowerCase().contains(filter.toLowerCase())) {
          continue;
        }
      }
      final isDir = f.isDir;
      if (!fileSelected) {
        if (!isDir) {
          continue;
        }
      }
      if (!folderSelected) {
        if (isDir) {
          continue;
        }
      }

      final path = f.path;
      items.add(ListTile(
        title: Text(name,
            style: isDir ? const TextStyle(color: Colors.blue) : null),
        leading: isDir
            ? const IconButton(
                onPressed: null,
                icon: Icon(
                  Icons.folder,
                  color: Colors.blue,
                ))
            : IconButton(
                onPressed: () async {
                  final host = window.location.host;
                  final protocol = window.location.protocol;
                  final routerPath = "/_download/$path";
                  final url = "$protocol//$host$routerPath";
                  await Clipboard.setData(ClipboardData(text: url));

                  final ua = window.navigator.userAgent.toLowerCase();
                  if (ua.contains("android") || ua.contains("ios")) {
                    // 手机系统自动提示复制
                    return;
                  }
                  if (!mounted) return;
                  myToast(context, "copy successfully!\nurl: $url");
                },
                icon: const Icon(Icons.file_copy, color: Colors.green)),
        subtitle: isDir
            ? null
            : Text(
                "${formatFileSize(f.size)}    ${formatTime(DateTime.fromMillisecondsSinceEpoch(f.lastTime))}"),
        onTap: isDir
            ? () {
                Navigator.push(context,
                    CupertinoPageRoute(builder: (BuildContext context) {
                  return FileList(dir: path);
                }));
              }
            : () {
                previewOrDownload(path: path, name: name);
              },
        trailing: !isDir
            ? IconButton(
                onPressed: () {
                  downloadFile(path: path, name: name, preview: false);
                  return;
                },
                icon: const Icon(
                  Icons.download,
                  color: Colors.green,
                ))
            : IconButton(
                onPressed: () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (BuildContext context) {
                    return FileList(dir: path);
                  }));
                  return;
                },
                icon: const Icon(Icons.navigate_next, color: Colors.blue)),
      ));
    }
    return items;
  }

  Future<void> initFileInfos() async {
    final value = await getFileInfos(path: dir);
    init = true;
    if (value == null) return;
    listFiles = value.fileInfos;
    allowUpload = value.allowUpload;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initFileInfos();
  }

  Widget get uploadButton => Tooltip(
        message: "File Upload",
        child: IconButton(
            onPressed: () {
              Navigator.push(context,
                  CupertinoPageRoute(builder: (BuildContext context) {
                return FileShare(dir: dir);
              })).then((value) => initFileInfos());
            },
            icon: const Icon(Icons.upload_file)),
      );

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  Widget get listHeader => Row(
        children: [
          Expanded(
              child: CupertinoSearchTextField(
                  controller: controller,
                  onChanged: (String value) {
                    setState(() {
                      filter = value;
                    });
                  })),
          const SizedBox(width: 10),
          Tooltip(
            message: "Folder",
            child: IconButton(
                onPressed: () {
                  setState(() {
                    folderSelected = !folderSelected;
                  });
                },
                icon: folderSelected
                    ? const Icon(
                        Icons.folder,
                        color: Colors.blue,
                      )
                    : const Icon(Icons.folder_outlined)),
          ),
          Tooltip(
            message: "File",
            child: IconButton(
                onPressed: () {
                  setState(() {
                    fileSelected = !fileSelected;
                  });
                },
                icon: fileSelected
                    ? const Icon(
                        Icons.file_open,
                        color: Colors.green,
                      )
                    : const Icon(Icons.file_open_outlined)),
          )
        ],
      );

  Widget get refreshButton => Tooltip(
        message: "Refresh",
        child: IconButton(
            onPressed: () async {
              await initFileInfos();
              if (!mounted) return;
              myToast(context, "Update Successfully!");
            },
            icon: const Icon(Icons.refresh)),
      );

  Widget get homeButton => Tooltip(
      message: "Home",
      child: IconButton(
          onPressed: () {
            if (dir == "/") {
              return;
            }
            Navigator.push(context,
                CupertinoPageRoute(builder: (BuildContext context) {
              return const FileList(dir: "/");
            }));
          },
          icon: const Icon(Icons.home)));

  Widget get clipBoardButton => Tooltip(
      message: "Clip Board",
      child: IconButton(
          onPressed: () {
            Navigator.push(context,
                CupertinoPageRoute(builder: (BuildContext context) {
              return const ClipBoard();
            }));
          },
          icon: const Icon(Icons.paste)));

  @override
  Widget build(BuildContext context) {
    final listFilesBuild = buildListFiles;
    List<Widget> columnChildren = [
      const SizedBox(height: 5),
      listHeader,
      const SizedBox(height: 5),
    ];
    Widget body;
    if (listFilesBuild.isEmpty && init) {
      columnChildren.add(const Expanded(
          child: Center(
              child: Text("No Files",
                  style: TextStyle(color: Colors.grey, fontSize: 22)))));
      body = Column(children: columnChildren);
    } else {
      columnChildren.add(Expanded(child: ListView(children: listFilesBuild)));
      body = Column(children: columnChildren);
    }

    List<Widget> actionChildren = [];
    actionChildren.add(clipBoardButton);

    if (allowUpload) {
      actionChildren.add(uploadButton);
    }
    actionChildren.add(refreshButton);
    actionChildren.add(homeButton);
    return getScaffold(
      context,
      appBar: AppBar(
        title: Tooltip(
            message: dir,
            child:
                Text(dir, maxLines: 3, style: const TextStyle(fontSize: 14))),
        actions: actionChildren,
      ),
      body: Padding(padding: const EdgeInsets.all(8), child: body),
    );
  }
}
