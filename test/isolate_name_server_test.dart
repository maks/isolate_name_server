import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:test/test.dart';

void main() {
  group('native registry tests', () {
    final ReceivePort receivePort = ReceivePort();
    final SendPort sendPort = receivePort.sendPort;

    setUp(() {});

    test('adding a new entry works', () {
      final portName = "tester";
      final result = IsolateNameServer.registerPortWithName(sendPort, portName);
      expect(result, isTrue);
    });

    test('adding an existing entry returns false', () {
      final portName = "tester";
      IsolateNameServer.registerPortWithName(sendPort, portName);
      final result = IsolateNameServer.registerPortWithName(sendPort, portName);
      expect(result, isFalse);
    });

    test('looking up an non existing entry works', () {
      final foundPort = IsolateNameServer.lookupPortByName("foo");
      expect(foundPort == sendPort, isFalse);
    });

    test('looking up an existing entry finds it', () {
      final portName = "tester";
      IsolateNameServer.registerPortWithName(sendPort, portName);
      final foundPort = IsolateNameServer.lookupPortByName(portName);
      expect(foundPort == sendPort, isTrue);
    });

    test('removing an existing entry works', () {
      final portName = "tester";
      IsolateNameServer.registerPortWithName(sendPort, portName);
      final result = IsolateNameServer.removePortNameMapping(portName);
      expect(result, isTrue);
    });

    test('removing non existing entry works', () {
      final portName = "tester";
      final result = IsolateNameServer.removePortNameMapping(portName);
      expect(result, isFalse);
    });

    test('removing an existing entry makes it no longer accessible', () {
      final portName = "tester";
      IsolateNameServer.registerPortWithName(sendPort, portName);
      IsolateNameServer.removePortNameMapping(portName);
      final found = IsolateNameServer.lookupPortByName(portName);
      expect(found, isNull);
    });

    test('lookup works across Isolates', () async {
      final portName = "tester";
      ReceivePort rp = ReceivePort();
      IsolateNameServer.registerPortWithName(rp.sendPort, portName);

      Isolate.spawn((_) {
        final found = IsolateNameServer.lookupPortByName(portName);
        found?.send("x");
      }, null);

      expect(IsolateNameServer.lookupPortByName(portName), isNotNull);

      bool gotMesg = false;
      rp.listen((message) => gotMesg = true);

      await Future.delayed(Duration(seconds: 1));

      expect(gotMesg, isTrue);
    });
  });
}
