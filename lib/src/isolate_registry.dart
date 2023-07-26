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
    String libraryPath = path.join(Directory.current.path, 'nameserver_library', 'libnameserver.so');
    if (Platform.isMacOS) {
      libraryPath = path.join(Directory.current.path, 'nameserver_library', 'libnameserver.dylib');
    }
    if (Platform.isWindows) {
      libraryPath = path.join(Directory.current.path, 'nameserver_library', 'Debug', 'libnameserver.dll');
    }
    return DynamicLibrary.open(libraryPath);
  }

  /// Looks up the [SendPort] associated with a given name.
  ///
  /// Returns null if the name does not exist. To register the name in the first
  /// place, consider [registerPortWithName].
  ///
  /// The `name` argument must not be null.
  static SendPort? lookupPortByName(String name) {
    final lookupPortByNamePointer = _dylib.lookup<NativeFunction<_LookupPortByNameFunc>>('lookupPortByName');
    final lookupPortByName = lookupPortByNamePointer.asFunction<_LookupPortByName>();
    return lookupPortByName(name.toNativeUtf8());
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
        _dylib.lookup<NativeFunction<_RegisterPortWithNameFunc>>('registerPortWithName');
    final registerPortWithName = registerPortWithNamePointer.asFunction<_RegisterPortWithName>();
    return registerPortWithName(port.nativePort, name.toNativeUtf8());
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
        _dylib.lookup<NativeFunction<_RemovePortNameMappingFunc>>('removePortNameMapping');
    final removePortNameMapping = removePortNameMappingPointer.asFunction<_RemovePortNameMapping>();
    return removePortNameMapping(name.toNativeUtf8());
  }
}

typedef _LookupPortByNameFunc = Int64 Function(Pointer<Utf8> name);
typedef _LookupPortByName = int Function(Pointer<Utf8> name);

typedef _RegisterPortWithNameFunc = Bool Function(Int64 port, Pointer<Utf8> name);
typedef _RegisterPortWithName = bool Function(int port, Pointer<Utf8> name);

typedef _RemovePortNameMappingFunc = Bool Function(Pointer<Utf8> name);
typedef _RemovePortNameMapping = bool Function(Pointer<Utf8> name);
