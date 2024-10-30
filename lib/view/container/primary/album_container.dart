import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/utils/sticky_header_delegate.dart';
import 'package:soundify/provider/album_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/view/container/secondary/menu/album_menu.dart';

import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/song_list.dart';

// Import the uuid package

class AlbumContainer extends StatefulWidget {
  final String albumId;
  const AlbumContainer({super.key, required this.albumId});

  @override
  State<AlbumContainer> createState() => _AlbumContainerState();
}

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

  Future<void> _showAlbumDescriptionModal(
      BuildContext context, String creatorName) async {
    // Access the AlbumProvider
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);

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
                    height: 300, // Adjust height as needed
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
                        Row(
                          children: [
                            // Song image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: albumProvider.albumImageUrl.isEmpty
                                    ? Container(
                                        color: primaryTextColor,
                                        child: Icon(Icons.library_music,
                                            color: primaryColor, size: 25))
                                    : Image.file(
                                        File(albumProvider.albumImageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
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
                                    albumProvider.albumName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: mediumWeight,
                                      fontSize: smallFontSize,
                                    ),
                                  ),
                                  creatorName.isNotEmpty
                                      ? Text(
                                          creatorName,
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
                                _closeModal();
                              },
                              icon: const Icon(
                                Icons.close,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          thickness: 1,
                          color: primaryTextColor,
                        ),
                        Expanded(
                          // Make the scrollable area expand
                          child: SingleChildScrollView(
                            child: Text(
                              albumProvider.albumDescription,
                              style: const TextStyle(
                                color: quaternaryTextColor,
                                fontWeight: mediumWeight,
                                fontSize: microFontSize,
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
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   // Show a loading indicator while fetching the user ID
        //   return Center(child: CircularProgressIndicator());
        // }
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
              IntrinsicWidth(
                child: RichText(
                  text: TextSpan(
                    text: albumProvider.albumDescription,
                    style: TextStyle(
                      color: quaternaryTextColor, // quaternaryTextColor
                      fontWeight: mediumWeight,
                      fontSize: isMediumScreen ? 14 : 12, // smallFontSize
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        // Fetch album data if needed
                        Album? album = await _databaseHelper
                            .getAlbumById(albumProvider.albumId);
                        if (album != null) {
                          _showAlbumDescriptionModal(
                              context, album.creatorName ?? '');
                        }
                      },
                  ),
                  maxLines: isMediumScreen ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
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

  @override
  void dispose() {
    _albumNameController.dispose();
    _albumDescriptionController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}
