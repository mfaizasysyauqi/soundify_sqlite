class User {
  final String userId;
  late final String fullName;
  late final String username;
  final String email;
  final String password;
  late final String profileImageUrl;
  late final String bioImageUrl;
  late final String bio;
  final String role;
  final List<String> followers;
  final List<String> following;
  final List<String> userLikedSongs;
  final List<String> userLikedAlbums;
  final List<String> userLikedPlaylists;
  String lastListenedSongId;
  double lastVolumeLevel;

  User({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.profileImageUrl,
    required this.bioImageUrl,
    required this.bio,
    required this.role,
    required this.followers,
    required this.following,
    required this.userLikedSongs,
    required this.userLikedAlbums,
    required this.userLikedPlaylists,
    this.lastListenedSongId = '',
    this.lastVolumeLevel = 0.5,
  });

  User copyWith({
    String? lastListenedSongId,
    double? lastVolumeLevel,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? bioImageUrl,
    String? bio,
    List<String>? followers,
    List<String>? following,
  }) {
    return User(
      userId: userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email,
      password: password,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bioImageUrl: bioImageUrl ?? this.bioImageUrl,
      bio: bio ?? this.bio,
      role: role,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      userLikedSongs: userLikedSongs,
      userLikedAlbums: userLikedAlbums,
      userLikedPlaylists: userLikedPlaylists,
      lastListenedSongId: lastListenedSongId ?? this.lastListenedSongId,
      lastVolumeLevel: lastVolumeLevel ?? this.lastVolumeLevel,
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      bioImageUrl: map['bioImageUrl'] ?? '',
      bio: map['bio'] ?? '',
      role: map['role'] ?? 'user',
      followers: (map['followers'] ?? '')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      following: (map['following'] ?? '')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      userLikedSongs: (map['userLikedSongs'] ?? '')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      userLikedAlbums: (map['userLikedAlbums'] ?? '')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      userLikedPlaylists: (map['userLikedPlaylists'] ?? '')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      lastListenedSongId: map['lastListenedSongId'] ?? '',
      lastVolumeLevel: (map['lastVolumeLevel'] ?? 0.5) as double,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String) {
      return value.isNotEmpty ? value.split(',') : [];
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'profileImageUrl': profileImageUrl,
      'bioImageUrl': bioImageUrl,
      'bio': bio,
      'role': role,
      'followers': followers.join(','),
      'following': following.join(','),
      'userLikedSongs': userLikedSongs.join(','),
      'userLikedAlbums': userLikedAlbums.join(','),
      'userLikedPlaylists': userLikedPlaylists.join(','),
      'lastListenedSongId': lastListenedSongId,
      'lastVolumeLevel': lastVolumeLevel,
    };
  }
}
