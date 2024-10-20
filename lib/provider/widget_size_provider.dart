import 'package:flutter/material.dart';

// Assuming you have a WidgetStateProvider1, let's modify it or create a new provider
class WidgetSizeProvider extends ChangeNotifier {
  double _expandedWidth = 0;
  Widget _currentWidget = Container(); // Default widget

  double get expandedWidth => _expandedWidth;
  Widget get currentWidget => _currentWidget;

  void updateExpandedWidth(double width) {
    _expandedWidth = width;
    notifyListeners();
  }

  void updateCurrentWidget(Widget widget) {
    _currentWidget = widget;
    notifyListeners();
  }
}