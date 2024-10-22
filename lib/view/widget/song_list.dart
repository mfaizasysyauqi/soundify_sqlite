import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:soundify/components/hover_icons_widget.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class SongList extends StatefulWidget {
  final String userId;
  final String pageName;
  final String playlistId;
  final String albumId;

  SongList({
    Key? key,
    required this.userId,
    required this.pageName,
    required this.playlistId,
    required this.albumId,
  }) : super(key: key);

  @override
  State<SongList> createState() => _SongListState();
}

TextEditingController searchListController = TextEditingController();

class _SongListState extends State<SongList> {
  String? lastListenedSongId;
  int _clickedIndex = -1;

  List<Song> songs = [];
  List<Song> filteredSongs = [];
  bool isSearch = false;
  DatabaseHelper dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _fetchLastListenedSongId();
    searchListController.addListener(() {
      if (mounted) {
        setState(() {
          _filterSongs(); // Panggil metode filter setiap ada perubahan input
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure this is inside a widget and the context is BuildContext
    final currentWidgetName =
        Provider.of<WidgetStateProvider1>(context, listen: true).widgetName;
    bool wasSearch = isSearch;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isSearch = currentWidgetName != "HomeContainer";
        if (isSearch && !wasSearch) {
          searchListController.clear();
        }
      });
    });
  }

  Future<void> _fetchLastListenedSongId() async {
    User? currentUser = await dbHelper.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        lastListenedSongId = currentUser.lastListenedSongId;
      });
    }
  }

  Future<void> _loadSongs() async {
    List<Song> fetchedSongs = [];
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
      setState(() {
        songs = fetchedSongs;
        filteredSongs = songs;
        if (lastListenedSongId != null) {
          _clickedIndex =
              songs.indexWhere((song) => song.songId == lastListenedSongId);
        }
      });
    }
  }

  List<Song> _filterSongs() {
    String query = searchListController.text.toLowerCase();
    List<Song> songDocs = songs;

    if (query.isEmpty) {
      return songDocs; // Jika inputan kosong, tampilkan semua lagu
    }

    return songDocs.where((song) {
      String songTitle = song.songTitle.toLowerCase();
      String artistName = song.artistName?.toLowerCase() ?? '';
      String albumName = song.albumName?.toLowerCase() ?? '';

      // Periksa apakah inputan mengandung judul lagu, nama artis, atau nama album
      return songTitle.contains(query) ||
          artistName.contains(query) ||
          albumName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SongProvider>(context);

    List<Song> displayedSongs = _filterSongs();
    displayedSongs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      itemCount: displayedSongs.length,
      itemBuilder: (context, index) {
        Song song = displayedSongs[index];
        String formattedDate = DateFormat('MMM d, yyyy').format(song.timestamp);

        return SongListItem(
          index: index,
          songId: song.songId,
          senderId: song.senderId,
          songTitle: song.songTitle,
          artistId: song.artistId,
          artistName: song.artistName,
          albumId: song.albumId,
          albumName: song.albumName,
          artistFileIndex: song.artistSongIndex,
          formattedDate: formattedDate,
          songDuration: song.songDuration,
          songUrl: song.songUrl,
          profileImageUrl: song.profileImageUrl,
          songImageUrl: song.songImageUrl,
          bioImageUrl: song.bioImageUrl,
          likedIds: song.likeIds,
          playlistIds: song.playlistIds,
          timestamp: song.timestamp,
          isClicked: _clickedIndex == index,
          onItemTapped: (int tappedIndex) {
            setState(() {
              _clickedIndex = tappedIndex;
              lastListenedSongId = displayedSongs[tappedIndex].songId;
            });
          },
          isInitialSong: lastListenedSongId == song.songId,
        );
      },
    );
  }
}

// Widget terpisah untuk setiap item
class SongListItem extends StatefulWidget {
  final int index;
  final String songId;
  final String senderId;
  final String songTitle;
  final String artistId;
  final String? artistName;
  final String? albumId;
  final String? albumName;
  final int artistFileIndex;
  final String formattedDate;
  final Duration songDuration;
  final String songUrl;
  final String? profileImageUrl;
  final String songImageUrl;
  final String? bioImageUrl;
  final List<String>? likedIds;
  final List<String>? playlistIds;
  final DateTime timestamp;
  final bool isClicked; // This is received from the parent widget
  final Function(int) onItemTapped; // Callback to notify parent
  final bool isInitialSong;

  const SongListItem({
    super.key,
    required this.index,
    required this.songId,
    required this.senderId,
    required this.songTitle,
    required this.artistId,
    required this.artistName,
    required this.albumId,
    required this.albumName,
    required this.artistFileIndex,
    required this.formattedDate,
    required this.songDuration,
    required this.songUrl,
    required this.profileImageUrl,
    required this.songImageUrl,
    required this.bioImageUrl,
    required this.likedIds,
    required this.playlistIds,
    required this.timestamp,
    required this.isClicked, // Add this to the constructor
    required this.onItemTapped, // Add this to the constructor
    required this.isInitialSong,
  });

  @override
  _SongListItemState createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  bool _isLiked = false;
  SongProvider? songProvider; // make nullable
  bool _isHovering = false;

// Function to change hovering state
  void _handleHoverChange(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    songProvider = Provider.of<SongProvider>(context, listen: false);
    if (widget.isInitialSong) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playSelectedSong();
      });
    }
  }

  Future<void> _checkIfLiked() async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    if (currentUser != null && widget.likedIds != null) {
      if (mounted) {
        setState(() {
          _isLiked = widget.likedIds!.contains(currentUser.userId);
        });
      }
    }
  }

  void _playSelectedSong() async {
    if (songProvider?.songId == widget.songId && songProvider!.isPlaying) {
      songProvider!.pauseOrResume();
    } else {
      songProvider!.stop();
      songProvider!.setSong(
        widget.songId,
        widget.senderId,
        widget.artistId,
        widget.songTitle,
        widget.profileImageUrl,
        widget.songImageUrl,
        widget.bioImageUrl,
        widget.artistName,
        widget.songUrl,
        widget.songDuration,
        widget.index,
      );
      if (!mounted) return;
      setState(() {}); // Rebuild the UI after song and bio are updated
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formattedDuration = _formatDuration(widget.songDuration);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          widget.onItemTapped(widget.index);
          _playSelectedSong();
          songProvider?.setShouldPlay(true);
        },
        child: Container(
          color: widget.isClicked
              ? primaryTextColor.withOpacity(0.1)
              : (_isHovering
                  ? primaryTextColor.withOpacity(0.1)
                  : Colors.transparent),
          child: Table(
            border: TableBorder.all(
              color: transparentColor, // Warna border sementara untuk debugging
              width: 1,
            ),
            columnWidths: {
              0: const FixedColumnWidth(50), // Lebar tetap untuk nomor indeks
              1: FlexColumnWidth(2), // Lebih besar untuk info lagu
              2: screenWidth > 1280
                  ? const FlexColumnWidth(2)
                  : const FixedColumnWidth(0),
              3: screenWidth > 1480
                  ? const FlexColumnWidth(2)
                  : const FixedColumnWidth(0),
              4: const FixedColumnWidth(168), // Kontrol tombol suka dan durasi
            },
            children: [
              TableRow(
                children: [
                  // Index number
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 23),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: transparentColor), // Border per sel
                    ),
                    child: _buildIndexNumber(), // Widget nomor indeks
                  ),
                  // Song info
                  Container(
                    padding: const EdgeInsets.all(
                      8.0,
                    ),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: transparentColor), // Border per sel
                    ),
                    child: _buildSongInfo(screenWidth), // Widget informasi lagu
                  ),
                  // Album name (only on wider screens)
                  if (screenWidth > 1280)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 23),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: transparentColor), // Border per sel
                      ),
                      child: _buildAlbumName(screenWidth), // Widget nama album
                    )
                  else
                    const SizedBox.shrink(), // Kosong jika layar kecil
                  // Date (only on even wider screens)
                  if (screenWidth > 1480)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 23),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: transparentColor), // Border per sel
                      ),
                      child: _buildDate(), // Widget tanggal
                    )
                  else
                    const SizedBox.shrink(), // Kosong jika layar kecil
                  // Like button and duration
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: transparentColor), // Border per sel
                    ),
                    child: _buildControls(
                        formattedDuration), // Widget tombol suka dan durasi
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndexNumber() {
    return SizedBox(
      width: 35,
      child: Text(
        widget.index + 1 > 1000 ? "𝅗𝅥" : '${widget.index + 1}',
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: primaryTextColor,
          fontWeight: mediumWeight,
        ),
      ),
    );
  }

  Widget _buildSongInfo(double screenWidth) {
    return Row(
      children: [
        // Song image
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 50,
            width: 50,
            child: widget.songImageUrl.isNotEmpty
                ? (Uri.tryParse(widget.songImageUrl)?.hasAbsolutePath ?? false
                    ? Image.file(
                        File(widget.songImageUrl), // Load local file
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white),
                        ),
                      )
                    : Container(
                        color: Colors.grey,
                        child:
                            const Icon(Icons.broken_image, color: Colors.white),
                      ))
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 10),
        // Song title and artist name
        SizedBox(
          width: screenWidth * 0.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.songTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryTextColor,
                  fontWeight: mediumWeight,
                  fontSize: smallFontSize,
                ),
              ),
              Text(
                widget.artistName ?? '',
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
    );
  }

  Widget _buildAlbumName(double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.125,
      child: Text(
        widget.albumName ?? '',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: primaryTextColor,
          fontWeight: mediumWeight,
        ),
      ),
    );
  }

  Widget _buildDate() {
    return SizedBox(
      width: 82,
      child: Text(
        widget.formattedDate,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: primaryTextColor,
          fontWeight: mediumWeight,
        ),
      ),
    );
  }

  Widget _buildControls(String formattedDuration) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: SizedBox(
        height: 66,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Like button (visible on hover or if clicked)
            if (widget.isClicked || _isHovering)
              SizedBox(
                width: 45,
                child: GestureDetector(
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                    color: _isLiked ? secondaryColor : primaryTextColor,
                    size: smallFontSize,
                  ),
                  onTap: () {
                    // Handle like button press
                  },
                ),
              )
            else
              const SizedBox(width: 45),

            const SizedBox(width: 15),

            // Song duration
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

            // HoverIconsWidget
            HoverIconsWidget(
              isClicked: widget.isClicked,
              onItemTapped: (index) {
                print('Item tapped at index: $index');
              },
              index: widget.index,
              isHoveringParent: _isHovering, // Pass hover state
              onHoverChange:
                  _handleHoverChange, // Pass callback to update hover state
            ),
          ],
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
