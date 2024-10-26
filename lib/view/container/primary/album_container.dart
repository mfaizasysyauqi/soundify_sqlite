import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/utils/sticky_header_delegate.dart';
import 'package:soundify/provider/album_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/view/container/primary/home_container.dart';
import 'package:soundify/view/container/secondary/menu/album_menu.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';

import 'package:soundify/view/style/style.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/song_list.dart';

// Import the uuid package

class AlbumContainer extends StatefulWidget {
  final String albumId;
  const AlbumContainer({super.key, required this.albumId});

  @override
  State<AlbumContainer> createState() => _AlbumContainerState();
}

bool showModal = false;
OverlayEntry? _overlayEntry;
Uint8List? _selectedImage;

final TextEditingController _albumNameController = TextEditingController();
final TextEditingController _albumDescriptionController =
    TextEditingController();

final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

class _AlbumContainerState extends State<AlbumContainer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlbumData();
    });
  }

  // Function untuk memuat data album (jika perlu)
  void _loadAlbumData() {
    Provider.of<AlbumProvider>(context, listen: false)
        .fetchAlbumById(widget.albumId)
        .catchError((error) {
      // Handle error, maybe show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading album: $error')),
      );
    });
  }

  void _showModal(BuildContext context) {
    // Access the AlbumProvider
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // GestureDetector untuk mendeteksi klik di luar area modal
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _closeModal(); // Tutup modal jika area luar modal diklik
              },
              child: Container(
                color: Colors.transparent, // Area di luar modal transparan
              ),
            ),
          ),
          Positioned(
            right: 410, // Posisi modal container
            top: 130, // Posisi modal container
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 148, // Atur lebar container
                height: 96, // Atur tinggi container
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  color: tertiaryColor, // Background container
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
                    Material(
                      color: transparentColor,
                      child: InkWell(
                        hoverColor: primaryTextColor.withOpacity(0.1),
                        onTap: () {
                          setState(() {});
                          _closeModal(); // Tutup modal setelah action
                          _showEditProfileModal(
                              context); // Menampilkan AlertDialog
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 200,
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
                          Provider.of<WidgetStateProvider1>(context,
                                  listen: false)
                              .changeWidget(
                                  const HomeContainer(), 'Home Container');

                          Provider.of<WidgetStateProvider2>(context,
                                  listen: false)
                              .changeWidget(
                                  const ShowDetailSong(), 'ShowDetailSong');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 200,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!); // Tampilkan overlay
  }

  void _showEditProfileModal(BuildContext context) {
    // Access the AlbumProvider
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

    // Controllers for TextFormField
    TextEditingController _albumNameController =
        TextEditingController(text: albumProvider.albumName);
    TextEditingController _albumDescriptionController =
        TextEditingController(text: albumProvider.albumDescription);

    // Variable to store the selected image
    Uint8List? _selectedImage;

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
                                  final pickedImageFile =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                  );

                                  if (pickedImageFile != null) {
                                    setState(() {
                                      // Store the selected image
                                      _selectedImage =
                                          pickedImageFile.files.first.bytes;
                                    });
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: _selectedImage == null &&
                                              albumProvider
                                                  .albumImageUrl.isEmpty
                                          ? primaryTextColor
                                          : tertiaryColor,
                                      image: _selectedImage != null
                                          ? DecorationImage(
                                              image: MemoryImage(
                                                _selectedImage!, // Menggunakan MemoryImage untuk gambar in-memory
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : albumProvider
                                                  .albumImageUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: FileImage(
                                                    File(albumProvider
                                                        .albumImageUrl), // Menggunakan FileImage untuk gambar dari direktori lokal
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null, // Tidak ada gambar jika keduanya null
                                    ),
                                    child: _selectedImage == null &&
                                            albumProvider.albumImageUrl.isEmpty
                                        ? Icon(
                                            Icons.album,
                                            color: primaryColor,
                                            size: 80,
                                          )
                                        : null, // Menampilkan ikon hanya jika tidak ada gambar
                                  ),
                                )),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future:
          _databaseHelper.getCurrentUserId(), // Fetch user ID asynchronously
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while fetching the user ID
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          // Handle the error or the case where no user ID is available
          return Center(child: Text('Error fetching user ID'));
        }

        // Extract the user ID from the snapshot
        final currentUserId = snapshot.data;

        return Consumer<AlbumProvider>(
          builder: (context, albumProvider, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                const minContentWidth = 360.0;
                final providedMaxWidth =
                    Provider.of<WidgetSizeProvider>(context).expandedWidth;
                final adjustedMaxWidth =
                    providedMaxWidth.clamp(minContentWidth, double.infinity);

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
                          maxWidth: screenWidth.clamp(
                              minContentWidth, adjustedMaxWidth),
                        ),
                        child: NestedScrollView(
                          headerSliverBuilder:
                              (BuildContext context, bool innerBoxIsScrolled) {
                            return [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: _buildAlbumHeader(
                                          albumProvider, isMediumScreen),
                                    ),
                                  ],
                                ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: StickyHeaderDelegate(
                                  child: _buildSongListHeader(isMediumScreen),
                                ),
                              ),
                            ];
                          },
                          body: SongList(
                            userId: currentUserId!,
                            pageName: "AlbumContainer",
                            playlistId: "",
                            albumId: albumProvider.albumId,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumHeader(AlbumProvider albumProvider, bool isMediumScreen) {
    final widgetStateProvider2 =
        Provider.of<WidgetStateProvider2>(context, listen: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAlbumImage(albumProvider),
        SizedBox(width: isMediumScreen ? 16 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: albumProvider.albumDescription.isNotEmpty
                      ? 0.0
                      : (isMediumScreen ? 28.0 : 38.0),
                ),
                child: Text(
                  albumProvider.albumName,
                  style: TextStyle(
                    color: Colors.white, // primaryTextColor
                    fontSize: isMediumScreen ? 50 : 30,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                albumProvider.albumDescription,
                style: TextStyle(
                  color: Colors.grey, // quaternaryTextColor
                  fontSize: isMediumScreen ? 14 : 12, // smallFontSize
                ),
                maxLines: isMediumScreen ? 2 : 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () async {
            // Make onPressed async
            // First fetch the album data
            Album? album = await _databaseHelper.getAlbumById(
                albumProvider.albumId); // Assuming albumProvider has albumId

            if (album != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widgetStateProvider2.changeWidget(
                    AlbumMenu(
                      albumName: albumProvider.albumName,
                      albumImageUrl: albumProvider.albumImageUrl,
                      creatorName: album.creatorName ??
                          '', // Now we can use the creator name
                    ),
                    'AlbumMenu',
                  );
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAlbumImage(AlbumProvider albumProvider) {
    String albumImageUrl = albumProvider.albumImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: albumImageUrl == '' ? primaryTextColor : tertiaryColor,
        ),
        child: albumImageUrl == ''
            ? Icon(Icons.album, color: primaryColor, size: 60)
            : Image.file(
                File(albumImageUrl), // Convert String to File
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey,
                  child: const Icon(Icons.broken_image,
                      color: Colors.white, size: 60),
                ),
              ),
      ),
    );
  }

  Widget _buildSongListHeader(bool isMediumScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Padding(
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
                      border:
                          Border.all(color: transparentColor), // Border per sel
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
                      border:
                          Border.all(color: transparentColor), // Border per sel
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
                        border: Border.all(
                            color: transparentColor), // Border per sel
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
                        border: Border.all(
                            color: transparentColor), // Border per sel
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
                          border: Border.all(
                              color: transparentColor), // Border per sel
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
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Divider(
            color: primaryTextColor,
          ),
        ),
      ],
    );
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

  Future<void> _updateAlbum(AlbumProvider albumProvider) async {
    String? currentUserId = await _databaseHelper.getCurrentUserId();
    if (currentUserId != null) {
      try {
        Album updatedAlbum = Album(
          albumId: albumProvider.albumId,
          creatorId: currentUserId,
          albumName: _albumNameController.text.isNotEmpty
              ? _albumNameController.text
              : albumProvider.albumName,
          albumDescription: _albumDescriptionController.text.isNotEmpty
              ? _albumDescriptionController.text
              : albumProvider.albumDescription,
          albumImageUrl: _selectedImage != null
              ? 'path_to_saved_image' // You'll need to implement image storage
              : albumProvider.albumImageUrl,
          timestamp: DateTime.now(),
          albumUserIndex: albumProvider.albumUserIndex,
          albumLikeIds: albumProvider.albumLikeIds,
          songListIds: albumProvider.songListIds,
          totalDuration: albumProvider.totalDuration ?? Duration.zero,
        );

        await _databaseHelper.updateAlbum(updatedAlbum);

        // Update provider
        albumProvider.updateAlbum(
          updatedAlbum.albumImageUrl,
          updatedAlbum.albumName,
          updatedAlbum.albumDescription,
          updatedAlbum.creatorId,
          updatedAlbum.albumId,
          updatedAlbum.timestamp,
          updatedAlbum.albumUserIndex,
          updatedAlbum.songListIds,
          updatedAlbum.albumLikeIds,
          updatedAlbum.totalDuration,
        );

        _closeModal();
      } catch (e) {
        print("Error updating album: $e");
      }
    }
  }

  @override
  void dispose() {
    _albumNameController.dispose();
    _albumDescriptionController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}
