#include "/usr/lib/dart/include/dart_api_dl.h"

Dart_Handle convertNativePortToSendPort(Dart_Port port) {
  // The API is also available via our `include/dart_api_dl.h` surface.
  return Dart_NewSendPort(port);
}