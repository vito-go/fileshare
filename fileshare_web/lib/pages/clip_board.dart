import 'package:fileshare_web/pages/preview.dart';
import 'package:fileshare_web/service/service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util/util.dart';
import '../widgets/get_scaffold.dart';

class ClipBoard extends StatefulWidget {
  const ClipBoard({super.key});

  @override
  State<StatefulWidget> createState() {
    return ClipBoardState();
  }
}

class ClipBoardState extends State<ClipBoard> {
  List<BoardContent> contents = [];
  bool canSend = false;

  Future<void> initContents() async {
    final value = await boardList();
    contents = value;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initContents();
  }

  Widget buildContents() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int count) {
        final content = contents[count].content;
        final id = contents[count].id;
        return ListTile(
          // dense: true,
          minLeadingWidth: 0,
          leading: IconButton(
              onPressed: () async {
                final result = await boardDel(id: id);
                if (result == "") {
                  contents.removeWhere((element) => element.id == id);
                  setState(() {});
                }
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              )),
          title: Text(content, maxLines: 4, overflow: TextOverflow.ellipsis),
          onTap: () {
            Navigator.push(context,
                CupertinoPageRoute(builder: (BuildContext context) {
              return PreviewText(content: content);
            }));
          },
          trailing: IconButton(
              onPressed: () {
                copyToClipBoard(context, content);
              },
              icon: const Icon(Icons.copy_all)),
        );
      },
      itemCount: contents.length,
    );
  }

  TextEditingController controller = TextEditingController();

  Widget get getTextField => TextField(
        minLines: 4,
        controller: controller,
        onChanged: (v) {
          if (v == "") {
            canSend = false;
            setState(() {});
            return;
          }
          if (canSend) return;
          setState(() {
            canSend = true;
          });
        },
        maxLines: 12,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(),
          hintText: "type here...",
        ),
      );

  Widget get getRowSend => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
              onPressed: () {
                controller.text = "";
                setState(() {
                  canSend = false;
                });
              },
              icon: const Icon(
                Icons.clear,
                color: Colors.red,
              )),
          const SizedBox(
            width: 10,
          ),
          IconButton(
              onPressed: !canSend
                  ? null
                  : () async {
                      final text = controller.text;
                      if (text == "") {
                        myToast(context, "content is empty");
                        return;
                      }
                      final result = await boardAdd(body: text);
                      if (result > 0) {
                        contents.insert(0, BoardContent(result, text));
                        controller.text = "";
                        canSend = false;
                        setState(() {});
                      }
                    },
              icon: Icon(
                Icons.send,
                color: canSend ? Theme.of(context).primaryColor : null,
              )),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final col = Column(
      children: [
        getTextField,
        getRowSend,
        Row(
          children: [
            const Flexible(child: Divider()),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Text("total: ${contents.length}"),
            ),
            const Flexible(child: Divider()),
          ],
        ),
        Expanded(child: buildContents())
      ],
    );
    return getScaffold(
      context,
      appBar: AppBar(
        title: const Text(
          "Clip Board",
        ),
        actions: [
          Tooltip(
            message: "Refresh",
            child: IconButton(
                onPressed: () async {
                  await initContents();
                  if (!mounted) return;
                  myToast(context, "Update Successfully!");
                },
                icon: const Icon(Icons.refresh)),
          )
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(8), child: col),
    );
  }
}
