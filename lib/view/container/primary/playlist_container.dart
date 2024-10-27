import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/utils/sticky_header_delegate.dart';
import 'package:soundify/provider/playlist_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/view/container/secondary/menu/playlist_menu.dart';

import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/song_list.dart';

// Import the uuid package

class PlaylistContainer extends StatefulWidget {
  final String playlistId;
  const PlaylistContainer({super.key, required this.playlistId});

  @override
  State<PlaylistContainer> createState() => _PlaylistContainerState();
}

bool showModal = false;
OverlayEntry? _overlayEntry;
Uint8List? _selectedImage;

final TextEditingController _playlistNameController = TextEditingController();
final TextEditingController _playlistDescriptionController =
    TextEditingController();

final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

class _PlaylistContainerState extends State<PlaylistContainer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlaylistData();
    });
  }

  // Function untuk memuat data playlist (jika perlu)
  void _loadPlaylistData() {
    Provider.of<PlaylistProvider>(context, listen: false)
        .fetchPlaylistById(widget.playlistId)
        .catchError((error) {
      // Handle error, maybe show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading playlist: $error')),
      );
    });
  }

  Future<void> _showPlaylistDescriptionModal(
      BuildContext context, String creatorName) async {
    // Access the PlaylistProvider
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

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
                                child: playlistProvider.playlistImageUrl.isEmpty
                                    ? Container(
                                        color: primaryTextColor,
                                        child: Icon(Icons.library_music,
                                            color: primaryColor, size: 25))
                                    : Image.file(
                                        File(playlistProvider.playlistImageUrl),
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
                                    playlistProvider.playlistName,
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
                              playlistProvider.playlistDescription,
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
        //   return const Center(child: CircularProgressIndicator());
        // }
        if (snapshot.hasError || !snapshot.hasData) {
          // Handle the error or the case where no user ID is available
          return const Center(child: Text('Error fetching user ID'));
        }

        // Extract the user ID from the snapshot
        final currentUserId = snapshot.data;

        return Consumer<PlaylistProvider>(
          builder: (context, playlistProvider, child) {
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
                                      child: _buildPlaylistHeader(
                                          playlistProvider, isMediumScreen),
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
                            pageName: "PlaylistContainer",
                            playlistId: widget.playlistId,
                            albumId: "",
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

  Widget _buildPlaylistHeader(
      PlaylistProvider playlistProvider, bool isMediumScreen) {
    final widgetStateProvider2 =
        Provider.of<WidgetStateProvider2>(context, listen: false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlaylistImage(playlistProvider),
        SizedBox(width: isMediumScreen ? 16 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: playlistProvider.playlistDescription.isNotEmpty
                      ? 0.0
                      : (isMediumScreen ? 28.0 : 38.0),
                ),
                child: Text(
                  playlistProvider.playlistName,
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
                    text: playlistProvider.playlistDescription,
                    style: TextStyle(
                      color: senaryColor, // quaternaryTextColor
                      fontWeight: mediumWeight,
                      fontSize: isMediumScreen ? 14 : 12, // smallFontSize
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        // Fetch playlist data if needed
                        Playlist? playlist = await _databaseHelper
                            .getPlaylistById(playlistProvider.playlistId);
                        if (playlist != null) {
                          _showPlaylistDescriptionModal(
                              context, playlist.creatorName ?? '');
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
            Playlist? playlist = await _databaseHelper.getPlaylistById(
                playlistProvider
                    .playlistId); // Assuming playlistProvider has playlistId

            if (playlist != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widgetStateProvider2.changeWidget(
                    PlaylistMenu(
                      playlistName: playlistProvider.playlistName,
                      playlistImageUrl: playlistProvider.playlistImageUrl,
                      creatorName: playlist.creatorName ?? '',
                    ),
                    'PlaylistMenu',
                  );
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPlaylistImage(PlaylistProvider playlistProvider) {
    String playlistImageUrl = playlistProvider.playlistImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: playlistImageUrl == '' ? primaryTextColor : tertiaryColor,
        ),
        child: playlistImageUrl == ''
            ? Icon(Icons.library_music, color: primaryColor, size: 60)
            : Image.file(
                File(playlistImageUrl), // Convert String to File
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
    _playlistNameController.dispose();
    _playlistDescriptionController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}
