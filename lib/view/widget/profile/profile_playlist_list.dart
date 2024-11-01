import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart'; // Import intl
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/user.dart';

import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/playlist_container.dart';
import 'package:soundify/view/container/primary/personal_profile_container.dart';
import 'package:soundify/view/container/secondary/menu/playlist_menu.dart';
import 'package:soundify/view/style/style.dart'; // Pastikan file style sudah ada

import 'package:provider/provider.dart'; // Tambahkan provider

class ProfilePlaylistList extends StatefulWidget {
  const ProfilePlaylistList({
    super.key,
  });

  @override
  State<ProfilePlaylistList> createState() => _ProfilePlaylistListState();
}

OverlayEntry? _overlayEntryPlaylist;
bool showModalPlaylist = false;
GlobalKey _iconKey1Playlist = GlobalKey();
GlobalKey _iconKey2Playlist = GlobalKey();

class _ProfilePlaylistListState extends State<ProfilePlaylistList> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool showModalPlaylist = false;
  int _clickedIndex = -1;
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser != null) {
        // Get playlists for current user and sort by timestamp
        final userPlaylists =
            await _db.getPlaylistsByCreatorId(currentUser.userId);
        setState(() {
          _playlists = userPlaylists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading playlists: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryTextColor),
      );
    }

    if (_playlists.isEmpty) {
      return const Center(
        child: Text(
          '',
          style: TextStyle(color: primaryTextColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return FutureBuilder<User?>(
          future: _db.getUserById(playlist.creatorId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final creator = snapshot.data!;

            return ProfilePlaylistListItem(
              index: index,
              creatorId: playlist.creatorId,
              artistName: creator.fullName,
              playlistId: playlist.playlistId,
              playlistName: playlist.playlistName,
              artistFileIndex: playlist.playlistUserIndex,
              formattedDate: DateFormat('MMM d, yyyy').format(
                playlist.timestamp,
              ),
              playlistImageUrl: playlist.playlistImageUrl ?? '',
              likedIds: playlist.playlistLikeIds ?? [],
              playlistIds: playlist.songListIds ?? [],
              songs: playlist.songListIds?.length ?? 0,
              totalDuration: playlist.totalDuration,
              timestamp: playlist.timestamp,
              isClicked: _clickedIndex == index,
              onItemTapped: (int index) {
                setState(() => _clickedIndex = index);
              },
              songListIds: playlist.songListIds ?? [],
            );
          },
        );
      },
    );
  }
}

// Widget terpisah untuk setiap item
class ProfilePlaylistListItem extends StatefulWidget {
  final int index;
  final String creatorId;
  final String artistName; // Added field
  final String playlistId;
  final String playlistName;
  final int artistFileIndex;
  final String formattedDate;
  final String playlistImageUrl;
  final List likedIds;
  final List playlistIds;
  final int songs;
  final Duration totalDuration;
  final DateTime timestamp;
  final bool isClicked;
  final Function(int) onItemTapped;
  final List<String>? songListIds;

  const ProfilePlaylistListItem({
    super.key,
    required this.index,
    required this.creatorId,
    required this.artistName, // Added this to the constructor
    required this.playlistId,
    required this.playlistName,
    required this.artistFileIndex,
    required this.formattedDate,
    required this.playlistImageUrl,
    required this.likedIds,
    required this.playlistIds,
    required this.songs,
    required this.totalDuration,
    required this.timestamp,
    required this.isClicked,
    required this.onItemTapped,
    required this.songListIds,
  });

  @override
  _ProfilePlaylistListItemState createState() =>
      _ProfilePlaylistListItemState();
}

class _ProfilePlaylistListItemState extends State<ProfilePlaylistListItem> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isHovering = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) return;

      final playlist = await _db.getPlaylistById(widget.playlistId);
      if (playlist == null) return;

      setState(() {
        _isLiked =
            playlist.playlistLikeIds?.contains(currentUser.userId) ?? false;
      });
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) return;

      final success =
          await _db.togglePlaylistLike(widget.playlistId, currentUser.userId);
      if (mounted) {
        setState(() => _isLiked = success);
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widgetStateProvider1 =
        Provider.of<WidgetStateProvider1>(context, listen: false);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          widget.onItemTapped(widget.index);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widgetStateProvider1.changeWidget(
              PlaylistContainer(playlistId: widget.playlistId),
              'Playlist Container',
            );
          });
        },
        child: _buildListItem(context, screenWidth),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, double screenWidth) {
    return Container(
      color: widget.isClicked
          ? primaryTextColor.withOpacity(0.1)
          : (_isHovering
              ? primaryTextColor.withOpacity(0.1)
              : Colors.transparent),
      child: Row(
        children: [
          _buildIndexNumber(),
          Expanded(
            flex: 2,
            child: _buildPlaylistInfo(screenWidth),
          ),
          if (screenWidth > 1280)
            Expanded(
              flex: 2,
              child: _buildSongsCount(screenWidth),
            ),
          if (screenWidth > 1480)
            Expanded(
              flex: 2,
              child: _buildDateAdded(),
            ),
          SizedBox(
            width: 168,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexNumber() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: SizedBox(
        width: 35,
        child: Text(
          widget.index + 1 > 1000 ? "𝅗𝅥" : '${widget.index + 1}',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: primaryTextColor,
            fontWeight: mediumWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: Row(
        children: [
          _buildPlaylistImage(),
          const SizedBox(width: 10),
          _buildPlaylistDetails(screenWidth),
        ],
      ),
    );
  }

  Widget _buildPlaylistImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 50,
        width: 50,
        child: widget.playlistImageUrl.isNotEmpty
            ? (Uri.tryParse(widget.playlistImageUrl)?.hasAbsolutePath ?? false
                ? Image.file(
                    File(widget.playlistImageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey,
                      child:
                          const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  )
                : Container(
                    color: primaryTextColor,
                    child: const Icon(Icons.library_music,
                        color: secondaryTextColor),
                  ))
            : Container(
                color: primaryTextColor,
                child:
                    const Icon(Icons.library_music, color: secondaryTextColor),
              ),
      ),
    );
  }

  Widget _buildPlaylistDetails(double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.playlistName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryTextColor,
              fontWeight: mediumWeight,
              fontSize: smallFontSize,
            ),
          ),
          GestureDetector(
            onTap: () {
              Provider.of<WidgetStateProvider1>(context, listen: false)
                  .changeWidget(
                PersonalProfileContainer(userId: widget.creatorId),
                'Profile Container',
              );
            },
            child: Text(
              widget.artistName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: quaternaryTextColor,
                fontWeight: mediumWeight,
                fontSize: microFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsCount(double screenWidth) {
    int _songLength = widget.songListIds!.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: SizedBox(
        width: screenWidth * 0.125,
        child: Text(
          _songLength.toString(), // Kurangi 1 dari length
          style: const TextStyle(
            color: primaryTextColor,
            fontWeight: mediumWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildDateAdded() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: SizedBox(
        width: 82,
        child: Text(
          widget.formattedDate,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: primaryTextColor,
            fontWeight: mediumWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLikeButton(),
          const SizedBox(width: 15),
          _buildDuration(),
          _buildMoreOptions(),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    if (!widget.isClicked && !_isHovering) {
      return const SizedBox(width: 45);
    }
    return SizedBox(
      width: 45,
      child: IconButton(
        icon: Icon(
          _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
          color: _isLiked ? secondaryColor : primaryTextColor,
          size: smallFontSize,
        ),
        onPressed: _toggleLike,
      ),
    );
  }

  Widget _buildDuration() {
    return SizedBox(
      width: 45,
      child: Text(
        _formatDuration(widget.totalDuration),
        style: const TextStyle(
          color: primaryTextColor,
          fontWeight: mediumWeight,
        ),
      ),
    );
  }

  Widget _buildMoreOptions() {
    final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    final widgetStateProvider2 =
        Provider.of<WidgetStateProvider2>(context, listen: false);
    if (!_isHovering && !widget.isClicked) {
      return const SizedBox(width: 45);
    }
    return Row(
      children: [
        SizedBox(
          width: 45,
          child: GestureDetector(
            onTap: () async {
              // Make onPressed async
              // First fetch the playlist data
              Playlist? playlist =
                  await _databaseHelper.getPlaylistById(widget.playlistId);

              if (playlist != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    widgetStateProvider2.changeWidget(
                      PlaylistMenu(
                        playlistName: widget.playlistName,
                        playlistImageUrl: widget.playlistImageUrl,
                        creatorName: playlist.creatorName ??
                            '', // Now we can use the creator name
                      ),
                      'PlaylistMenu',
                    );
                  }
                });
              }
            },
            child: const Icon(
              Icons.more_horiz,
              color: primaryTextColor,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
