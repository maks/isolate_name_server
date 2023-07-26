import 'dart:io';
import 'dart:isolate';
import 'dart:ffi';
import 'package:path/path.dart' as path;

typedef _ConvertNativePortToSendPortFunc = Handle Function(Int64 port);
typedef _ConvertNativePortToSendPort = Object Function(int port);

void main() async {
  final ReceivePort receivePort = ReceivePort();
  final SendPort sendPort = receivePort.sendPort;
  final int nativePort = sendPort.nativePort;

  receivePort.listen((message) {
    print("message to recv port:$message");

    receivePort.close(); // we're done, close port so Dart will exit
  });

  final DynamicLibrary dylib = _init();

  final SendPort sendPort2 = convertNativePortToSendPort(dylib, nativePort);

  sendPort2.send("hi from sendport 2");
}

dynamic convertNativePortToSendPort(DynamicLibrary dylib, int nativePort) {
  final convertNativePortPointer =
      dylib.lookup<NativeFunction<_ConvertNativePortToSendPortFunc>>(
          'convertNativePortToSendPort');
  final convertNativePort =
      convertNativePortPointer.asFunction<_ConvertNativePortToSendPort>();
  return convertNativePort(nativePort) as SendPort;
}

DynamicLibrary _init() {
  // Open the dynamic library
  String libraryPath =
      path.join(Directory.current.path, 'native', 'libreturnport.so');
  if (Platform.isMacOS) {
    libraryPath =
        path.join(Directory.current.path, 'native', 'returnport.dylib');
  }
  if (Platform.isWindows) {
    libraryPath =
        path.join(Directory.current.path, 'native', 'Debug', 'returnport.dll');
  }
  final lib = DynamicLibrary.open(libraryPath);

  // need to call this because our native library makes use of dart_api_dl.h, the Dynamically Linked Dart API
  // this code comes from:
  // https://github.com/dart-lang/sdk/blob/main/samples/ffi/sample_ffi_functions_callbacks_closures.dart#L55
  final initializeApi = lib.lookupFunction<IntPtr Function(Pointer<Void>),
      int Function(Pointer<Void>)>("Dart_InitializeApiDL");
  final initResult = initializeApi(NativeApi.initializeApiDLData);

  if (initResult != 0) {
    throw Exception(
        "failed in initialise Dart Native Library Dynamic Link API");
  }
  print("finished DL lib init");
  return lib;
}
