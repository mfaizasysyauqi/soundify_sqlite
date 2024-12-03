import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/profile_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/utils/sticky_header_delegate.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/profile/profile_album_list.dart';
import 'package:soundify/view/widget/profile/profile_followers_list.dart';
import 'package:soundify/view/widget/profile/profile_following_list.dart';
import 'package:soundify/view/widget/profile/profile_playlist_list.dart';
import 'package:soundify/view/widget/profile/profile_select_role.dart';
import 'package:soundify/view/widget/song_list.dart';

class OtherProfileContainer extends StatefulWidget {
  final String userId;

  const OtherProfileContainer({
    super.key,
    required this.userId,
  });

  @override
  State<OtherProfileContainer> createState() => _OtherProfileContainerState();
}

OverlayEntry? _overlayEntry;

class _OtherProfileContainerState extends State<OtherProfileContainer> {
  bool _mounted = true;
  late ProfileProvider _profileProvider; // Keep it non-nullable but late
  bool _isProviderInitialized = false; // Add flag to track initialization
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isSongClicked = true;
  bool _isHaveSong = true;
  bool _isAlbumClicked = false;
  bool _isHaveAlbum = false;
  bool _isPlaylistClicked = false;
  bool _isHavePlaylist = false;
  bool _isLoading = false;
  bool _isFollowing = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        _initializeAsync();
      }
    });
    _loadCurrentUserData();
  }

  // Tambahkan method untuk memuat data current user
  Future<void> _loadCurrentUserData() async {
    try {
      final currentUser = await DatabaseHelper.instance.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _currentUserRole = currentUser.role;
        });
      }
    } catch (e) {
      print('Error loading current user data: $e');
    }
  }

  Future<void> _initializeAsync() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (!_isProviderInitialized) {
        _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        _isProviderInitialized = true;
        await _profileProvider.loadUserById(widget.userId);
        await _checkIfFollow();
      }
      await _checkUserContent();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(OtherProfileContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _resetState();
      _initializeAsync();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mounted && !_isProviderInitialized) {
      _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _isProviderInitialized = true;
      _checkIfFollow();
      _profileProvider.addListener(_onProfileUpdate);
    }
  }

  void _onProfileUpdate() {
    if (_mounted) {
      refreshProfile();
    }
  }

  Future<void> refreshProfile() async {
    if (!mounted || !_isProviderInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileProvider.loadUserById(widget.userId);
      await _checkIfFollow();
      await _checkUserContent();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mounted = false;
    if (_isProviderInitialized) {
      _profileProvider.removeListener(_onProfileUpdate);
    }
    super.dispose();
  }

  Future<void> _showProfileBioModal(BuildContext context) async {
    try {
      // Access the ProfileProvider
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

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
                                                  color: primaryColor,
                                                  size: 25))
                                          : Image.file(
                                              File(profileProvider
                                                  .profileImageUrl),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
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
                                      'Bio',
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
                            // Make the scrollable area expand
                            child: SingleChildScrollView(
                              child: Text(
                                profileProvider.bio,
                                style: const TextStyle(
                                  color: quaternaryTextColor,
                                  fontWeight: mediumWeight,
                                  fontSize: microFontSize,
                                ),
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

  Future<void> _initializeData() async {
    if (!mounted || !_isProviderInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileProvider.loadUserById(widget.userId);
      await _checkUserContent();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUserContent() async {
    await Future.wait([
      checkIfUserHasSong(),
      checkIfUserHasAlbum(),
      checkIfUserHasPlaylist(),
    ]);
  }

  Future<void> _checkIfFollow() async {
    try {
      User? currentUser = await _db.getCurrentUser();
      if (currentUser == null || !_mounted) return;

      final isFollowing =
          await _db.isFollowing(currentUser.userId, widget.userId);

      if (_mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });

        // Refresh provider data
        await _profileProvider.loadUserById(widget.userId);
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> checkIfUserHasSong() async {
    try {
      final songs = await _db.getSongsByArtist(widget.userId);
      if (!mounted) return;
      setState(() {
        _isHaveSong = songs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking songs: $e');
    }
  }

  Future<void> checkIfUserHasAlbum() async {
    try {
      final albums = await _db.getAlbumByCreatorId(widget.userId);
      if (!mounted) return;
      setState(() {
        _isHaveAlbum = albums != null;
      });
    } catch (e) {
      print('Error checking albums: $e');
    }
  }

  Future<void> checkIfUserHasPlaylist() async {
    try {
      final playlists = await _db.getPlaylists();
      final userPlaylists =
          playlists.where((p) => p.creatorId == widget.userId);
      if (!mounted) return;
      setState(() {
        _isHavePlaylist = userPlaylists.isNotEmpty;
      });
    } catch (e) {
      print('Error checking playlists: $e');
    }
  }

  void onSongClicked() {
    setState(() {
      _isSongClicked = true;
      _isAlbumClicked = false;
      _isPlaylistClicked = false;
    });
  }

  void onAlbumClicked() {
    setState(() {
      _isSongClicked = false;
      _isAlbumClicked = true;
      _isPlaylistClicked = false;
    });
  }

  void onPlaylistClicked() {
    setState(() {
      _isSongClicked = false;
      _isAlbumClicked = false;
      _isPlaylistClicked = true;
    });
  }

  Future<void> _handleFollowUnfollow() async {
    if (!_mounted || !_isProviderInitialized) return;

    try {
      User? currentUser = await _db.getCurrentUser();
      if (currentUser == null) return;

      bool success;

      if (_isFollowing) {
        // Only update the follow relationship in the database
        success = await _db.unfollowUser(currentUser.userId, widget.userId);
      } else {
        success = await _db.followUser(currentUser.userId, widget.userId);
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
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = profileProvider.currentUser;
        if (user == null) {
          return const Center(child: Text('User not found'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return _buildResponsiveLayout(
                context, constraints, profileProvider);
          },
        );
      },
    );
  }

  Widget _buildResponsiveLayout(BuildContext context,
      BoxConstraints constraints, ProfileProvider profileProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    const minContentWidth = 360.0;
    final providedMaxWidth =
        Provider.of<WidgetSizeProvider>(context).expandedWidth;
    final adjustedMaxWidth =
        providedMaxWidth.clamp(minContentWidth, double.infinity);

    final isSmallScreen = constraints.maxWidth < 800;
    final isMediumScreen = constraints.maxWidth >= 800;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        backgroundColor: primaryColor,
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minContentWidth,
              maxWidth: screenWidth.clamp(minContentWidth, adjustedMaxWidth),
            ),
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildProfileSection(
                        isSmallScreen, isMediumScreen, profileProvider),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyHeaderDelegate(
                      child: Column(
                        children: [
                          _buildHeaderSection(isMediumScreen),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Divider(color: primaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: _buildList(),
            ),
          ),
        ),
      ),
    );
  }

  // Modify _buildProfileSection to use ProfileProvider
  Widget _buildProfileSection(bool isSmallScreen, bool isMediumScreen,
      ProfileProvider profileProvider) {
    if (isSmallScreen) {
      return _buildSmallScreenProfile(profileProvider);
    } else {
      return _buildMediumScreenProfile(profileProvider);
    }
  }

  Widget _buildHeaderSection(bool isMediumScreen) {
    return Column(
      children: [
        if (_isHaveSong && _isSongClicked) _buildSongHeader(isMediumScreen),
        if (_isHaveAlbum && _isAlbumClicked) _buildAlbumHeader(isMediumScreen),
        if (_isHavePlaylist && _isPlaylistClicked)
          _buildPlaylistHeader(isMediumScreen),
      ],
    );
  }

  // Update profile display methods to use profileProvider
  Widget _buildSmallScreenProfile(ProfileProvider profileProvider) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: (profileProvider.profileImageUrl.isEmpty)
                    ? primaryTextColor
                    : tertiaryColor,
                backgroundImage: profileProvider.profileImageUrl.isNotEmpty &&
                        File(profileProvider.profileImageUrl).existsSync()
                    ? FileImage(File(profileProvider.profileImageUrl))
                    : null,
                child: (profileProvider.profileImageUrl.isEmpty ||
                        !File(profileProvider.profileImageUrl).existsSync())
                    ? Icon(Icons.person, color: primaryColor, size: 50)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    if (!mounted) return;
                    _handleFollowUnfollow(); // Call the function properly
                  },
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor:
                        _isFollowing ? quinaryColor : tertiaryTextColor,
                    child: Icon(
                      _isFollowing ? Icons.star : Icons.star_border,
                      color: primaryTextColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('@${profileProvider.username}',
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: smallFontSize,
              )),
          Text(profileProvider.fullName,
              style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: mediumFontSize,
                  fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => showProfileFollowersModal(
                  context,
                ),
                child: Text(
                  'Followers: ${profileProvider.followers.length}',
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: smallFontSize,
                  ),
                ),
              ),
              Text(
                ' | ',
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: smallFontSize,
                ),
              ),
              GestureDetector(
                onTap: () => showProfileFollowingModal(context),
                child: Text(
                  'Following: ${profileProvider.following.length}',
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: smallFontSize,
                  ),
                ),
              ),

              // Tampilkan role hanya jika current user adalah Admin
              if (_currentUserRole == 'Admin') ...[
                Text(
                  ' | ',
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: smallFontSize,
                  ),
                ),
                GestureDetector(
                  onTap: () => showProfileSelectRoleModal(context),
                  child: Text(
                    'Role: ${profileProvider.currentUser?.role ?? ""}',
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (profileProvider.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 90.0),
              child: IntrinsicWidth(
                child: RichText(
                  text: TextSpan(
                    text: profileProvider.bio,
                    style: TextStyle(
                      color: quaternaryTextColor,
                      fontWeight: mediumWeight,
                      fontSize: smallFontSize,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        _showProfileBioModal(context);
                      },
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          _buildActionButtons(useRow: true),
        ],
      ),
    );
  }

  Widget _buildMediumScreenProfile(ProfileProvider profileProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 75,
                backgroundColor: (profileProvider.profileImageUrl.isEmpty)
                    ? primaryTextColor
                    : tertiaryColor,
                backgroundImage: profileProvider.profileImageUrl.isNotEmpty &&
                        File(profileProvider.profileImageUrl).existsSync()
                    ? FileImage(File(profileProvider.profileImageUrl))
                    : null,
                child: (profileProvider.profileImageUrl.isEmpty ||
                        !File(profileProvider.profileImageUrl).existsSync())
                    ? Icon(Icons.person, color: primaryColor, size: 75)
                    : null,
              ),
              // In _buildMediumScreenProfile method, modify the onTap handler:
              Positioned(
                bottom: 7,
                right: 7,
                child: GestureDetector(
                  onTap: () {
                    if (!mounted) return;
                    _handleFollowUnfollow(); // Call the function properly
                  },
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor:
                        _isFollowing ? quinaryColor : tertiaryTextColor,
                    child: Icon(
                      _isFollowing ? Icons.star : Icons.star_border,
                      color: primaryTextColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileProvider.bio.isNotEmpty
                  ? const SizedBox(
                      height: 7,
                    )
                  : const SizedBox(
                      height: 14,
                    ),
              Text('@${profileProvider.username}',
                  style: const TextStyle(
                      color: primaryTextColor, fontSize: smallFontSize)),
              Text(
                profileProvider.fullName,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: profileProvider.bio.isNotEmpty
                      ? extraHugeFontSize
                      : superHugeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => showProfileFollowersModal(context),
                    child: Text(
                      'Followers: ${profileProvider.followers.length}',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: smallFontSize,
                      ),
                    ),
                  ),
                  Text(
                    ' | ',
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: smallFontSize,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showProfileFollowingModal(context),
                    child: Text(
                      'Following: ${profileProvider.following.length}',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: smallFontSize,
                      ),
                    ),
                  ),
                  // Tampilkan role hanya jika current user adalah Admin
                  if (_currentUserRole == 'Admin') ...[
                    Text(
                      ' | ',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: smallFontSize,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showProfileSelectRoleModal(context),
                      child: Text(
                        'Role: ${profileProvider.currentUser?.role ?? ""}',
                        style: const TextStyle(
                          color: primaryTextColor,
                          fontSize: smallFontSize,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (profileProvider.bio.isNotEmpty)
                IntrinsicWidth(
                  child: RichText(
                    text: TextSpan(
                      text: profileProvider.bio,
                      style: TextStyle(
                        color: senaryColor, // quaternaryTextColor
                        fontWeight: mediumWeight,
                        fontSize: smallFontSize,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          _showProfileBioModal(context);
                        },
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons({bool useRow = false}) {
    final List<Widget> buttons = [
      SizedBox(
        height: 28,
      ),
      if (_isHaveSong)
        IconButton(
          icon: const Icon(Icons.music_note, color: primaryTextColor),
          onPressed: onSongClicked,
        ),
      if (_isHaveAlbum)
        IconButton(
          icon: const Icon(Icons.album, color: primaryTextColor),
          onPressed: onAlbumClicked,
        ),
      if (_isHavePlaylist)
        IconButton(
          icon: const Icon(Icons.library_music, color: primaryTextColor),
          onPressed: onPlaylistClicked,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
      ),
      child: useRow
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttons,
            )
          : Column(
              children: buttons,
            ),
    );
  }

  Widget _buildSongHeader(bool isLargeScreen) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Table(
        border: TableBorder.all(
          color: transparentColor, // Warna border sementara
          width: 1, // Ketebalan border
        ),
        columnWidths: {
          0: const FixedColumnWidth(50), // Lebar tetap untuk kolom #
          1: const FlexColumnWidth(2), // Kolom Title lebih besar
          2: screenWidth > 1280
              ? const FlexColumnWidth(2)
              : const FixedColumnWidth(0),
          3: screenWidth > 1480
              ? const FlexColumnWidth(2)
              : const FixedColumnWidth(0),
          4: const FixedColumnWidth(168), // Kolom Icon untuk durasi
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: transparentColor), // Border per sel
                ),
                child: const Text(
                  "#",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: transparentColor), // Border per sel
                ),
                child: const Text(
                  'Title',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                ),
              ),
              if (screenWidth > 1280)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: transparentColor), // Border per sel
                  ),
                  child: const Text(
                    "Album",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Kosong jika layar kecil
              if (screenWidth > 1480)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: transparentColor), // Border per sel
                  ),
                  child: const Text(
                    "Date added",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Kosong jika layar kecil
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 45,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: transparentColor), // Border per sel
                    ),
                    child: const SizedBox(
                      width: 50,
                      child: Align(
                        child: Icon(
                          Icons.access_time,
                          color: primaryTextColor,
                        ),
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumHeader(bool isLargeScreen) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Table(
        border: TableBorder.all(
          color: transparentColor, // Warna border sementara
          width: 1, // Ketebalan border
        ),
        columnWidths: {
          0: const FixedColumnWidth(50), // Lebar tetap untuk kolom #
          1: const FlexColumnWidth(2), // Kolom Title lebih besar
          2: screenWidth > 1280
              ? const FlexColumnWidth(2)
              : const FixedColumnWidth(0),
          3: screenWidth > 1480
              ? const FlexColumnWidth(2)
              : const FixedColumnWidth(0),
          4: const FixedColumnWidth(168), // Kolom Icon untuk durasi
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: transparentColor), // Border per sel
                ),
                child: const Text(
                  "#",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: transparentColor), // Border per sel
                ),
                child: const Text(
                  'Title',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                ),
              ),
              if (screenWidth > 1280)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: transparentColor), // Border per sel
                  ),
                  child: const Text(
                    "Songs",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Kosong jika layar kecil
              if (screenWidth > 1480)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: transparentColor), // Border per sel
                  ),
                  child: const Text(
                    "Date added",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Kosong jika layar kecil
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 45,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: transparentColor), // Border per sel
                    ),
                    child: const SizedBox(
                      width: 50,
                      child: Align(
                        child: Icon(
                          Icons.access_time,
                          color: primaryTextColor,
                        ),
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader(bool isLargeScreen) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Table(
        border: TableBorder.all(
          color: transparentColor, // Warna border sementara
          width: 1, // Ketebalan border
        ),
        columnWidths: {
          0: const FixedColumnWidth(50), // Lebar tetap untuk kolom #
          1: const FlexColumnWidth(2), // Kolom Title lebih besar
          2: screenWidth > 1280
              ? const FlexColumnWidth(2)
              : const FixedColumnWidth(0),
          3: screenWidth > 1480
              ? const FlexColumnWidth(2)
              : const FixedColumnWidth(0),
          4: const FixedColumnWidth(168), // Kolom Icon untuk durasi
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: transparentColor), // Border per sel
                ),
                child: const Text(
                  "#",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: transparentColor), // Border per sel
                ),
                child: const Text(
                  'Title',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                ),
              ),
              if (screenWidth > 1280)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: transparentColor), // Border per sel
                  ),
                  child: const Text(
                    "Songs",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Kosong jika layar kecil
              if (screenWidth > 1480)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: transparentColor), // Border per sel
                  ),
                  child: const Text(
                    "Date added",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: mediumWeight,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Kosong jika layar kecil
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 45,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: transparentColor), // Border per sel
                    ),
                    child: const SizedBox(
                      width: 50,
                      child: Align(
                        child: Icon(
                          Icons.access_time,
                          color: primaryTextColor,
                        ),
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryTextColor),
      );
    }

    if (_isSongClicked && _isHaveSong) {
      _cachedSongList ??= SongList(
        userId: widget.userId,
        pageName: "OtherProfileContainer",
        playlistId: "",
        albumId: "",
      );
      return _cachedSongList!;
    } else if (_isPlaylistClicked && _isHavePlaylist) {
      _cachedPlaylistList ??= ProfilePlaylistList(
        userId: widget.userId,
        pageName: "OtherProfileContainer",
      );
      return _cachedPlaylistList!;
    } else if (_isAlbumClicked && _isHaveAlbum) {
      _cachedAlbumList ??= ProfileAlbumList(
        userId: widget.userId,
        pageName: "OtherProfileContainer",
      );
      return _cachedAlbumList!;
    }

    return const SizedBox.shrink();
  }

// Helper method to get current user from SQLite
  Future<User?> _getCurrentUser() async {
    try {
      final currentUserId = widget.userId;
      if (currentUserId.isEmpty) return null;

      return await _db.getUserById(currentUserId);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Cached widgets
  Widget? _cachedSongList;
  Widget? _cachedPlaylistList;
  Widget? _cachedAlbumList;

  void _resetState() {
    setState(() {
      _isLoading = true;
      _isHaveSong = false;
      _isHaveAlbum = false;
      _isHavePlaylist = false;
      _cachedSongList = null;
      _cachedPlaylistList = null;
      _cachedAlbumList = null;
    });
  }

  Widget _buildSongList() {
    _cachedSongList ??= SongList(
      userId: widget.userId,
      pageName: "OtherProfileContainer",
      playlistId: "",
      albumId: "",
    );
    return _cachedSongList!;
  }

  Widget _buildPlaylistList() {
    _cachedPlaylistList ??= ProfilePlaylistList(
      userId: widget.userId,
      pageName: "OtherProfileContainer",
    );
    return _cachedPlaylistList!;
  }

  Widget _buildAlbumList() {
    _cachedAlbumList ??= ProfileAlbumList(
      userId: widget.userId,
      pageName: "OtherProfileContainer",
    );
    return _cachedAlbumList!;
  }
}
