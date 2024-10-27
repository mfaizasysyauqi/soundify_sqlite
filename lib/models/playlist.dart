// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Playlist {
  late String playlistId;
  final String creatorId;
  final String playlistName;
  late String? playlistDescription;
  late String? playlistImageUrl;
  final DateTime timestamp; // Use DateTime for timestamp
  final int playlistUserIndex;
  late List<String>? songListIds;
  late List<String>? playlistLikeIds;
  late final Duration totalDuration;

  String? creatorName;

  Playlist({
    required this.playlistId,
    required this.creatorId,
    required this.playlistName,
    this.playlistDescription,
    this.playlistImageUrl,
    required this.timestamp,
    required this.playlistUserIndex,
    this.songListIds,
    this.playlistLikeIds,
    required this.totalDuration,
  });

  // Convert Playlist to a Map to store in SQLite
  Map<String, dynamic> toMap() {
    return {
      'playlistId': playlistId,
      'creatorId': creatorId,
      'playlistName': playlistName,
      'playlistDescription': playlistDescription,
      'playlistImageUrl': playlistImageUrl,
      'timestamp': timestamp.toIso8601String(), // Store DateTime as ISO string
      'playlistUserIndex': playlistUserIndex,
      'songListIds':
          songListIds?.join(','), // Convert List to comma-separated String
      'playlistLikeIds': playlistLikeIds?.join(','),
      'totalDuration': totalDuration.inSeconds, // Store Duration as seconds
    };
  }

  // Create an Playlist object from a Map retrieved from SQLite
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      playlistId: map['playlistId'],
      creatorId: map['creatorId'],
      playlistName: map['playlistName'],
      playlistDescription: map['playlistDescription'],
      playlistImageUrl: map['playlistImageUrl'],
      timestamp: DateTime.parse(map['timestamp']), // Parse string to DateTime
      playlistUserIndex: map['playlistUserIndex'],
      songListIds: map['songListIds'] != null
          ? (map['songListIds'] as String).split(',')
          : [],
      playlistLikeIds: map['playlistLikeIds'] != null
          ? (map['playlistLikeIds'] as String).split(',')
          : [],
      totalDuration: map['totalDuration'] != null
          ? Duration(seconds: map['totalDuration'])
          : Duration.zero,
    );
  }

  // Convert Playlist object to JSON
  String toJson() => json.encode(toMap());

  // Create an Playlist object from JSON
  factory Playlist.fromJson(String source) =>
      Playlist.fromMap(json.decode(source) as Map<String, dynamic>);

  // Create an empty Playlist object
  factory Playlist.empty() {
    return Playlist(
      playlistId: '', // Empty string for playlistId
      creatorId: '', // Empty string for creatorId
      playlistName: '', // Empty string for playlistName
      playlistDescription: null, // Null for optional description
      playlistImageUrl: null, // Null for optional image URL
      timestamp: DateTime.now(), // Current timestamp
      playlistUserIndex: 0, // Default value
      songListIds: [], // Empty list for songListIds
      playlistLikeIds: [], // Empty list for playlistLikeIds
      totalDuration: Duration.zero, // Zero duration for totalDuration
    );
  }
}
