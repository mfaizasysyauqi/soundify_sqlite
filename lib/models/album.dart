// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Album {
  final String albumId;
  final String creatorId;
  late final String albumName;
  late final String albumDescription;
  late final String albumImageUrl;
  final DateTime timestamp; // Use DateTime for timestamp
  final int albumUserIndex;
  late final List<String> songListIds;
  final List<String> albumLikeIds;
  late final Duration totalDuration;

  String? creatorName;

  Album({
    required this.albumId,
    required this.creatorId,
    required this.albumName,
    this.albumDescription = '', // Default empty string for nullable description
    this.albumImageUrl = '', // Default empty string for nullable image URL
    required this.timestamp,
    required this.albumUserIndex,
    required this.songListIds,
    required this.albumLikeIds,
    required this.totalDuration,
  });

  // Convert Album to a Map to store in SQLite
  Map<String, dynamic> toMap() {
    return {
      'albumId': albumId,
      'creatorId': creatorId,
      'albumName': albumName,
      'albumDescription': albumDescription,
      'albumImageUrl': albumImageUrl,
      'timestamp': timestamp.toIso8601String(), // Store DateTime as ISO string
      'albumUserIndex': albumUserIndex,
      'songListIds':
          songListIds.join(','), // Convert List to comma-separated String
      'albumLikeIds': albumLikeIds.join(','),
      'totalDuration': totalDuration.inSeconds, // Store Duration as seconds
    };
  }

  // Create an Album object from a Map retrieved from SQLite
  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      albumId: map['albumId'],
      creatorId: map['creatorId'],
      albumName: map['albumName'],
      albumDescription: map['albumDescription'],
      albumImageUrl: map['albumImageUrl'],
      timestamp: DateTime.parse(map['timestamp']), // Parse string to DateTime
      albumUserIndex: map['albumUserIndex'],
      songListIds: map['songListIds'] != null
          ? (map['songListIds'] as String).split(',')
          : [],
      albumLikeIds: map['albumLikeIds'] != null
          ? (map['albumLikeIds'] as String).split(',')
          : [],
      totalDuration: map['totalDuration'] != null
          ? Duration(seconds: map['totalDuration'])
          : Duration.zero,
    );
  }

  // Convert Album object to JSON
  String toJson() => json.encode(toMap());

  // Create an Album object from JSON
  factory Album.fromJson(String source) =>
      Album.fromMap(json.decode(source) as Map<String, dynamic>);

  // Create an empty Album object
  factory Album.empty() {
    return Album(
      albumId: '', // Empty string for albumId
      creatorId: '', // Empty string for creatorId
      albumName: '', // Empty string for albumName
      albumDescription: '', // Null for optional description
      albumImageUrl: '', // Null for optional image URL
      timestamp: DateTime.now(), // Current timestamp
      albumUserIndex: 0, // Default value
      songListIds: [], // Empty list for songListIds
      albumLikeIds: [], // Empty list for albumLikeIds
      totalDuration: Duration.zero, // Zero duration for totalDuration
    );
  }
}
