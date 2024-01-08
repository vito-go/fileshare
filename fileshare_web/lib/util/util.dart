


import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:io';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

String formatFileSize(int size) {
  if (size <= 1 << 10) {
    return "$size B";
  } else if (size <= 8 << 20) {
    return "${(size / 1024).ceil()} KB";
  } else if (size <= 1 << 30) {
    return "${(size / 1024 / 1024).ceil()} MB";
  } else {
    return "${(size / 1024 / 1024 / 1024).ceil()} GB";
  }
}


String formatTime(DateTime now) {
  String month = now.month < 10 ? "0${now.month}" : "${now.month}";
  String day = now.day < 10 ? "0${now.day}" : "${now.day}";
  String hour = now.hour < 10 ? "0${now.hour}" : "${now.hour}";
  String minute = now.minute < 10 ? "0${now.minute}" : "${now.minute}";
  String second = now.second < 10 ? "0${now.second}" : "${now.second}";
  return "${now.year}-$month-$day $hour:$minute:$second";
}
myToast(BuildContext context, dynamic msg) {
  myPrint(msg, skip: 2);

  if (!context.mounted) return;
  showToast(
    "$msg",
    context: context,
    animation: StyledToastAnimation.fade,
    reverseAnimation: StyledToastAnimation.fade,
    position: StyledToastPosition.center,
    // curve: Curves.linear,
    // reverseCurve: Curves.linear,
  );
}

myPrint(dynamic msg,
    {List<dynamic>? args, String level = 'INFO', int skip = 1}) {
  if (kIsWeb) {
    skip++;
  }
  //  根据环境进行打印输出
  if (kDebugMode) {
    var traceString = StackTrace.current.toString().split("\n")[skip];
    String arg = "";

    if (args != null) {
      arg = "{";
      for (var i = 0; i < args.length; i++) {
        if (i % 2 == 0) {
          arg += '"${args[i]}": ';
        } else {
          if (i == args.length - 1) {
            arg += '${args[i]}';
          } else {
            arg += '${args[i]}, ';
          }
        }
      }
      arg += "}";
    }

    print("[$level] ${DateTime.now()} $traceString $msg $arg");
  }
}


bool platFormIsMobile() {
  if (kIsWeb) {
    final ua = html.window.navigator.userAgent.toLowerCase();
    if (ua.contains("android") || ua.contains("ios")) {
      return true;
    }
    return false;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }
  return false;
}
copyToClipBoard(BuildContext context, String content) {
  Clipboard.setData(ClipboardData(text: content));
  if (!platFormIsMobile()) {
    myPrint(content);
    myToast(context, "Copy Successfully");
  }
}
