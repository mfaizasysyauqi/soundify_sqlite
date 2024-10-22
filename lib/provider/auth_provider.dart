import 'package:flutter/foundation.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';


class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? get currentUserId => _currentUser?.userId;
  
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

  bool get isAuthenticated => _currentUser != null;
}