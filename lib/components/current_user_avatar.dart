import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/view/style/style.dart';

class CurrentUserAvatar extends StatefulWidget {
  final double radius;
  final double iconSize;

  const CurrentUserAvatar({
    Key? key,
    this.radius = 20,
    this.iconSize = 20,
  }) : super(key: key);

  @override
  State<CurrentUserAvatar> createState() => _CurrentUserAvatarState();
}

class _CurrentUserAvatarState extends State<CurrentUserAvatar> {
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await DatabaseHelper.instance.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _profileImageUrl = currentUser.profileImageUrl;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: _profileImageUrl.isEmpty
          ? primaryTextColor
          : tertiaryColor,
      backgroundImage: _profileImageUrl.isNotEmpty &&
              File(_profileImageUrl).existsSync()
          ? FileImage(File(_profileImageUrl))
          : null,
      child: (_profileImageUrl.isEmpty ||
              !File(_profileImageUrl).existsSync())
          ? Icon(Icons.person,
              color: primaryColor, size: widget.iconSize)
          : null,
    );
  }
}
