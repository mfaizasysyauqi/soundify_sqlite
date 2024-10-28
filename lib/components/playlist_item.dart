// Extracted PlaylistListItem widget
import 'package:flutter/material.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/view/style/style.dart';

class PlaylistListItem extends StatefulWidget {
  final Map<String, dynamic> playlist;
  final Song song;
  final Function(Map<String, dynamic>) onAddToPlaylist;

  const PlaylistListItem({
    required this.playlist,
    required this.song,
    required this.onAddToPlaylist,
    Key? key,
  }) : super(key: key);

  @override
  _PlaylistListItemState createState() => _PlaylistListItemState();
}

class _PlaylistListItemState extends State<PlaylistListItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Container(
        color: isHovered
            ? primaryTextColor.withOpacity(0.1)
            : Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0.0,
            horizontal: 16.0,
          ),
          title: Text(
            widget.playlist['playlistName'],
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: tinyFontSize,
            ),
          ),
          onTap: () => widget.onAddToPlaylist(widget.playlist),
        ),
      ),
    );
  }
}
