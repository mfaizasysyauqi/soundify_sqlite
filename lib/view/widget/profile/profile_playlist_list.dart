import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart'; // Import intl
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/user.dart';

import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/other_profile_container.dart';
import 'package:soundify/view/container/primary/playlist_container.dart';
import 'package:soundify/view/container/primary/personal_profile_container.dart';
import 'package:soundify/view/container/secondary/menu/playlist_menu.dart';
import 'package:soundify/view/style/style.dart'; // Pastikan file style sudah ada

import 'package:provider/provider.dart'; // Tambahkan provider

class ProfilePlaylistList extends StatefulWidget {
  final String userId;
  final String pageName;
  const ProfilePlaylistList({
    super.key,
    required this.userId,
    required this.pageName,
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

  // Modifikasi method _loadPlaylists
  Future<void> _loadPlaylists() async {
    try {
      // Langsung menggunakan widget.userId untuk mengambil playlist
      final userPlaylists = await _db.getPlaylistsByCreatorId(widget.userId);
      if (mounted) {
        setState(() {
          _playlists = userPlaylists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading playlists: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tambahkan method didUpdateWidget untuk handle perubahan userId
  @override
  void didUpdateWidget(ProfilePlaylistList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _loadPlaylists();
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
              userId: widget.userId,
              pageName: widget.pageName,
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
  final String userId;
  final String pageName;

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
    required this.userId,
    required this.pageName,
  });

  @override
  _ProfilePlaylistListItemState createState() =>
      _ProfilePlaylistListItemState();
}

class _ProfilePlaylistListItemState extends State<ProfilePlaylistListItem> {
  bool _isHovering = false;

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
          IntrinsicWidth(
            child: FutureBuilder<User?>(
              future: DatabaseHelper.instance.getCurrentUser(),
              builder: (context, snapshot) {
                return RichText(
                  text: TextSpan(
                    text: widget.artistName,
                    style: const TextStyle(
                      color: quaternaryTextColor,
                      fontWeight: mediumWeight,
                      fontSize: microFontSize,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Check if we're already in OtherProfileContainer
                        if (widget.pageName == "OtherProfileContainer") {
                          // If the clicked artist is the same as the current profile, do nothing
                          if (widget.userId == widget.creatorId) {
                            return;
                          }
                        }

                        // Always navigate to OtherProfileContainer when clicking artist name
                        // in song list unless it's the current user
                        if (snapshot.hasData &&
                            snapshot.data?.userId == widget.creatorId) {
                          // Jika creator adalah current user, navigasi ke PersonalProfileContainer
                          Provider.of<WidgetStateProvider1>(context,
                                  listen: false)
                              .changeWidget(
                            PersonalProfileContainer(userId: widget.creatorId),
                            'PersonalProfileContainer',
                          );
                        } else {
                          // Jika creator adalah user lain, navigasi ke OtherProfileContainer
                          Provider.of<WidgetStateProvider1>(context,
                                  listen: false)
                              .changeWidget(
                            OtherProfileContainer(userId: widget.creatorId),
                            'OtherProfileContainer',
                          );
                        }
                      },
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
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
          SizedBox(width: 45),
          const SizedBox(width: 15),
          _buildDuration(),
          _buildMoreOptions(),
        ],
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

    // Jika tidak hover dan tidak diklik, return SizedBox
    if (!_isHovering && !widget.isClicked) {
      return const SizedBox(width: 45);
    }

    // Tambahkan FutureBuilder untuk mengecek current user
    return FutureBuilder<User?>(
      future: _databaseHelper.getCurrentUser(),
      builder: (context, snapshot) {
        // Jika data belum ada atau error, return SizedBox
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(width: 45);
        }

        // Cek apakah current user adalah creator
        final isCreator = snapshot.data!.userId == widget.creatorId;

        // Jika bukan creator, return SizedBox
        if (!isCreator) {
          return const SizedBox(width: 45);
        }

        // Jika creator, tampilkan icon more_horiz
        return Row(
          children: [
            SizedBox(
              width: 45,
              child: GestureDetector(
                onTap: () async {
                  Playlist? playlist =
                      await _databaseHelper.getPlaylistById(widget.playlistId);

                  if (playlist != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        widgetStateProvider2.changeWidget(
                          PlaylistMenu(
                            playlistName: widget.playlistName,
                            playlistImageUrl: widget.playlistImageUrl,
                            creatorName: playlist.creatorName ?? '',
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
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
