import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/provider/album_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/home_container.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/style/style.dart';
import 'package:file_picker/file_picker.dart';

class AlbumMenu extends StatefulWidget {
  final String albumName;
  final String albumImageUrl;
  final String creatorName;
  const AlbumMenu({
    super.key,
    required this.albumName,
    required this.albumImageUrl,
    required this.creatorName,
  });

  @override
  State<AlbumMenu> createState() => _AlbumMenuState();
}

final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

OverlayEntry? _overlayEntry;

class _AlbumMenuState extends State<AlbumMenu> {
  @override
  Widget build(BuildContext context) {
    // Access the AlbumProvider
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
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
                  '𝅗𝅥',
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
                  child: widget.albumImageUrl.isEmpty
                      ? Container(
                          color: primaryTextColor,
                          child:
                              Icon(Icons.album, color: primaryColor, size: 25))
                      : Image.file(
                          File(widget.albumImageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey,
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
                      widget.albumName,
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
                        : SizedBox.shrink(),
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
          color: transparentColor,
          child: InkWell(
            hoverColor: primaryTextColor.withOpacity(0.1),
            onTap: () {
              _showEditAlbumModal(context); // Menampilkan AlertDialog
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
                    "Edit Album",
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
              _deleteAlbum(
                albumProvider.albumId,
                albumProvider.albumImageUrl,
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
                  Text(
                    "Delete Album",
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
      ],
    );
  }

  void _showEditAlbumModal(BuildContext context) {
    // Access the AlbumProvider
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    // Controllers for TextFormField
    TextEditingController _albumNameController =
        TextEditingController(text: albumProvider.albumName);
    TextEditingController _albumDescriptionController =
        TextEditingController(text: albumProvider.albumDescription);

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
                              'Edit Album',
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
                                            albumProvider.albumImageUrl.isEmpty
                                        ? primaryTextColor
                                        : tertiaryColor,
                                    image: _selectedImagePath != null
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(_selectedImagePath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : albumProvider.albumImageUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: FileImage(
                                                  File(albumProvider
                                                      .albumImageUrl),
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: _selectedImagePath == null &&
                                          albumProvider.albumImageUrl.isEmpty
                                      ? Icon(
                                          Icons.album,
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
                                    controller: _albumNameController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Album name',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      hintText: 'Enter album name',
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
                                    controller: _albumDescriptionController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Description',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      hintText: 'Enter album description',
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
                                              _albumNameController.text;
                                          final newDescription =
                                              _albumDescriptionController.text;
                                          final newImagePath =
                                              _selectedImagePath ??
                                                  albumProvider.albumImageUrl;

                                          // Create updated album object
                                          final updatedAlbum = Album(
                                            albumId: albumProvider.albumId,
                                            creatorId: albumProvider.creatorId,
                                            albumName: newName,
                                            albumDescription: newDescription,
                                            albumImageUrl: newImagePath,
                                            timestamp: albumProvider.timestamp,
                                            albumUserIndex:
                                                albumProvider.albumUserIndex,
                                            songListIds:
                                                albumProvider.songListIds,
                                            albumLikeIds:
                                                albumProvider.albumLikeIds,
                                            totalDuration:
                                                albumProvider.totalDuration ??
                                                    Duration.zero,
                                          );

                                          // Update album in database
                                          await DatabaseHelper.instance
                                              .updateAlbum(updatedAlbum);

                                          // Update provider
                                          albumProvider.editAlbum(
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

  Future<void> _deleteAlbum(String albumId, String albumImageUrl) async {
    try {
      // Get songs in album
      List<Song> albumSongs = await _databaseHelper.getSongsByAlbum(albumId);

      // Delete each song in the album
      for (var song in albumSongs) {
        await _databaseHelper.deleteSong(song.songId);
      }

      // Delete the album
      await _databaseHelper.deleteAlbum(albumId);

      // Update UI
      if (mounted) {
        Provider.of<WidgetStateProvider1>(context, listen: false)
            .changeWidget(const HomeContainer(), 'Home Container');
        Provider.of<WidgetStateProvider2>(context, listen: false)
            .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
      }
    } catch (e) {
      print("Error deleting album: $e");
    }
  }
}
