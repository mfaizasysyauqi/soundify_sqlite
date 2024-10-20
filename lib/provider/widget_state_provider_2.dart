import 'package:flutter/material.dart';

// Model untuk Provider
class WidgetStateProvider2 with ChangeNotifier {
  Widget activeWidget2 = Container(); // Default widget
  String widgetName = 'Container'; // Nama widget untuk melacak

  // Getter untuk mendapatkan widget saat ini
  Widget get currentWidget => activeWidget2;

  // Fungsi untuk mengubah widget dan melacak namanya
  void changeWidget(Widget newWidget, String name) {
    activeWidget2 = newWidget;
    widgetName = name; // Simpan nama widget
    notifyListeners(); // Memberitahu Consumer tentang perubahan
  }
}
