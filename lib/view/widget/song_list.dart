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
// song_list.dart
// Add this extension method at the top of your file
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

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
  final songProvider = SongProvider();
  @override
  void initState() {
    super.initState();
    _loadSongs();
    _fetchLastListenedSongId();
    searchListController.addListener(_handleSearchChange);

    // Add listener for liked songs updates
    if (widget.pageName == "LikedSongContainer") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<LikeProvider>(context, listen: false).fetchLikedSongs();
      });
    }
  }

  @override
  void didUpdateWidget(SongList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload songs when playlistId or pageName changes
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
    User? currentUser = await dbHelper.getCurrentUser();
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
          fetchedSongs = await dbHelper.getLikedSongs(currentUser!.userId);
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
    return Consumer3<SongProvider, SongListItemProvider, LikeProvider>(
      builder: (context, songProvider, listProvider, likeProvider, child) {
        List<Song> displayedSongs = widget.pageName == "LikedSongContainer"
            ? likeProvider.likedSongs
            : listProvider.filteredSongs;

        // // Remove the sort by timestamp for LikedSongContainer
        // if (widget.pageName != "LikedSongContainer") {
        //   displayedSongs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        // }

        if (displayedSongs.isEmpty) {
          return const Center(
            child: Text(
              'No songs available',
              style: TextStyle(color: primaryTextColor),
            ),
          );
        }

        return ListView.builder(
          itemCount: displayedSongs.length,
          itemBuilder: (context, index) {
            if (index >= displayedSongs.length) {
              return null;
            }
            final song = displayedSongs[index];
            return SongListItem(
              index: index,
              songId: song.songId,
              pageName: widget.pageName,
              playlistId: widget.playlistId,
            );
          },
        );
      },
    );
  }
}

class SongListItem extends StatefulWidget {
  final int index;
  final String songId;
  final String pageName;
  final String playlistId;
  const SongListItem({
    super.key,
    required this.index,
    required this.songId,
    required this.pageName,
    required this.playlistId,
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

  // Update the existing _handleToggleLike method
  Future<void> _handleToggleLike(
    String songId,
    LikeProvider likeProvider,
    BuildContext context,
  ) async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();

    if (currentUser == null) {
      print('No user logged in');
      return;
    }

    try {
      bool isNowLiked = await DatabaseHelper.instance.toggleSongLike(
        songId,
        currentUser.userId,
      );

      // Update LikeProvider state
      likeProvider.updateLikeState(songId, isNowLiked);

      // Refresh liked songs list if necessary
      if (widget.pageName == "LikedSongContainer") {
        await likeProvider.fetchLikedSongs();
      }
    } catch (e) {
      print('Error updating likes: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final listProvider =
          Provider.of<SongListItemProvider>(context, listen: false);
      songProvider = Provider.of<SongProvider>(context, listen: false);

      // Add null check and bounds check
      if (widget.index < listProvider.filteredSongs.length) {
        final song = listProvider.filteredSongs[widget.index];
        Provider.of<LikeProvider>(context, listen: false)
            .checkIfLiked(song.songId);

        if (song.songId == listProvider.lastListenedSongId) {
          _playSelectedSong();
        }
      }

      final likeProvider = Provider.of<LikeProvider>(context, listen: false);
      likeProvider.fetchLikedSongs();
    });
  }

  void _playSelectedSong() {
    if (!mounted) return;

    final listProvider =
        Provider.of<SongListItemProvider>(context, listen: false);

    // Check if the index is valid
    if (widget.index >= listProvider.filteredSongs.length) return;

    final song = listProvider.filteredSongs[widget.index];

    // Initialize songProvider if it's null
    songProvider ??= Provider.of<SongProvider>(context, listen: false);

    // Null check for songProvider
    if (songProvider == null) return;

    try {
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
          song.bio ?? '',
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error playing song: $e');
      // Optionally show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer2<SongListItemProvider, LikeProvider>(
      builder: (context, listProvider, likeProvider, child) {
        Song? song;
        if (widget.pageName == "LikedSongContainer") {
          song = likeProvider.likedSongs
              .firstWhereOrNull((s) => s.songId == widget.songId);
        } else if (widget.index < listProvider.filteredSongs.length) {
          song = listProvider.filteredSongs[widget.index];
        }
        if (song == null) {
          return const SizedBox.shrink(); // Return empty widget if song is null
        }
        final formattedDuration = _formatDuration(song.songDuration);
        final formattedDate = DateFormat('MMM d, yyyy').format(song.timestamp);
        final isClicked = listProvider.clickedIndex == widget.index;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            onTap: () {
              listProvider.setClickedIndex(widget.index);
              listProvider.setLastListenedSongId(song!.songId);
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
                likeProvider,
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
    LikeProvider likeProvider,
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
              likeProvider,
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
                            color: senaryColor,
                            child: const Icon(Icons.broken_image,
                                color: primaryTextColor),
                          ),
                        )
                      : Container(
                          color: senaryColor,
                          child: const Icon(Icons.broken_image,
                              color: primaryTextColor),
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

  Widget _buildControls(String formattedDuration, song, bool isClicked,
      LikeProvider likeProvider) {
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
                      await _handleToggleLike(song.songId, likeProvider, context);
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
                      originalIndex: widget.index,
                      likedIds: song.likeIds,
                      pageName: widget.pageName,
                      playlistId: widget.playlistId,
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