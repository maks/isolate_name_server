#include "isolate_name_server.h"

Dart_Handle lookupPortByName(const char* name) {
    Dart_Port port = 0;

    return Dart_NewSendPort(port);;
}

int registerPortWithName(Dart_Port port, const char*  name) {
    return 0;
}

int removePortNameMapping(const char*  name) {
    return 0;
}
