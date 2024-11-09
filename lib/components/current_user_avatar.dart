import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundify/provider/profile_provider.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';

// current_user_avatar.dart
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false)
          .loadCurrentUserProfileImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profileImageUrl = profileProvider.currentUserProfileImageUrl;

        return CircleAvatar(
          radius: widget.radius,
          backgroundColor:
              profileImageUrl.isEmpty ? primaryTextColor : tertiaryColor,
          backgroundImage:
              profileImageUrl.isNotEmpty && File(profileImageUrl).existsSync()
                  ? FileImage(File(profileImageUrl))
                  : null,
          child: (profileImageUrl.isEmpty ||
                  !File(profileImageUrl).existsSync())
              ? Icon(Icons.person, color: primaryColor, size: widget.iconSize)
              : null,
        );
      },
    );
  }
}
