import 'package:flutter/material.dart';

class ImageProviderData extends ChangeNotifier {
  String? _imagePath;

  String? get imagePath => _imagePath;

  void setImageData(String imagePath) {
    _imagePath = imagePath;

    notifyListeners(); // Notifikasi perubahan
  }

  void clearImageData() {
    _imagePath = null;

    notifyListeners();
  }
}
