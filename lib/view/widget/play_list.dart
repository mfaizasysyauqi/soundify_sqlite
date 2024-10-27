import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soundify/view/style/style.dart';

class PlayList extends StatefulWidget {
  final String playlistImageUrl;
  final String playlistName;
  final String creatorName;

  const PlayList({
    super.key,
    required this.playlistImageUrl,
    required this.playlistName,
    required this.creatorName,
  });

  @override
  State<PlayList> createState() => _PlayListState();
}

class _PlayListState extends State<PlayList> {
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
                Text(
                  widget.creatorName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: quaternaryTextColor,
                    fontSize: microFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
