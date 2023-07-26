#include "/usr/lib/dart/include/dart_api_dl.h"

Dart_Handle lookupPortByName(const char* name);

int registerPortWithName(Dart_Port port, const char*  name);

int removePortNameMapping(const char*  name);