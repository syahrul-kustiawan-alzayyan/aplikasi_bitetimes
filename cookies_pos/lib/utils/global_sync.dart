import 'package:flutter/foundation.dart';

class GlobalSync extends ChangeNotifier {
  static final GlobalSync _instance = GlobalSync._internal();
  factory GlobalSync() => _instance;
  GlobalSync._internal();

  static GlobalSync get instance => _instance;

  void notify() {
    notifyListeners();
  }
}
