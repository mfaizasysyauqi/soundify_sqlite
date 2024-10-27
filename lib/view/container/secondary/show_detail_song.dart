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
    final screenWidth = MediaQuery.of(context).size.width;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (songProvider.songImageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.file(
                          File(songProvider.songImageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: screenWidth * 0.8,
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
                        width: screenWidth * 0.8,
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
                if (songProvider.songImageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: screenWidth,
                        color: tertiaryColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (songProvider.bioImageUrl?.isNotEmpty ?? false)
                              _buildBioImageSection(songProvider, screenWidth)
                            else
                              _buildDefaultArtistSection(songProvider),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                            if (songProvider.userBio.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Padding(
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
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBioImageSection(SongProvider songProvider, double screenWidth) {
    return Stack(
      children: [
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: songProvider.userBio.isNotEmpty ? 0.75 : 0.9,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(songProvider.bioImageUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: primaryTextColor,
                    width: screenWidth * 0.22,
                    height: screenWidth * 0.22,
                    child: Icon(
                      Icons.portrait,
                      color: primaryColor,
                      size: screenWidth * 0.11,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _buildAboutArtistLabel(),
      ],
    );
  }

  Widget _buildDefaultArtistSection(SongProvider songProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildDefaultAboutArtistLabel(), // No need to change this call
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundColor: (songProvider.profileImageUrl?.isEmpty ?? true)
                ? primaryTextColor
                : tertiaryColor,
            backgroundImage: (songProvider.profileImageUrl?.isNotEmpty ?? false)
                ? FileImage(File(songProvider.profileImageUrl!))
                : null,
            child: (songProvider.profileImageUrl?.isEmpty ?? true)
                ? Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 40,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutArtistLabel() {
    return Positioned(
      top: 10,
      left: 10,
      child: Text(
        'About the artist',
        style: TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(-1.0, 1.0),
              blurRadius: 2.0,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAboutArtistLabel() {
    return Text(
      'About the artist',
      style: TextStyle(
        color: primaryTextColor,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: const Offset(-1.0, 1.0),
            blurRadius: 2.0,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
