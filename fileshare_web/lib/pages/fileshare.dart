import 'package:file_picker/file_picker.dart';
import 'package:fileshare_web/service/service.dart';
import 'package:flutter/material.dart';

import '../util/util.dart';
import '../widgets/get_scaffold.dart';
import '../widgets/my_progress.dart';

class UploadFile {
  // int idx = DateTime.now().microsecondsSinceEpoch; //坑爹啊，web不支持毫秒级别的时间，所以生成的idx都一样
  String name;
  int idx;
  int size;
  Stream<List<int>> readStream;
  bool? uploadSuccess;
  int? uploadSize;
  bool uploading = false;
  String failedMsg = '';

  UploadFile({
    required this.idx,
    required this.name,
    required this.size,
    required this.readStream,
  });
}

class FileShare extends StatefulWidget {
  const FileShare({super.key, required this.dir});

  final String dir;

  @override
  State<StatefulWidget> createState() {
    return FileShareState();
  }
}

class FileShareState extends State<FileShare> {
  List<UploadFile> selectFiles = [];
  late final dir = widget.dir;

  picFile({bool allowMultiple = true}) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withReadStream: true);
    if (result != null) {
      final files = result.files;
      List<UploadFile> s = [];
      for (int i = 0; i < files.length; i++) {
        final ele = files[i];
        final readStream = ele.readStream;
        if (readStream == null) continue;
        final idx = int.parse(
            "${DateTime.now().millisecondsSinceEpoch}$i"); // 防止重新选择后idx重复
        s.add(UploadFile(
            name: ele.name, size: ele.size, readStream: readStream, idx: idx));
      }
      setState(() {
        selectFiles = s;
      });
    } else {
      print("error: pickFiles: result is null");
    }
  }

  int get totalSize {
    int total = 0;
    for (var f in selectFiles) {
      total += f.size;
    }
    return total;
  }

  List<Widget> get getSelectFiles {
    List<Widget> items = [];
    for (int i = 0; i < selectFiles.length; i++) {
      final f = selectFiles[i];
      final idx = f.idx;
      final fileName = f.name;
      Widget trailButton;
      if (f.uploadSuccess != null) {
        if (f.uploadSuccess == true) {
          trailButton = const IconButton(
              onPressed: null,
              icon: Icon(
                Icons.done_all,
                color: Colors.green,
              ));
        } else {
          trailButton = IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          title: Text(f.name), content: Text(f.failedMsg));
                    });
              },
              icon: const Icon(Icons.sms_failed, color: Colors.red));
        }
      } else {
        if (f.uploadSize != null) {
          trailButton =
              MyCircularProgressIndicator(count: f.uploadSize!, total: f.size);
        } else {
          trailButton = IconButton(
              onPressed: () {
                for (int i = 0; i < selectFiles.length; i++) {
                  if (selectFiles[i].idx == idx) {
                    selectFiles.removeAt(i);
                    setState(() {});
                    break;
                  }
                  ;
                }
              },
              icon: const Icon(Icons.close, color: Colors.red));
        }
      }
      items.add(ListTile(
        leading: trailButton,
        minLeadingWidth: 0,
        title: Text(fileName),
        trailing: Text(formatFileSize(f.size)),
        // dense: true,
      ));
      items.add(const Divider());
      continue;
    }
    return items;
  }

  void upload() {
    for (var id = 0; id < selectFiles.length; id++) {
      final ele = selectFiles[id];
      if (ele.uploadSuccess != null) continue;
      if (ele.uploading) continue;
      ele.uploading = true;
      selectFiles[id] = ele;
      final idx = ele.idx;
      final name = ele.name;
      final readStream = ele.readStream;
      uploadFile(
          dir: dir,
          name: name,
          body: readStream,
          onSendProgress: (int count, int total) {
            for (var i = 0; i < selectFiles.length; i++) {
              final s = selectFiles[i];
              print("onSendProgress: idx: $idx, s.idx: ${s.idx}, name: $name");
              if (s.idx == idx) {
                if (s.uploadSuccess != null) return;
                s.uploadSize = count;
                selectFiles[i] = s;
                print("idx: $idx count: $count total: $total");
                setState(() {});
                break;
              }
            }
          }).then((String value) {
        if (!mounted) return;
        if (value == "") {
          for (int i = 0; i < selectFiles.length; i++) {
            final s = selectFiles[i];
            if (s.idx == idx) {
              s.uploadSize = s.size;
              s.uploadSuccess = true;
              selectFiles[i] = s;
              setState(() {});
              break;
            }
          }
        } else {
          myToast(context, "upload error! $name $value");
          for (var i = 0; i < selectFiles.length; i++) {
            final s = selectFiles[i];
            if (s.idx == idx) {
              s.uploadSuccess = false;
              s.failedMsg = value;
              selectFiles[i] = s;
              setState(() {});
              break;
            }
          }
        }
      });
    }
  }

  bool canUpload() {
    int count = 0;
    for (var ele in selectFiles) {
      if (ele.uploadSuccess == null &&
          ele.uploading == false &&
          ele.uploadSize == null) {
        count++;
      }
    }
    if (count > 0) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final canUp = canUpload();
    final col = Column(
      children: [
        ListTile(
          title: const Text(
            "please select the files",
            style: TextStyle(color: Colors.green),
          ),
          minLeadingWidth: 0,
          subtitle: selectFiles.isEmpty
              ? const Text("")
              : Text(
                  "count: ${selectFiles.length}, size: ${formatFileSize(totalSize)}"),
          trailing: IconButton(
              onPressed: canUp ? upload : null,
              icon: canUp
                  ? const Icon(Icons.upload, color: Colors.green)
                  : const Icon(Icons.upload)),
          leading: IconButton(
            onPressed: selectFiles.isEmpty
                ? null
                : () {
                    selectFiles = [];
                    setState(() {});
                  },
            icon: Icon(
              Icons.clear,
              color: selectFiles.isEmpty ? Colors.grey : Colors.red,
            ),
          ),
          onTap: () {
            picFile();
          },
        ),
        Expanded(
            child: SingleChildScrollView(
          child: Column(children: getSelectFiles),
        ))
      ],
    );
    return getScaffold(
      context,
      appBar: AppBar(
        title: Tooltip(
            message: dir,
            child: Text(
              "File Upload: $dir",
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
            )),
      ),
      body: Padding(padding: const EdgeInsets.all(10), child: col),
    );
  }
}
