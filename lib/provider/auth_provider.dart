import 'package:flutter/foundation.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';


class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _currentUserRole;

  String? get currentUserId =>  _currentUser?.userId;
  String? get currentUserRole => _currentUserRole;
  Future<void> initializeUser() async {
    _currentUser = await DatabaseHelper.instance.getCurrentUser();
    notifyListeners();
  }

  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    await DatabaseHelper.instance.setCurrentUserId(user.userId);
    notifyListeners();
  }

  Future<void> clearCurrentUser() async {
    _currentUser = null;
    await DatabaseHelper.instance.clearSession();
    notifyListeners();
  }

  // Method untuk mendapatkan role user saat ini
  Future<String?> getCurrentUserRole() async {
    try {
      final user = await DatabaseHelper.instance.getCurrentUser();
      _currentUserRole = user?.role;
      notifyListeners();
      return _currentUserRole;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  bool get isAuthenticated => _currentUser != null;
}