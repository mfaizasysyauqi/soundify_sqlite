import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/view/style/style.dart';

class PlayList extends StatefulWidget {
  final String creatorId;
  final String playlistId;
  final String playlistName;
  final String playlistDescription;
  final String playlistImageUrl;
  final DateTime timestamp;
  final int playlistUserIndex;
  final List songListIds;
  final int totalDuration;

  const PlayList({
    super.key,
    required this.creatorId,
    required this.playlistId,
    required this.playlistName,
    required this.playlistDescription,
    required this.playlistImageUrl,
    required this.timestamp,
    required this.playlistUserIndex,
    required this.songListIds,
    required this.totalDuration,
  });

  @override
  State<PlayList> createState() => _PlayListState();
}

class _PlayListState extends State<PlayList> {
  // Cache untuk menyimpan user name berdasarkan creatorId
  Map<String, String?> userNameCache = {};

  // Fungsi untuk mengambil nama pengguna dari SQLite
  Future<String> fetchUserName(String creatorId) async {
    if (userNameCache.containsKey(creatorId)) {
      return userNameCache[creatorId] ?? 'Unknown';
    } else {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'users',
        columns: ['name'],
        where: 'userId = ?',
        whereArgs: [creatorId],
      );

      String? userName;
      if (result.isNotEmpty) {
        userName = result.first['name'] as String?;
        userNameCache[creatorId] = userName; // Simpan di cache
      } else {
        userName = 'Unknown';
        userNameCache[creatorId] = userName;
      }

      return userName ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: primaryColor,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: widget.playlistImageUrl.isEmpty
                    ? primaryTextColor
                    : tertiaryColor,
              ),
              child: widget.playlistImageUrl.isEmpty
                  ? Icon(
                      Icons.library_music,
                      color: primaryColor,
                    )
                  : Image.file(
                      File(widget.playlistImageUrl),
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image: $error");
                        return Container(
                          color: Colors.grey,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        );
                      },
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playlistName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<String>(
                  future: fetchUserName(widget.creatorId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        '',
                        style: TextStyle(
                          color: quaternaryTextColor,
                          fontSize: microFontSize,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return const Text(
                        'Error',
                        style: TextStyle(
                          color: quaternaryTextColor,
                          fontSize: microFontSize,
                        ),
                      );
                    } else {
                      return Text(
                        snapshot.data ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: quaternaryTextColor,
                          fontSize: microFontSize,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
