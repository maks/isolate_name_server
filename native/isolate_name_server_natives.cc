// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "isolate_name_server_natives.h"

#include <string>

#include "isolate_name_server.h"

namespace flutter {

Dart_Handle IsolateNameServerNatives::LookupPortByName(
    const std::string& name) {
  auto name_server = UIDartState::Current()->GetIsolateNameServer();
  if (!name_server) {
    return Dart_Null();
  }
  Dart_Port port = name_server->LookupIsolatePortByName(name);
  if (port == ILLEGAL_PORT) {
    return Dart_Null();
  }
  return Dart_NewSendPort(port);
}

bool IsolateNameServerNatives::RegisterPortWithName(Dart_Handle port_handle,
                                                    const std::string& name) {
  auto name_server = UIDartState::Current()->GetIsolateNameServer();
  if (!name_server) {
    return false;
  }
  Dart_Port port = ILLEGAL_PORT;
  Dart_SendPortGetId(port_handle, &port);
  if (!name_server->RegisterIsolatePortWithName(port, name)) {
    return false;
  }
  return true;
}

bool IsolateNameServerNatives::RemovePortNameMapping(const std::string& name) {
  auto name_server = UIDartState::Current()->GetIsolateNameServer();
  if (!name_server || !name_server->RemoveIsolateNameMapping(name)) {
    return false;
  }
  return true;
}

}  // namespace flutter