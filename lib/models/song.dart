// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Song {
  late String songId;
  final String senderId;
  late final String artistId;
  late final String albumId;
  late final String songTitle;
  late final String songImageUrl;
  late final String songUrl;
  late final Duration songDuration;
  final DateTime timestamp; // Use DateTime for timestamp
  late final int artistSongIndex;
  late List<String>? likeIds;
  late List<String>? playlistIds;
  late List<String>? albumIds;
  late List<String>? playedIds;

  String? artistName;
  String? albumName;
  String? profileImageUrl;
  String? bioImageUrl;

  Song({
    required this.songId,
    required this.senderId,
    required this.artistId,
    required this.albumId,
    required this.songTitle,
    required this.songImageUrl,
    required this.songUrl,
    required this.songDuration,
    required this.timestamp, // Use DateTime here
    required this.artistSongIndex,
    this.likeIds,
    this.playlistIds,
    this.albumIds,
    this.playedIds,
  });

  // Convert Song to a Map to store in SQLite
  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'senderId': senderId,
      'artistId': artistId,
      'albumId': albumId,
      'songTitle': songTitle,
      'songImageUrl': songImageUrl,
      'songUrl': songUrl,
      'songDuration': songDuration.inSeconds, // Store duration as seconds
      'timestamp': timestamp.toIso8601String(), // Store DateTime as ISO string
      'artistSongIndex': artistSongIndex,
      'likeIds': likeIds?.join(','), // Convert List to comma-separated String
      'playlistIds': playlistIds?.join(','),
      'albumIds': albumIds?.join(','),
      'playedIds': playedIds?.join(','),
    };
  }

  // Create a Song object from a Map retrieved from SQLite
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      songId: map['songId'],
      senderId: map['senderId'],
      artistId: map['artistId'],
      albumId: map['albumId'],
      songTitle: map['songTitle'],
      songImageUrl: map['songImageUrl'],
      songUrl: map['songUrl'],
      songDuration: Duration(seconds: map['songDuration']),
      timestamp: DateTime.parse(map['timestamp']), // Parse string to DateTime
      artistSongIndex: map['artistSongIndex'],
      likeIds:
          map['likeIds'] != null ? (map['likeIds'] as String).split(',') : [],
      playlistIds: map['playlistIds'] != null
          ? (map['playlistIds'] as String).split(',')
          : [],
      albumIds:
          map['albumIds'] != null ? (map['albumIds'] as String).split(',') : [],
      playedIds: map['playedIds'] != null
          ? (map['playedIds'] as String).split(',')
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Song.fromJson(String source) =>
      Song.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Song.empty() {
    return Song(
      songId: '', // Empty string for the songId
      senderId: '', // Empty string for the senderId
      artistId: '', // Empty string for the artistId
      albumId: '', // Null for optional albumId
      songTitle: '', // Empty string for the songTitle
      songImageUrl: '', // Empty string for the songImageUrl
      songUrl: '', // Empty string for the songUrl
      songDuration: Duration.zero, // Zero duration for the song
      timestamp: DateTime.now(), // Current timestamp
      artistSongIndex: 0, // Default to 0 for artistSongIndex
      likeIds: [], // Empty list for likeIds
      playlistIds: [], // Empty list for playlistIds
      albumIds: [], // Empty list for albumIds
      playedIds: [], // Empty list for playedIds
    );
  }
}
