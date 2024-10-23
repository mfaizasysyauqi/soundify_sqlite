import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/edit_song_container.dart';
import 'package:soundify/view/container/secondary/create/show_image.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/main_page.dart';
import 'package:soundify/view/style/style.dart';
import 'package:sqflite/sqflite.dart' show Transaction;

class SongMenu extends StatefulWidget {
  final Function(Widget) onChangeWidget;
  final String songId;
  final String songUrl;
  final String songImageUrl;
  final String artistId;
  final String albumId;
  final String? artistName;
  final int artistFileIndex;
  final String songTitle;
  final Duration songDuration;
  final int? originalIndex; // Made nullable with ?

  const SongMenu({
    super.key,
    required this.onChangeWidget,
    required this.songId,
    required this.songUrl,
    required this.songImageUrl,
    required this.artistId,
    required this.artistName,
    required this.albumId,
    required this.artistFileIndex,
    required this.songTitle,
    required this.songDuration,
    this.originalIndex, // Made optional by removing required
  });

  @override
  State<SongMenu> createState() => _SongMenuState();
}

class _SongMenuState extends State<SongMenu> {
  bool isLiked = false; // Added missing isLiked variable

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
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: primaryTextColor.withOpacity(0.1),
            onTap: () {
              // Add to playlist action
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: primaryTextColor,
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: primaryTextColor.withOpacity(0.1),
            onTap: () {
              if (!mounted) return;
              setState(() {
                isLiked = !isLiked;
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
                      isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                      color: isLiked ? secondaryColor : primaryTextColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isLiked
                          ? "Remove from your Liked Songs"
                          : "Save to your Liked Songs",
                      style: const TextStyle(
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Divider(
            thickness: 1,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: primaryTextColor.withOpacity(0.1),
            onTap: () {
              final widgetStateProvider1 =
                  Provider.of<WidgetStateProvider1>(context, listen: false);
              final widgetStateProvider2 =
                  Provider.of<WidgetStateProvider2>(context, listen: false);

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
                      artistFileIndex: widget.artistFileIndex,
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
                widget.artistFileIndex,
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
                    ),
                  ],
                ),
              ),
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
