import 'package:flutter/material.dart';

// Model untuk Provider
class WidgetStateProvider1 with ChangeNotifier {
  Widget _activeWidget1 = Container(); // Default widget
  String _widgetName = 'Container'; // Nama widget untuk melacak

  // Getter untuk mendapatkan widget saat ini
  Widget get currentWidget => _activeWidget1;
  String get widgetName => _widgetName;

  // Fungsi untuk mengubah widget dan melacak namanya
  void changeWidget(Widget newWidget, String name) {
    _activeWidget1 = newWidget;
    _widgetName = name;
    
    notifyListeners(); // Notify listeners immediately after the widget is changed
  }
}
