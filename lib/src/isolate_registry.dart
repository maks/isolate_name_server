import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// Based on https://github.com/flutter/engine/blob/main/lib/ui/isolate_name_server.dart

/// Static methods to allow for simple sharing of [SendPort]s across [Isolate]s.
///
/// All isolates share a global mapping of names to ports. An isolate can
/// register a [SendPort] with a given name using [registerPortWithName];
/// another isolate can then look up that port using [lookupPortByName].
///
/// To create a [SendPort], first create a [ReceivePort], then use
/// [ReceivePort.sendPort].
///
/// Since multiple isolates can each obtain the same [SendPort] associated with
/// a particular [ReceivePort], the protocol built on top of this mechanism
/// should typically consist of a single message. If more elaborate two-way
/// communication or multiple-message communication is necessary, it is
/// recommended to establish a separate communication channel in that first
/// message (e.g. by passing a dedicated [SendPort]).
abstract final class IsolateNameServer {
  static final DynamicLibrary _dylib = _init();

  static DynamicLibrary _init() {
    // Open the dynamic library
    String libraryPath =
        path.join(Directory.current.path, 'native', 'libnameserver.so');
    if (Platform.isMacOS) {
      libraryPath =
          path.join(Directory.current.path, 'native', 'libnameserver.dylib');
    }
    if (Platform.isWindows) {
      libraryPath = path.join(
          Directory.current.path, 'native', 'Debug', 'libnameserver.dll');
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

    final initNameServer =
        lib.lookupFunction<IntPtr Function(), int Function()>("initNameServer");

    final initNSResult = initNameServer();
    if (initNSResult != 0) {
      throw Exception("failed in initialise Name Server native lib");
    }

    return lib;
  }

  /// Looks up the [SendPort] associated with a given name.
  ///
  /// Returns null if the name does not exist. To register the name in the first
  /// place, consider [registerPortWithName].
  ///
  /// The `name` argument must not be null.
  static SendPort? lookupPortByName(String name) {
    final lookupPortByNamePointer = _dylib
        .lookup<NativeFunction<_LookupPortByNameFunc>>('lookupPortByName');
    final lookupPortByName =
        lookupPortByNamePointer.asFunction<_LookupPortByName>();
    final port = lookupPortByName(name.toNativeUtf8());
    if (port != null) {
      return port as SendPort;
    } else {
      return null;
    }
  }

  /// Registers a [SendPort] with a given name.
  ///
  /// Returns true if registration is successful, and false if the name entry
  /// already existed (in which case the earlier registration is left
  /// unchanged). To remove a registration, consider [removePortNameMapping].
  ///
  /// Once a port has been registered with a name, it can be obtained from any
  /// [Isolate] using [lookupPortByName].
  ///
  /// Multiple isolates should avoid attempting to register ports with the same
  /// name, as there is an inherent race condition in doing so.
  ///
  /// The `port` and `name` arguments must not be null.
  static bool registerPortWithName(SendPort port, String name) {
    final registerPortWithNamePointer =
        _dylib.lookup<NativeFunction<_RegisterPortWithNameFunc>>(
            'registerPortWithName');
    final registerPortWithName =
        registerPortWithNamePointer.asFunction<_RegisterPortWithName>();
    return registerPortWithName(port.nativePort, name.toNativeUtf8()) == 0;
  }

  /// Removes a name-to-[SendPort] mapping given its name.
  ///
  /// Returns true if the mapping was successfully removed, false if the mapping
  /// did not exist. To add a registration, consider [registerPortWithName].
  ///
  /// Generally, removing a port name mapping is an inherently racy operation
  /// (another isolate could have obtained the name just prior to the name being
  /// removed, and thus would still be able to communicate over the port even
  /// after it has been removed).
  ///
  /// The `name` argument must not be null.
  static bool removePortNameMapping(String name) {
    final removePortNameMappingPointer =
        _dylib.lookup<NativeFunction<_RemovePortNameMappingFunc>>(
            'removePortNameMapping');
    final removePortNameMapping =
        removePortNameMappingPointer.asFunction<_RemovePortNameMapping>();
    return removePortNameMapping(name.toNativeUtf8()) == 0;
  }
}

typedef _LookupPortByNameFunc = Handle Function(Pointer<Utf8> name);
typedef _LookupPortByName = Object? Function(Pointer<Utf8> name);

typedef _RegisterPortWithNameFunc = Int Function(
    Int64 port, Pointer<Utf8> name);
typedef _RegisterPortWithName = int Function(int port, Pointer<Utf8> name);

typedef _RemovePortNameMappingFunc = Int Function(Pointer<Utf8> name);
typedef _RemovePortNameMapping = int Function(Pointer<Utf8> name);
