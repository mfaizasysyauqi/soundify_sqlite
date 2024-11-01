import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/profile_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/view/container/primary/other_profile_container.dart';
import 'package:soundify/view/container/primary/personal_profile_container.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';

OverlayEntry? _overlayEntry;

Future<void> showFollowingModal(BuildContext context) async {
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
                                    "Following",
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
                          child: profileProvider.following.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No following yet',
                                    style: TextStyle(
                                      color: quaternaryTextColor,
                                      fontSize: smallFontSize,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: profileProvider.following.length,
                                  itemBuilder: (context, index) {
                                    final followingId =
                                        profileProvider.following[index];
                                    return MultiProvider(
                                      providers: [
                                        ChangeNotifierProvider(
                                          create: (_) => ProfileProvider()
                                            ..loadUserById(followingId),
                                        ),
                                      ],
                                      child: FollowingListItem(
                                        followingId: followingId,
                                        onFollowStatusChanged:
                                            refreshParentProfile,
                                        onTap: () {
                                          print(
                                              'Tapped following: $followingId');
                                        },
                                      ),
                                    );
                                  },
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

class FollowingListItem extends StatefulWidget {
  final String followingId;
  final VoidCallback onTap;
  final VoidCallback onFollowStatusChanged; // Add this

  const FollowingListItem({
    required this.followingId,
    required this.onTap,
    required this.onFollowStatusChanged, // Add this
    Key? key,
  }) : super(key: key);

  @override
  State<FollowingListItem> createState() => _FollowingListItemState();
}

class _FollowingListItemState extends State<FollowingListItem> {
  bool _mounted = true;
  late ProfileProvider _profileProvider;
  bool _isProviderInitialized = false;
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isProviderInitialized) {
      _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _isProviderInitialized = true;
      _checkIfFollow();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted || !_isProviderInitialized) return;

    setState(() {});

    try {
      await _profileProvider.loadUserById(widget.followingId);
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _checkIfFollow() async {
    try {
      User? currentUser = await _db.getCurrentUser();
      if (currentUser == null || !_mounted) return;

      final isFollowing =
          await _db.isFollowing(currentUser.userId, widget.followingId);

      if (_mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });

        await _profileProvider.loadUserById(widget.followingId);
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _handleFollowUnfollow() async {
    if (!_mounted || !_isProviderInitialized) return;

    try {
      User? currentUser = await _db.getCurrentUser();
      if (currentUser == null) return;

      bool success;

      if (_isFollowing) {
        // Only update the follow relationship in the database
        success =
            await _db.unfollowUser(currentUser.userId, widget.followingId);
      } else {
        success = await _db.followUser(currentUser.userId, widget.followingId);
      }

      if (success && _mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });

        // Only refresh the profile we're viewing
        await _profileProvider.refreshCurrentUser();
      }
    } catch (e) {
      print('Error handling follow/unfollow: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return FutureBuilder<User?>(
          future: DatabaseHelper.instance.getUserById(widget.followingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircleAvatar(
                  child: CircularProgressIndicator(),
                ),
                title: Text('Loading...'),
              );
            }

            final user = snapshot.data;
            if (user == null) {
              return const ListTile(
                title: Text('User not found'),
              );
            }
            return FutureBuilder<User?>(
              future: DatabaseHelper.instance.getCurrentUser(),
              builder: (context, currentUserSnapshot) {
                final currentUser = currentUserSnapshot.data;
                final isCurrentUser = currentUser?.userId == user.userId;

                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 0, right: 0),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: user.profileImageUrl.isEmpty
                        ? primaryTextColor
                        : tertiaryColor,
                    backgroundImage: user.profileImageUrl.isNotEmpty &&
                            File(user.profileImageUrl).existsSync()
                        ? FileImage(File(user.profileImageUrl))
                        : null,
                    child: user.profileImageUrl.isEmpty ||
                            !File(user.profileImageUrl).existsSync()
                        ? Icon(Icons.person, color: primaryColor)
                        : null,
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                      fontSize: smallFontSize,
                    ),
                  ),
                  subtitle: Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: quaternaryTextColor,
                      fontSize: microFontSize,
                    ),
                  ),
                  trailing: isCurrentUser
                      ? null // Tidak menampilkan tombol follow jika user sendiri
                      : TextButton(
                          onPressed: _handleFollowUnfollow,
                          style: TextButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isFollowing ? 'Unfollow' : 'Follow',
                            style: const TextStyle(
                              color: primaryTextColor,
                              fontSize: microFontSize,
                            ),
                          ),
                        ),
                  onTap: () {
                    if (!isCurrentUser) {
                      Provider.of<WidgetStateProvider1>(context, listen: false)
                          .changeWidget(
                        OtherProfileContainer(userId: widget.followingId),
                        'OtherProfileContainer',
                      );
                    } else if (isCurrentUser) {
                      Provider.of<WidgetStateProvider1>(context, listen: false)
                          .changeWidget(
                        PersonalProfileContainer(userId: widget.followingId),
                        'PersonalProfileContainer',
                      );
                    }
                    _closeModal();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
