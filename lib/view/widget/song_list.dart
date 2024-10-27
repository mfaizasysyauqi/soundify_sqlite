import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:soundify/components/hover_icons_widget.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/like_provider.dart';
import 'package:soundify/provider/song_list_item_provider.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/album_container.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/container/secondary/menu/song_menu.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class SongList extends StatefulWidget {
  final String userId;
  final String pageName;
  final String playlistId;
  final String albumId;

  const SongList({
    super.key,
    required this.userId,
    required this.pageName,
    required this.playlistId,
    required this.albumId,
  });

  @override
  State<SongList> createState() => _SongListState();
}

TextEditingController searchListController = TextEditingController();

class _SongListState extends State<SongList> {
  DatabaseHelper dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _fetchLastListenedSongId();
    searchListController.addListener(_handleSearchChange);
  }

  @override
  void didUpdateWidget(SongList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload songs when playlistId changes
    if (oldWidget.playlistId != widget.playlistId) {
      _loadSongs();
    }
  }

  @override
  void dispose() {
    if (mounted) {
      searchListController.removeListener(_handleSearchChange);
    }
    super.dispose();
  }

  void _handleSearchChange() {
    if (mounted) {
      final provider =
          Provider.of<SongListItemProvider>(context, listen: false);
      provider.filterSongs(searchListController.text);
    }
  }

  Future<void> _fetchLastListenedSongId() async {
    User? currentUser = await dbHelper.getCurrentUser();
    if (currentUser != null && mounted) {
      Provider.of<SongListItemProvider>(context, listen: false)
          .setLastListenedSongId(currentUser.lastListenedSongId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentWidgetName =
        Provider.of<WidgetStateProvider1>(context, listen: true).widgetName;
    final provider = Provider.of<SongListItemProvider>(context, listen: false);
    bool wasSearch = provider.isSearch;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.setIsSearch(currentWidgetName != "HomeContainer");
      if (provider.isSearch && !wasSearch) {
        searchListController.clear();
      }
    });
  }

  Future<void> _loadSongs() async {
    List<Song> fetchedSongs = [];
    try {
      switch (widget.pageName) {
        case "HomeContainer":
          fetchedSongs = await dbHelper.getSongs();
          break;
        case "PersonalProfileContainer":
        case "OtherProfileContainer":
          fetchedSongs = await dbHelper.getSongsByArtist(widget.userId);
          break;
        case "AlbumContainer":
          fetchedSongs = await dbHelper.getSongsByAlbum(widget.albumId);
          break;
        case "PlaylistContainer":
          fetchedSongs = await dbHelper.getSongsByPlaylist(widget.playlistId);
          break;
        case "LikedSongContainer":
          User? currentUser = await dbHelper.getCurrentUser();
          if (currentUser != null) {
            fetchedSongs = await dbHelper.getLikedSongs(currentUser.userId);
          }
          break;
        default:
          fetchedSongs = await dbHelper.getSongs();
      }

      if (mounted) {
        final provider =
            Provider.of<SongListItemProvider>(context, listen: false);
        // Clear existing songs before setting new ones
        provider.clearSongs();
        provider.setSongs(fetchedSongs);

        if (provider.lastListenedSongId != null) {
          provider.setClickedIndex(fetchedSongs.indexWhere(
              (song) => song.songId == provider.lastListenedSongId));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SongProvider, SongListItemProvider>(
      builder: (context, songProvider, listProvider, child) {
        List<Song> displayedSongs = listProvider.filteredSongs;
        displayedSongs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          itemCount: displayedSongs.length,
          itemBuilder: (context, index) {
            int reversedIndex = displayedSongs.length - 1 - index;
            int ascendingIndex = index;

            return SongListItem(
              index: reversedIndex,
              originalIndex: ascendingIndex,
            );
          },
        );
      },
    );
  }
}

class SongListItem extends StatefulWidget {
  final int index;
  final int originalIndex;

  const SongListItem({
    super.key,
    required this.index,
    required this.originalIndex,
  });

  @override
  _SongListItemState createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  SongProvider? songProvider;
  bool _isHovering = false;

  void _handleHoverChange(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
  }

  @override
  void initState() {
    super.initState();
    final listProvider =
        Provider.of<SongListItemProvider>(context, listen: false);
    final song = listProvider.filteredSongs[widget.originalIndex];
    Provider.of<LikeProvider>(context, listen: false).checkIfLiked(song.songId);

    songProvider = Provider.of<SongProvider>(context, listen: false);

    if (song.songId == listProvider.lastListenedSongId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playSelectedSong();
      });
    }
  }

  Future<void> _checkIfLiked() async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    final listProvider =
        Provider.of<SongListItemProvider>(context, listen: false);
    final song = listProvider.filteredSongs[widget.originalIndex];

    if (currentUser != null && song.likeIds != null) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _playSelectedSong() async {
    final listProvider =
        Provider.of<SongListItemProvider>(context, listen: false);
    final song = listProvider.filteredSongs[widget.originalIndex];

    if (songProvider?.songId == song.songId && songProvider!.isPlaying) {
      songProvider!.pauseOrResume();
    } else {
      songProvider!.stop();
      songProvider!.setSong(
        song.songId,
        song.senderId,
        song.artistId,
        song.songTitle,
        song.profileImageUrl,
        song.songImageUrl,
        song.bioImageUrl,
        song.artistName,
        song.songUrl,
        song.songDuration,
        widget.index,
      );
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer<SongListItemProvider>(
      builder: (context, listProvider, child) {
        final song = listProvider.filteredSongs[widget.originalIndex];
        final formattedDuration = _formatDuration(song.songDuration);
        final formattedDate = DateFormat('MMM d, yyyy').format(song.timestamp);
        final isClicked = listProvider.clickedIndex == widget.index;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            onTap: () {
              listProvider.setClickedIndex(widget.index);
              listProvider.setLastListenedSongId(song.songId);
              _playSelectedSong();
              songProvider?.setShouldPlay(true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<WidgetStateProvider2>(context, listen: false)
                    .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
              });
            },
            child: Container(
              color: isClicked
                  ? primaryTextColor.withOpacity(0.1)
                  : (_isHovering
                      ? primaryTextColor.withOpacity(0.1)
                      : Colors.transparent),
              child: _buildListItem(
                context,
                screenWidth,
                song,
                isClicked,
                formattedDuration,
                formattedDate,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    double screenWidth,
    Song currentSong,
    bool isClicked,
    String formattedDuration,
    String formattedDate,
  ) {
    return Container(
      color: isClicked
          ? primaryTextColor.withOpacity(0.1)
          : (_isHovering
              ? primaryTextColor.withOpacity(0.1)
              : Colors.transparent),
      child: Row(
        children: [
          _buildIndexNumber(),
          Expanded(
            flex: 2,
            child: _buildSongInfo(screenWidth, currentSong),
          ),
          if (screenWidth > 1280)
            Expanded(
              flex: 2,
              child: _buildAlbumName(screenWidth, currentSong),
            ),
          if (screenWidth > 1480)
            Expanded(
              flex: 2,
              child: _buildDate(formattedDate),
            ),
          SizedBox(
            width: 168,
            child: _buildControls(
              formattedDuration,
              currentSong,
              isClicked,
            ),
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
          widget.originalIndex + 1 > 1000
              ? "𝅗𝅥"
              : '${widget.originalIndex + 1}',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: primaryTextColor,
            fontWeight: mediumWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(double screenWidth, song) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 50,
              width: 50,
              child: song.songImageUrl.isNotEmpty
                  ? (Uri.tryParse(song.songImageUrl)?.hasAbsolutePath ?? false
                      ? Image.file(
                          File(song.songImageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image,
                                color: Colors.white),
                          ),
                        )
                      : Container(
                          color: Colors.grey,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white),
                        ))
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: screenWidth * 0.1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.songTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                    fontSize: smallFontSize,
                  ),
                ),
                Text(
                  song.artistName ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: quaternaryTextColor,
                    fontWeight: mediumWeight,
                    fontSize: microFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumName(double screenWidth, song) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: SizedBox(
        width: screenWidth * 0.125,
        child: IntrinsicWidth(
          child: RichText(
            text: TextSpan(
              text: song.albumName ?? '',
              style: const TextStyle(
                color: primaryTextColor,
                fontWeight: mediumWeight,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Provider.of<WidgetStateProvider1>(context, listen: false)
                      .changeWidget(
                    AlbumContainer(albumId: song.albumId),
                    'Album Container',
                  );
                },
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDate(String formattedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: SizedBox(
        width: 82,
        child: Text(
          formattedDate,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: primaryTextColor,
            fontWeight: mediumWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(String formattedDuration, song, bool isClicked) {
    final likeProvider = Provider.of<LikeProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isClicked || _isHovering)
                SizedBox(
                  width: 45,
                  child: GestureDetector(
                    child: Icon(
                      likeProvider.isLiked(song.songId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: likeProvider.isLiked(song.songId)
                          ? secondaryColor
                          : primaryTextColor,
                      size: smallFontSize,
                    ),
                    onTap: () async {
                      await likeProvider.toggleLike(song.songId);
                    },
                  ),
                )
              else
                const SizedBox(width: 45),
              const SizedBox(width: 15),
              SizedBox(
                width: 45,
                child: Text(
                  formattedDuration,
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                  ),
                ),
              ),
              HoverIconsWidget(
                isClicked: isClicked,
                onItemTapped: (index) {
                  Provider.of<WidgetStateProvider2>(context, listen: false)
                      .changeWidget(
                    SongMenu(
                      onChangeWidget: (Widget) {},
                      songId: song.songId,
                      songUrl: song.songUrl,
                      songImageUrl: song.songImageUrl,
                      artistId: song.artistId,
                      artistName: song.artistName,
                      albumId: song.albumId,
                      artistSongIndex: song.artistSongIndex,
                      songTitle: song.songTitle,
                      songDuration: song.songDuration,
                      originalIndex: widget.originalIndex,
                      likedIds: song.likeIds,
                    ),
                    'SongMenu',
                  );
                },
                index: widget.index,
                isHoveringParent: _isHovering,
                onHoverChange: _handleHoverChange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}