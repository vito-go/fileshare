import 'package:fileshare_web/util/util.dart';
import 'package:flutter/material.dart';

class PreviewText extends StatelessWidget {
  const PreviewText({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close)),
        title: const Text("Select Text"),
        actions: [
          Tooltip(
            message: "Copy All",
            child: IconButton(
                onPressed: () async {
                  copyToClipBoard(context, content);
                },
                icon: const Icon(Icons.copy_all)),
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: SelectableText(content),
          )),
    );
  }
}
