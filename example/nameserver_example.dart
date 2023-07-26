import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';

void main() async {
  final ReceivePort receivePort = ReceivePort();
  final SendPort sendPort = receivePort.sendPort;

  receivePort.listen((message) {
    print("message to recv port:$message");

    if (message == "goodbye") {
      receivePort.close(); // we're done, close port so Dart will exit
    }    
  });

  final portName = "accumulator";
  IsolateNameServer.registerPortWithName(sendPort, portName);
  print("registered SendPort as $portName");

  final sendPort2 = IsolateNameServer.lookupPortByName(portName);
  if (sendPort2 != null) {
    sendPort2.send("goodbye");
  } else {
    throw Exception("could not retrieve named SendPort");
  }
  
}
