import 'package:flutter/material.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';

// Model untuk Provider
class WidgetStateProvider2 with ChangeNotifier {
  Widget activeWidget2 = const ShowDetailSong(); // Default widget
  String widgetName = 'ShowDetailSong'; // Nama widget untuk melacak

  // Getter untuk mendapatkan widget saat ini
  Widget get currentWidget => activeWidget2;

  // Fungsi untuk mengubah widget dan melacak namanya
  void changeWidget(Widget newWidget, String name) {
    activeWidget2 = newWidget;
    widgetName = name; // Simpan nama widget
    notifyListeners(); // Memberitahu Consumer tentang perubahan
  }
}
