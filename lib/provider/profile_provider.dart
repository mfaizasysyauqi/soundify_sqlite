// profile_provider.dart

import 'package:flutter/foundation.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/models/user.dart';

class ProfileProvider with ChangeNotifier {
  // Private fields
  User? _currentUser;
  bool _isLoading = false;
  bool _disposed = false;
  String? currentLoadedUserId; // Tambahkan variabel ini

  // Public getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // User property getters
  String get username => _currentUser?.username ?? '';
  String get fullName => _currentUser?.fullName ?? '';
  String get profileImageUrl => _currentUser?.profileImageUrl ?? '';
  String get bioImageUrl => _currentUser?.bioImageUrl ?? '';
  String get bio => _currentUser?.bio ?? '';
  List<String> get followers => _currentUser?.followers ?? [];
  List<String> get following => _currentUser?.following ?? [];

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void clearCurrentUser() {
    _currentUser = null;
    currentLoadedUserId = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser != null && !_disposed && currentLoadedUserId != null) {
      try {
        final refreshedUser =
            await DatabaseHelper.instance.getUserById(currentLoadedUserId!);
        if (refreshedUser != null && !_disposed) {
          _currentUser = refreshedUser;
          notifyListeners();
        }
      } catch (e) {
        print('Error refreshing current user: $e');
      }
    }
  }

  // Tambahkan method baru untuk memperbarui data followers/following
  Future<void> updateFollowerCount(String userId) async {
    try {
      if (currentLoadedUserId == userId) {
        final updatedUser = await DatabaseHelper.instance.getUserById(userId);
        if (updatedUser != null && !_disposed) {
          _currentUser = updatedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating follower count: $e');
    }
  }

  Future<void> loadUserById(String userId) async {
    // Tambahkan pengecekan untuk mencegah reload yang tidak perlu
    if (currentLoadedUserId == userId && _currentUser != null) {
      return;
    }

    if (_disposed || _isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final user = await DatabaseHelper.instance.getUserById(userId);

      if (!_disposed) {
        _currentUser = user;
        currentLoadedUserId = userId; // Set ID user yang sedang dimuat
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Add method to handle both bio and bio image update
  // In ProfileProvider
  Future<void> updateBioWithImage({
    String? bio,
    String? bioImagePath,
  }) async {
    if (_currentUser == null) return;

    try {
      String? newBioImageUrl = _currentUser!.bioImageUrl;

      if (bioImagePath != null) {
        // Menggunakan saveBioImage bukan saveProfileImage
        newBioImageUrl = await FileStorageHelper.instance
            .saveBioImage(_currentUser!.userId, bioImagePath);
      }

      final updatedUser = _currentUser!.copyWith(
        bio: bio ?? _currentUser!.bio,
        bioImageUrl: newBioImageUrl,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating bio with image: $e');
      rethrow;
    }
  }

  // Add method to handle profile complete update
  Future<void> updateProfileComplete({
    String? username,
    String? fullName,
    String? profileImagePath,
  }) async {
    if (_currentUser == null) return;

    try {
      String? newProfileImageUrl = _currentUser!.profileImageUrl;

      if (profileImagePath != null) {
        newProfileImageUrl = await FileStorageHelper.instance
            .saveProfileImage(_currentUser!.userId, profileImagePath);
      }

      final updatedUser = _currentUser!.copyWith(
        username: username ?? _currentUser!.username,
        fullName: fullName ?? _currentUser!.fullName,
        profileImageUrl: newProfileImageUrl,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating profile complete: $e');
      rethrow;
    }
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.getCurrentUser();
      _currentUser = user;
    } catch (e) {
      print('Error loading current user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? profileImageUrl,
    String? bioImageUrl,
    String? bio,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        username: username ?? _currentUser!.username,
        fullName: fullName ?? _currentUser!.fullName,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        bioImageUrl: bioImageUrl ?? _currentUser!.bioImageUrl,
        bio: bio ?? _currentUser!.bio,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Add the missing methods

  Future<void> deleteBioImage() async {
    if (_currentUser == null) return;

    try {
      // Delete the actual image file
      if (_currentUser!.bioImageUrl.isNotEmpty) {
        await FileStorageHelper.instance.deleteImage(_currentUser!.bioImageUrl);
      }

      // Update user with empty bio image URL
      await updateProfile(bioImageUrl: '');
    } catch (e) {
      print('Error deleting bio image: $e');
      rethrow;
    }
  }

  Future<void> updateBio({
    String? bio,
    String? bioImageUrl,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        bio: bio ?? _currentUser!.bio,
        bioImageUrl: bioImageUrl ?? _currentUser!.bioImageUrl,
        // Tidak perlu menyertakan properti lain yang tidak diubah
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating bio: $e');
      rethrow;
    }
  }

  Future<void> deleteProfileImage() async {
    if (_currentUser == null) return;

    try {
      // Delete the actual image file
      if (_currentUser!.profileImageUrl.isNotEmpty) {
        await FileStorageHelper.instance
            .deleteImage(_currentUser!.profileImageUrl);
      }

      // Update user with empty profile image URL
      await updateProfile(profileImageUrl: '');
    } catch (e) {
      print('Error deleting profile image: $e');
      rethrow;
    }
  }

  Future<void> updateFollowers(String followerId, bool isFollowing) async {
    if (_currentUser == null) return;

    try {
      List<String> updatedFollowers = List.from(_currentUser!.followers);
      if (isFollowing) {
        if (!updatedFollowers.contains(followerId)) {
          updatedFollowers.add(followerId);
        }
      } else {
        updatedFollowers.remove(followerId);
      }

      final updatedUser = _currentUser!.copyWith(followers: updatedFollowers);
      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating followers: $e');
      rethrow;
    }
  }

  Future<void> updateFollowing(String userId, bool isFollowing) async {
    if (_currentUser == null) return;

    try {
      List<String> updatedFollowing = List.from(_currentUser!.following);
      if (isFollowing) {
        if (!updatedFollowing.contains(userId)) {
          updatedFollowing.add(userId);
        }
      } else {
        updatedFollowing.remove(userId);
      }

      final updatedUser = _currentUser!.copyWith(following: updatedFollowing);
      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating following: $e');
      rethrow;
    }
  }
}
