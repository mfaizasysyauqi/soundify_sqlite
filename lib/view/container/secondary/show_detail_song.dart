import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/view/style/style.dart';

class ShowDetailSong extends StatefulWidget {
  const ShowDetailSong({super.key});

  @override
  State<ShowDetailSong> createState() => _ShowDetailSongState();
}

class _ShowDetailSongState extends State<ShowDetailSong> {
  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    // Get the screen width using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20), // Membuat sudut melengkung pada Scaffold
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(
              8.0), // Menambahkan padding di seluruh Scaffold
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                songProvider.songImageUrl.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.file(
                              File(songProvider
                                  .songImageUrl), // Ensure this is a valid file path
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: screenWidth *
                            0.8, // Set text width as 80% of screen width
                        child: Text(
                          songProvider.songTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: hugeFontSize,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth *
                            0.8, // Set text width as 80% of screen width
                        child: Text(
                          songProvider.artistName ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: quaternaryTextColor,
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                songProvider.songImageUrl.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: screenWidth * 1, // Same width as the image
                            color: tertiaryColor,

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                songProvider.bioImageUrl!.isNotEmpty
                                    ? Stack(
                                        children: [
                                          ClipRect(
                                            child: Align(
                                              alignment: Alignment
                                                  .topCenter, // Align to the top
                                              heightFactor: songProvider
                                                      .userBio.isNotEmpty
                                                  ? 0.75
                                                  : 0.9, // Show only 75% of the image
                                              child: AspectRatio(
                                                aspectRatio: 1,
                                                child: Image.file(
                                                  File(
                                                    songProvider.bioImageUrl ??
                                                        '',
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color: primaryTextColor,
                                                      width: screenWidth * 0.22,
                                                      height:
                                                          screenWidth * 0.22,
                                                      child: Icon(
                                                        Icons.portrait,
                                                        color: primaryColor,
                                                        size:
                                                            screenWidth * 0.11,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Text(
                                              'About the artist',
                                              style: TextStyle(
                                                color: primaryTextColor,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(-1.0,
                                                        1.0), // Posisi bayangan (x, y)
                                                    blurRadius:
                                                        2.0, // Tingkat blur
                                                    color: Colors.black
                                                        .withOpacity(
                                                            0.5), // Warna bayangan
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              height: 16,
                                            ),
                                            Text(
                                              'About the artist',
                                              style: TextStyle(
                                                color: primaryTextColor,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(-1.0,
                                                        1.0), // Posisi bayangan (x, y)
                                                    blurRadius:
                                                        2.0, // Tingkat blur
                                                    color: Colors.black
                                                        .withOpacity(
                                                            0.5), // Warna bayangan
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundColor: (songProvider
                                                      .profileImageUrl!.isEmpty)
                                                  ? primaryTextColor
                                                  : tertiaryColor,
                                              backgroundImage: songProvider
                                                      .profileImageUrl!
                                                      .isNotEmpty
                                                  ? NetworkImage(songProvider
                                                          .profileImageUrl ??
                                                      '')
                                                  : null, // Assign NetworkImage if _profileImageUrl is valid
                                              child: (songProvider
                                                      .profileImageUrl!.isEmpty)
                                                  ? Icon(
                                                      Icons.person,
                                                      color: primaryColor,
                                                      size: 40,
                                                    )
                                                  : null, // Show icon if no image is selected and no profileImageUrl exists
                                            ),
                                          ],
                                        ),
                                      ),
                                // Container replacing the cropped area
                                const SizedBox(
                                  height: 16,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    songProvider.artistName ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                songProvider.userBio.isNotEmpty
                                    ? const SizedBox(
                                        height: 4,
                                      )
                                    : const SizedBox.shrink(),
                                songProvider.userBio.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Text(
                                          songProvider.userBio,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: quaternaryTextColor,
                                            fontSize: microFontSize,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                const SizedBox(
                                  height: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
