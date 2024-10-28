import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/components/playlist_item.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/playlist_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/edit_song_container.dart';
import 'package:soundify/view/container/secondary/create/show_image.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/main_page.dart';
import 'package:soundify/view/style/style.dart';
import 'package:sqflite/sqflite.dart' show Transaction;
import 'dart:math' as math;

class SongMenu extends StatefulWidget {
  final Function(Widget) onChangeWidget;
  final String songId;
  final String songUrl;
  final String songImageUrl;
  final String artistId;
  final String albumId;
  final String? artistName;
  final int artistSongIndex;
  final String songTitle;
  final Duration songDuration;
  final int? originalIndex; // Made nullable with ?
  final List<String>? likedIds;

  const SongMenu({
    super.key,
    required this.onChangeWidget,
    required this.songId,
    required this.songUrl,
    required this.songImageUrl,
    required this.artistId,
    required this.artistName,
    required this.albumId,
    required this.artistSongIndex,
    required this.songTitle,
    required this.songDuration,
    this.originalIndex, // Made optional by removing required
    this.likedIds,
  });

  @override
  State<SongMenu> createState() => _SongMenuState();
}

class _SongMenuState extends State<SongMenu> {
  bool _isLiked = false; // Added missing _isLiked variable
  late Song _song; // Add this field to store the Song object
  bool _isAddToPlaylistMenuVisible = false;
  bool _isCreatePlaylistVisible = false;
  bool _isHoveredSearchPlaylist = false;

  final TextEditingController _searchPlaylistController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    // Initialize the Song object from widget properties
    _song = Song(
      songId: widget.songId,
      songUrl: widget.songUrl,
      songImageUrl: widget.songImageUrl,
      artistId: widget.artistId,
      albumId: widget.albumId,
      songTitle: widget.songTitle,
      songDuration: widget.songDuration,
      artistSongIndex: widget.artistSongIndex,
      // Initialize other required fields with default values or null
      senderId: '', // Add appropriate default value
      timestamp: DateTime.now(),
      likeIds: widget.likedIds ?? [],
      playlistIds: [],
      albumIds: [],
      playedIds: [],
    );

    // Add listener to controller
    _searchPlaylistController.addListener(() {
      if (mounted) {
        setState(() {
          // Trigger rebuild when search text changes
        });
      }
    });
  }

  @override
  void dispose() {
    // Remove listener before disposing the controller
    _searchPlaylistController.removeListener(() {});
    // _searchPlaylistController.dispose();
    super.dispose();
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

  void _onLikedChanged(bool _isLiked) async {
    // Get current user from DatabaseHelper
    User? currentUser = await DatabaseHelper.instance.getCurrentUser();

    if (currentUser == null) {
      print('No user logged in');
      return;
    }

    try {
      bool newLikeStatus = await DatabaseHelper.instance.toggleSongLike(
        widget.songId,
        currentUser.userId,
      );

      // Update UI if needed
      setState(() {
        // Update local state to reflect new like status
        _isLiked = newLikeStatus;
      });
    } catch (e) {
      print('Error updating likes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8.0, right: 8.0),
          child: Row(
            children: [
              // Only show index if it exists
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  widget.originalIndex != null
                      ? (widget.originalIndex! + 1 >= 10
                          ? '𝅗𝅥' // Tampilan khusus ketika nilai >= 1000
                          : '${widget.originalIndex! + 1}') // Tampilan normal jika kurang dari 1000
                      : '',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                    fontSize: smallFontSize,
                  ),
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              // Song image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: widget.songImageUrl.isNotEmpty
                      ? (Uri.tryParse(widget.songImageUrl)?.hasAbsolutePath ??
                              false
                          ? Image.file(
                              File(widget.songImageUrl),
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
              // Song title and artist name
              Expanded(
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
              IconButton(
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<WidgetStateProvider2>(context, listen: false)
                        .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Divider(
            thickness: 1,
            color: primaryTextColor,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    hoverColor: primaryTextColor.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _isAddToPlaylistMenuVisible =
                            !_isAddToPlaylistMenuVisible; // Toggle antara true dan false
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: _isAddToPlaylistMenuVisible
                                  ? 0
                                  : 3 * math.pi / 2,
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: primaryTextColor,
                                size: 24.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Add to Playlist",
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _isAddToPlaylistMenuVisible
                    ? _buildAddToPlaylistContainer(
                        MediaQuery.of(context).size.width, _song)
                    : SizedBox.shrink(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    hoverColor: primaryTextColor.withOpacity(0.1),
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _isLiked = !_isLiked; // Toggle the value of _isLiked
                        _onLikedChanged(_isLiked);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 11, right: 8.0, top: 10.0, bottom: 10.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border_outlined,
                              color:
                                  _isLiked ? secondaryColor : primaryTextColor,
                              size: 18,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _isLiked
                                    ? "Remove from your Liked Songs"
                                    : "Save to your Liked Songs",
                                style: const TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Divider(
                    thickness: 1,
                    color: primaryTextColor,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    hoverColor: primaryTextColor.withOpacity(0.1),
                    onTap: () {
                      final widgetStateProvider1 =
                          Provider.of<WidgetStateProvider1>(context,
                              listen: false);
                      final widgetStateProvider2 =
                          Provider.of<WidgetStateProvider2>(context,
                              listen: false);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          widgetStateProvider1.changeWidget(
                            EditSongContainer(
                              onChangeWidget: (newWidget) {
                                if (mounted) {
                                  setState(() {
                                    activeWidget2 = const ShowImage();
                                  });
                                }
                              },
                              songId: widget.songId,
                              songUrl: widget.songUrl,
                              songImageUrl: widget.songImageUrl,
                              artistId: widget.artistId,
                              artistSongIndex: widget.artistSongIndex,
                              albumId: widget.albumId,
                              songTitle: widget.songTitle,
                              songDuration: widget.songDuration,
                            ),
                            'EditSongContainer',
                          );
                        }
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          widgetStateProvider2.changeWidget(
                              const ShowDetailSong(), 'ShowDetailSong');
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: primaryTextColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Edit Song",
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    hoverColor: primaryTextColor.withOpacity(0.1),
                    onTap: () {
                      _deleteSong(
                        widget.songId,
                        widget.songUrl,
                        widget.songImageUrl,
                        widget.artistSongIndex,
                      );
                      // print('ini adalah widget id ${widget.songId}');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: primaryTextColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Delete Song",
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSong(String songId, String songUrl, String songImageUrl,
      int artistFileIndex) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // First verify the song exists and get its details
      final List<Map<String, dynamic>> songData = await db.query(
        'songs',
        where: 'songId = ?',
        whereArgs: [songId],
      );

      if (songData.isEmpty) {
        // Instead of throwing, show a user-friendly message and return
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song has already been deleted or does not exist'),
            backgroundColor: tertiaryTextColor,
          ),
        );
        return;
      }

      final song = songData.first;
      final String artistId = song['artistId'];
      final int songDuration = song['songDuration'] ?? 0;

      // Begin transaction to ensure all operations complete together
      await db.transaction((txn) async {
        try {
          // Delete the song from songs table
          final int deletedRows = await txn.delete(
            'songs',
            where: 'songId = ?',
            whereArgs: [songId],
          );

          if (deletedRows == 0) {
            throw Exception('Failed to delete song from database');
          }

          // Update related records
          await Future.wait([
            _updateAlbumsForDeletedSong(txn, songId, songDuration),
            _updatePlaylistsForDeletedSong(txn, songId, songDuration),
            _updateUserLikesForDeletedSong(txn, songId),
            _renumberArtistSongs(txn, artistId, artistFileIndex),
          ]);

          // Update songs.json file
          await _updateSongsJson(songId);
        } catch (e) {
          print('Error in transaction: $e');
          throw Exception('Failed to update related records: $e');
        }
      });

      // Delete physical files after successful database updates
      await _deletePhysicalFiles(songUrl, songImageUrl);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song deleted successfully'),
          backgroundColor: quinaryColor,
        ),
      );
    } catch (e) {
      print('Error during song deletion: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete song: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAddToPlaylistContainer(double screenWidth, Song song) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: transparentColor),
      ),
      child: Material(
        color: tertiaryColor,
        child: Container(
          height: 270,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          decoration: BoxDecoration(
            color: transparentColor,
            borderRadius: BorderRadius.circular(4),
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
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  height: 40,
                  child: MouseRegion(
                    onEnter: (event) => setState(() {
                      _isHoveredSearchPlaylist = true;
                    }),
                    onExit: (event) => setState(() {
                      _isHoveredSearchPlaylist = false;
                    }),
                    child: TextFormField(
                      controller: _searchPlaylistController,
                      readOnly: false,
                      style: const TextStyle(color: primaryTextColor),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(8),
                        prefixIcon: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.search,
                            color: primaryTextColor,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isCreatePlaylistVisible =
                                  !_isCreatePlaylistVisible;
                            });
                          },
                          icon: Icon(
                            _isCreatePlaylistVisible ? Icons.remove : Icons.add,
                            color: primaryTextColor,
                          ),
                        ),
                        hintText: 'Search Playlist',
                        hintStyle: const TextStyle(
                          color: primaryTextColor,
                          fontSize: tinyFontSize,
                        ),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryTextColor,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: secondaryColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _isHoveredSearchPlaylist
                                ? secondaryColor
                                : primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _isCreatePlaylistVisible
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          // Panggil fungsi untuk menyimpan data playlist
                          await Provider.of<PlaylistProvider>(context,
                                  listen: false)
                              .submitNewPlaylist(context);
                          // // Update UI by calling setState if needed
                          // if (context.mounted) {
                          //   setState(() {});
                          // }
                        },
                        hoverColor: primaryTextColor.withOpacity(0.1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              SizedBox(width: 16),
                              Icon(
                                Icons.playlist_add,
                                color: primaryTextColor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Create Playlist",
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: tinyFontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Divider(
                  thickness: 1,
                  color: primaryTextColor,
                ),
              ),
              // song_menu.dart
              Expanded(
                child: Consumer<PlaylistProvider>(
                  builder: (context, playlistProvider, _) {
                    // Filter playlists berdasarkan search query
                    final filteredPlaylists = playlistProvider.displayPlaylists
                        .where((playlist) => playlist['playlistName']
                            .toString()
                            .toLowerCase()
                            .contains(
                                _searchPlaylistController.text.toLowerCase()))
                        .toList();

                    // if (playlistProvider.isFetching) {
                    //   return const Center(child: CircularProgressIndicator());
                    // }

                    if (filteredPlaylists.isEmpty) {
                      return const Center(
                        child: Text(
                          'No playlists found',
                          style: TextStyle(color: primaryTextColor),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = filteredPlaylists[index];
                        return PlaylistListItem(
                          playlist: playlist,
                          song: song,
                          onAddToPlaylist: (playlistData) async {
                            try {
                              await _addSongToPlaylist(playlistData, song);
                            } catch (error) {
                              print('Error adding song to playlist: $error');
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// New method to update songs.json after deletion
Future<void> _updateSongsJson(String deletedSongId) async {
  try {
    final fileHelper = FileStorageHelper.instance;
    Map<String, dynamic>? songData = await fileHelper.readData('songs.json');

    if (songData != null && songData['songs'] != null) {
      List<dynamic> songs = songData['songs'];
      songs.removeWhere((song) => song['songId'] == deletedSongId);
      await fileHelper.writeData('songs.json', {'songs': songs});
    }
  } catch (e) {
    print('Error updating songs.json: $e');
    // Don't throw - we want the deletion to succeed even if JSON update fails
  }
}

Future<void> _deletePhysicalFiles(String songUrl, String songImageUrl) async {
  try {
    if (songUrl.isNotEmpty) {
      final songFile = File(songUrl);
      if (await songFile.exists()) {
        await songFile.delete();
        print('Successfully deleted song file: $songUrl');
      }
    }

    if (songImageUrl.isNotEmpty) {
      final imageFile = File(songImageUrl);
      if (await imageFile.exists()) {
        await imageFile.delete();
        print('Successfully deleted image file: $songImageUrl');
      }
    }
  } catch (e) {
    print('Error deleting physical files: $e');
    // Don't throw - we want the deletion to succeed even if file deletion fails
  }
}

Future<void> _updateAlbumsForDeletedSong(
    Transaction txn, String songId, int songDuration) async {
  final List<Map<String, dynamic>> albumsWithSong = await txn.query(
    'albums',
    where: 'songListIds LIKE ?',
    whereArgs: ['%$songId%'],
  );

  for (var album in albumsWithSong) {
    List<String> songListIds = (album['songListIds'] as String)
        .split(',')
        .where((id) => id.trim().isNotEmpty) // Filter out empty strings
        .where((id) => id != songId)
        .toList();

    int newTotalDuration = (album['totalDuration'] as int?) ?? 0;
    newTotalDuration =
        (newTotalDuration - songDuration).clamp(0, double.infinity).toInt();

    await txn.update(
      'albums',
      {'songListIds': songListIds.join(','), 'totalDuration': newTotalDuration},
      where: 'albumId = ?',
      whereArgs: [album['albumId']],
    );
  }
}

Future<void> _updatePlaylistsForDeletedSong(
    Transaction txn, String songId, int songDuration) async {
  final List<Map<String, dynamic>> playlistsWithSong = await txn.query(
    'playlists',
    where: 'songListIds LIKE ?',
    whereArgs: ['%$songId%'],
  );

  for (var playlist in playlistsWithSong) {
    List<String> songListIds = (playlist['songListIds'] as String)
        .split(',')
        .where((id) => id.trim().isNotEmpty) // Filter out empty strings
        .where((id) => id != songId)
        .toList();

    int newTotalDuration = (playlist['totalDuration'] as int?) ?? 0;
    newTotalDuration =
        (newTotalDuration - songDuration).clamp(0, double.infinity).toInt();

    await txn.update(
      'playlists',
      {'songListIds': songListIds.join(','), 'totalDuration': newTotalDuration},
      where: 'playlistId = ?',
      whereArgs: [playlist['playlistId']],
    );
  }
}

Future<void> _updateUserLikesForDeletedSong(
    Transaction txn, String songId) async {
  final List<Map<String, dynamic>> users = await txn.query(
    'users',
    where: 'userLikedSongs LIKE ?',
    whereArgs: ['%$songId%'],
  );

  for (var user in users) {
    if (user['userLikedSongs'] != null) {
      List<String> likedSongs = (user['userLikedSongs'] as String)
          .split(',')
          .where((id) => id.trim().isNotEmpty) // Filter out empty strings
          .where((id) => id != songId)
          .toList();

      await txn.update(
        'users',
        {'userLikedSongs': likedSongs.join(',')},
        where: 'userId = ?',
        whereArgs: [user['userId']],
      );
    }
  }
}

Future<void> _renumberArtistSongs(
    Transaction txn, String artistId, int deletedIndex) async {
  final List<Map<String, dynamic>> remainingSongs = await txn.query(
    'songs',
    where: 'artistId = ? AND artistSongIndex > ?',
    whereArgs: [artistId, deletedIndex],
    orderBy: 'artistSongIndex ASC',
  );

  for (var song in remainingSongs) {
    await txn.update(
      'songs',
      {'artistSongIndex': song['artistSongIndex'] - 1},
      where: 'songId = ?',
      whereArgs: [song['songId']],
    );
  }
}

Future<void> _deleteFile(String filePath) async {
  if (filePath.isEmpty) return;

  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      print('Successfully deleted file: $filePath');
    }
  } catch (e) {
    print('Error deleting file $filePath: $e');
    // Don't rethrow - we want to continue even if file deletion fails
  }
}
// Helper function to add song to playlist
Future<void> _addSongToPlaylist(
  Map<String, dynamic> playlist,
  Song song,
) async {
  final updatedSongList = List<String>.from(playlist['songListIds'] ?? []);
  updatedSongList.add(song.songId);

  final newTotalDuration = (playlist['totalDuration'] as Duration) + song.songDuration;

  final updatedPlaylist = Playlist(
    playlistId: playlist['playlistId'],
    creatorId: playlist['creatorId'],
    playlistName: playlist['playlistName'],
    playlistDescription: playlist['playlistDescription'],
    playlistImageUrl: playlist['playlistImageUrl'],
    timestamp: playlist['timestamp'],
    playlistUserIndex: playlist['playlistUserIndex'],
    songListIds: updatedSongList,
    totalDuration: newTotalDuration,
  );

  await DatabaseHelper.instance.updatePlaylist(updatedPlaylist);

  // Update song's playlist IDs
  final updatedPlaylistIds = List<String>.from(song.playlistIds ?? []);
  updatedPlaylistIds.add(playlist['playlistId']);

  final updatedSong = song.copyWith(playlistIds: updatedPlaylistIds);
  await DatabaseHelper.instance.updateSong(updatedSong);
}