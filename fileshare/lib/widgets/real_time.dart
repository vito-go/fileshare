import 'dart:async';

import 'package:flutter/widgets.dart';

import '../util/util.dart';

class RealTime extends StatefulWidget {
  const RealTime({super.key});

  @override
  State<StatefulWidget> createState() {
    return RealTimeState();
  }
}

class RealTimeState extends State {
  DateTime now = DateTime.now();

  Timer? timer;

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 998), (_) {
      now = DateTime.now();
      setState(() {});
    });
  }


  @override
  Widget build(BuildContext context) {
    return Text(formatTime(now));
  }
}
