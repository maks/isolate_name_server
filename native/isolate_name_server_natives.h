
#include <string>

namespace flutter {

class IsolateNameServerNatives {
 public:
  static Dart_Handle LookupPortByName(const std::string& name);
  static bool RegisterPortWithName(Dart_Handle port_handle,
                                   const std::string& name);
  static bool RemovePortNameMapping(const std::string& name);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_ISOLATE_NAME_SERVER_NATIVES_H_