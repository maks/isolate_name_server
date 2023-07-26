import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';

void main() async {
  final ReceivePort receivePort = ReceivePort();
  final SendPort sendPort = receivePort.sendPort;

  receivePort.listen((message) {
    print("message to recv port:$message");

    receivePort.close(); // we're done, close port so Dart will exit
  });

  IsolateNameServer.registerPortWithName(sendPort, "accumulator");
  print("registered SendPort as accumulator");

  sendPort.send("goodbye");
}
