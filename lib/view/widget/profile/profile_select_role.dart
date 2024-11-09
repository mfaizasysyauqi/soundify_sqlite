import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/provider/profile_provider.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';

OverlayEntry? _overlayEntry;
final DatabaseHelper _db = DatabaseHelper.instance;
bool _mounted = true;

Future<void> showProfileSelectRoleModal(BuildContext context) async {
  try {
    // Access the ProfileProvider
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    void refreshParentProfile() async {
      if (_overlayEntry != null) {
        await profileProvider.refreshCurrentUser();
        _overlayEntry!.markNeedsBuild();
      }
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _closeModal();
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 480,
                    height: 300, // Adjust height as needed
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: tertiaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            // Song image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: profileProvider.bioImageUrl.isEmpty
                                    ? profileProvider.profileImageUrl.isEmpty
                                        ? Container(
                                            color: primaryTextColor,
                                            child: Icon(Icons.library_music,
                                                color: primaryColor, size: 25))
                                        : Image.file(
                                            File(profileProvider
                                                .profileImageUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color: senaryColor,
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.white,
                                                size: 25,
                                              ),
                                            ),
                                          )
                                    : Image.file(
                                        File(profileProvider.bioImageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: senaryColor,
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.white,
                                            size: 25,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Song title and artist name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileProvider.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: mediumWeight,
                                      fontSize: smallFontSize,
                                    ),
                                  ),
                                  Text(
                                    "Select Role",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: quaternaryTextColor,
                                      fontWeight: mediumWeight,
                                      fontSize: microFontSize,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _closeModal();
                              },
                              icon: const Icon(
                                Icons.close,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          thickness: 1,
                          color: primaryTextColor,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: ProfileSelectRole(
                              userId: profileProvider.userId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!); // Show overlay
  } catch (e) {
    print('Error showing profile bio modal: $e');
  }
}

void _closeModal() {
  if (_overlayEntry != null) {
    _overlayEntry!.remove(); // Hapus overlay
    _overlayEntry = null;
  }
}

class ProfileSelectRole extends StatefulWidget {
  final String userId;

  const ProfileSelectRole({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileSelectRole> createState() => _ProfileSelectRoleState();
}

class _ProfileSelectRoleState extends State<ProfileSelectRole> {
  String? _currentUserRole;
  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  // Modifikasi _loadCurrentUserRole untuk juga memuat userId
  Future<void> _loadCurrentUserRole() async {
    try {
      final currentUser = await DatabaseHelper.instance.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _currentUserRole = currentUser.role;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _updateUserRole(String newRole) async {
    try {
      // Get the current user data
      final user = await DatabaseHelper.instance.getUserById(widget.userId);
      if (user == null) return;

      // Create updated user with new role
      final updatedUser = user.copyWith(role: newRole);

      // Update the user in database
      await DatabaseHelper.instance.updateUser(updatedUser);

      // Update the ProfileProvider
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.refreshCurrentUser();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role successfully updated to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating user role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_currentUserRole == "Admin") ...[
          ListTile(
            contentPadding: const EdgeInsets.only(left: 0, right: 0),
            leading: Icon(
              Icons.account_circle,
              color: primaryTextColor,
            ),
            title: Text(
              'Free User',
              style: const TextStyle(
                color: primaryTextColor,
                fontWeight: mediumWeight,
                fontSize: smallFontSize,
              ),
            ),
            subtitle: Text(
              'Access basic features with limited functionality.',
              style: const TextStyle(
                color: quaternaryTextColor,
                fontSize: microFontSize,
              ),
            ),
            onTap: () async {
              await _updateUserRole('Free User');
              _closeModal();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 0, right: 0),
            leading: Icon(
              Icons.workspace_premium,
              color: primaryTextColor,
            ),
            title: Text(
              'Premium User',
              style: const TextStyle(
                color: primaryTextColor,
                fontWeight: mediumWeight,
                fontSize: smallFontSize,
              ),
            ),
            subtitle: Text(
              'Access premium features with unlimited functionality.',
              style: const TextStyle(
                color: quaternaryTextColor,
                fontSize: microFontSize,
              ),
            ),
            onTap: () async {
              await _updateUserRole('Premium User');
              _closeModal();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 0, right: 0),
            leading: Icon(
              Icons.palette,
              color: primaryTextColor,
            ),
            title: Text(
              'Artist',
              style: const TextStyle(
                color: primaryTextColor,
                fontWeight: mediumWeight,
                fontSize: smallFontSize,
              ),
            ),
            subtitle: Text(
              'Access exclusive features designed for artists.',
              style: const TextStyle(
                color: quaternaryTextColor,
                fontSize: microFontSize,
              ),
            ),
            onTap: () async {
              await _updateUserRole('Artist');
              _closeModal();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 0, right: 0),
            leading: Icon(
              Icons.admin_panel_settings,
              color: primaryTextColor,
            ),
            title: Text(
              'Admin',
              style: const TextStyle(
                color: primaryTextColor,
                fontWeight: mediumWeight,
                fontSize: smallFontSize,
              ),
            ),
            subtitle: Text(
              'Full access with platform management capabilities.',
              style: const TextStyle(
                color: quaternaryTextColor,
                fontSize: microFontSize,
              ),
            ),
            onTap: () async {
              await _updateUserRole('Admin');
              _closeModal();
            },
          ),
        ] else ...[
          Text(
            'Hubungi Admin untuk ganti role jadi Premium User atau Artist',
            style: const TextStyle(
              color: primaryTextColor,
              fontWeight: mediumWeight,
              fontSize: smallFontSize,
            ),
          ),
        ]
      ],
    );
  }
}
