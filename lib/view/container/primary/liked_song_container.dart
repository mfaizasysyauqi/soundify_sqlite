import 'package:flutter/material.dart';
import 'package:soundify/provider/like_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/song_list.dart';
import 'package:soundify/provider/auth_provider.dart'; // Add this import

class LikedSongContainer extends StatefulWidget {
  const LikedSongContainer({super.key});

  @override
  State<LikedSongContainer> createState() => _LikedSongContainerState();
}

class _LikedSongContainerState extends State<LikedSongContainer> {
  String? userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WidgetStateProvider2>(context, listen: false)
            .changeWidget(const ShowDetailSong(), 'ShowDetailSong');

        // Fetch liked songs when container is initialized
        Provider.of<LikeProvider>(context, listen: false).fetchLikedSongs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double minContentWidth = 360;
    double providedMaxWidth =
        Provider.of<WidgetSizeProvider>(context).expandedWidth;

    // Get current user ID from your auth provider
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUserId;

    // Ensure providedMaxWidth is not smaller than minContentWidth
    double adjustedMaxWidth =
        providedMaxWidth.clamp(minContentWidth, double.infinity);

    if (currentUserId == null) {
      // Handle case when user is not logged in
      return const Center(
        child: Text(
          'Please log in to view content',
          style: TextStyle(color: primaryTextColor),
        ),
      );
    }

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
                minContentWidth,
                adjustedMaxWidth,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Table(
                    border: TableBorder.all(
                      color: transparentColor, // Warna border sementara
                      width: 1, // Ketebalan border
                    ),
                    columnWidths: {
                      0: const FixedColumnWidth(
                          50), // Lebar tetap untuk kolom #
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: transparentColor), // Border per sel
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: transparentColor), // Border per sel
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          transparentColor), // Border per sel
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
                Expanded(
                  child: Consumer<LikeProvider>(
                    builder: (context, likeProvider, child) {
                      return SongList(
                        userId: currentUserId,
                        pageName: "LikedSongContainer",
                        playlistId: "",
                        albumId: "",
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
