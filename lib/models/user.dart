class User {
  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String password;
  final String profileImageUrl;
  final String bioImageUrl;
  final String bio;
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
  }) {
    return User(
      userId: userId,
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      profileImageUrl: profileImageUrl,
      bioImageUrl: bioImageUrl,
      bio: bio,
      role: role,
      followers: followers,
      following: following,
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
      role: map['role'] ?? '',
      followers: _parseStringList(map['followers']),
      following: _parseStringList(map['following']),
      userLikedSongs: _parseStringList(map['userLikedSongs']),
      userLikedAlbums: _parseStringList(map['userLikedAlbums']),
      userLikedPlaylists: _parseStringList(map['userLikedPlaylists']),
      lastListenedSongId: map['lastListenedSongId'] ?? '',
      lastVolumeLevel: map['lastVolumeLevel'] ?? 0.5,
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
