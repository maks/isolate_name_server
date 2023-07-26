import 'dart:io';
import 'dart:isolate';
import 'dart:ffi';
import 'package:path/path.dart' as path;

typedef _ConvertNativePortToSendPortFunc = Handle Function(Int64 port);
typedef _ConvertNativePortToSendPort = SendPort Function(int port);

void main() {
  final ReceivePort receivePort = ReceivePort();
  final SendPort sendPort = receivePort.sendPort;
  final int nativePort = sendPort.nativePort;

  receivePort.listen((message) {
    print("message to recv port:$message");
  });

  final DynamicLibrary dylib = _init();

  final SendPort sendPort2 = convertNativePortToSendPort(dylib, nativePort);

  sendPort2.send("hi from sendport 2");
}

SendPort convertNativePortToSendPort(DynamicLibrary dylib, int nativePort) {
  final convertNativePortPointer =
      dylib.lookup<NativeFunction<_ConvertNativePortToSendPortFunc>>('convertNativePortToSendPort');
  final convertNativePort = convertNativePortPointer.asFunction<_ConvertNativePortToSendPort>();
  return convertNativePort(nativePort);
}

DynamicLibrary _init() {
  // Open the dynamic library
  String libraryPath = path.join(Directory.current.path, 'returnport_library', 'returnport.so');
  if (Platform.isMacOS) {
    libraryPath = path.join(Directory.current.path, 'returnport_library', 'returnport.dylib');
  }
  if (Platform.isWindows) {
    libraryPath = path.join(Directory.current.path, 'returnport_library', 'Debug', 'returnport.dll');
  }
  return DynamicLibrary.open(libraryPath);
}
