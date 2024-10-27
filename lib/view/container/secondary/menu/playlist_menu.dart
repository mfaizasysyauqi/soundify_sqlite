import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/provider/playlist_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/home_container.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/style/style.dart';
import 'package:file_picker/file_picker.dart';

class PlaylistMenu extends StatefulWidget {
  final String playlistName;
  final String playlistImageUrl;
  final String creatorName;
  const PlaylistMenu({
    super.key,
    required this.playlistName,
    required this.playlistImageUrl,
    required this.creatorName,
  });

  @override
  State<PlaylistMenu> createState() => _PlaylistMenuState();
}

final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

OverlayEntry? _overlayEntry;

class _PlaylistMenuState extends State<PlaylistMenu> {
  @override
  Widget build(BuildContext context) {
    // Access the PlaylistProvider
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8.0, right: 8.0),
          child: Row(
            children: [
              // Only show index if it exists
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const Text(
                  '𝅗𝅥',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                  child: widget.playlistImageUrl.isEmpty
                      ? Container(
                          color: primaryTextColor,
                          child: Icon(Icons.library_music,
                              color: primaryColor, size: 25))
                      : Image.file(
                          File(widget.playlistImageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: senaryColor,
                            child: const Icon(Icons.broken_image,
                                color: Colors.white, size: 25),
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
                      widget.playlistName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontWeight: mediumWeight,
                        fontSize: smallFontSize,
                      ),
                    ),
                    widget.creatorName.isNotEmpty
                        ? Text(
                            widget.creatorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: quaternaryTextColor,
                              fontWeight: mediumWeight,
                              fontSize: microFontSize,
                            ),
                          )
                        : const SizedBox.shrink(),
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
        Material(
          color: transparentColor,
          child: InkWell(
            hoverColor: primaryTextColor.withOpacity(0.1),
            onTap: () {
              _showEditPlaylistModal(context); // Menampilkan AlertDialog
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: primaryTextColor,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Edit Playlist",
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
        Material(
          color: transparentColor,
          child: InkWell(
            hoverColor: primaryTextColor.withOpacity(0.1),
            onTap: () {
              _deletePlaylist(
                playlistProvider.playlistId,
                playlistProvider.playlistImageUrl,
              );
              Provider.of<WidgetStateProvider1>(context, listen: false)
                  .changeWidget(const HomeContainer(), 'Home Container');

              Provider.of<WidgetStateProvider2>(context, listen: false)
                  .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: primaryTextColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    // Menambahkan Expanded agar teks menyesuaikan ruang yang tersedia
                    child: Text(
                      "Delete Playlist and Songs",
                      style: TextStyle(
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
      ],
    );
  }

  void _showEditPlaylistModal(BuildContext context) {
    // Access the PlaylistProvider
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    // Controllers for TextFormField
    TextEditingController _playlistNameController =
        TextEditingController(text: playlistProvider.playlistName);
    TextEditingController _playlistDescriptionController =
        TextEditingController(text: playlistProvider.playlistDescription);

    // Variable to store the selected image file path
    String? _selectedImagePath;

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
                    height: 248,
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
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Playlist',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _closeModal();
                              },
                              child: const Icon(
                                Icons.close,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Content
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // FilePicker to select image
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );

                                if (result != null) {
                                  setState(() {
                                    // Store the selected image path
                                    _selectedImagePath =
                                        result.files.single.path;
                                  });
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: _selectedImagePath == null &&
                                            playlistProvider
                                                .playlistImageUrl.isEmpty
                                        ? primaryTextColor
                                        : tertiaryColor,
                                    image: _selectedImagePath != null
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(_selectedImagePath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : playlistProvider
                                                .playlistImageUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: FileImage(
                                                  File(playlistProvider
                                                      .playlistImageUrl),
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: _selectedImagePath == null &&
                                          playlistProvider
                                              .playlistImageUrl.isEmpty
                                      ? Icon(
                                          Icons.library_music,
                                          color: primaryColor,
                                          size: 80,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _playlistNameController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Playlist name',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      hintText: 'Enter playlist name',
                                      hintStyle:
                                          TextStyle(color: primaryTextColor),
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _playlistDescriptionController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Description',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      hintText: 'Enter playlist description',
                                      hintStyle:
                                          TextStyle(color: primaryTextColor),
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          // Get the updated values
                                          final newName =
                                              _playlistNameController.text;
                                          final newDescription =
                                              _playlistDescriptionController
                                                  .text;
                                          final newImagePath =
                                              _selectedImagePath ??
                                                  playlistProvider
                                                      .playlistImageUrl;

                                          // Create updated playlist object
                                          final updatedPlaylist = Playlist(
                                            playlistId:
                                                playlistProvider.playlistId,
                                            creatorId:
                                                playlistProvider.creatorId,
                                            playlistName: newName,
                                            playlistDescription: newDescription,
                                            playlistImageUrl: newImagePath,
                                            timestamp:
                                                playlistProvider.timestamp,
                                            playlistUserIndex: playlistProvider
                                                .playlistUserIndex,
                                            songListIds:
                                                playlistProvider.songListIds,
                                            playlistLikeIds: playlistProvider
                                                .playlistLikeIds,
                                            totalDuration: playlistProvider
                                                    .totalDuration ??
                                                Duration.zero,
                                          );

                                          // Update playlist in database
                                          await DatabaseHelper.instance
                                              .updatePlaylist(updatedPlaylist);

                                          // Update provider
                                          playlistProvider.editPlaylist(
                                            newName,
                                            newDescription,
                                            newImagePath,
                                          );

                                          _closeModal(); // Close modal
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            color: primaryColor,
                                            width: 80,
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: primaryTextColor,
                                                fontSize: smallFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  }

  void _closeModal() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove(); // Hapus overlay
      _overlayEntry = null;
    }
  }

  Future<void> _deletePlaylist(
      String playlistId, String playlistImageUrl) async {
    try {
      // Delete the playlist
      await _databaseHelper.deletePlaylist(playlistId);

      // Update UI
      if (mounted) {
        Provider.of<WidgetStateProvider1>(context, listen: false)
            .changeWidget(const HomeContainer(), 'Home Container');
        Provider.of<WidgetStateProvider2>(context, listen: false)
            .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
      }
    } catch (e) {
      print("Error deleting playlist: $e");
    }
  }
}
