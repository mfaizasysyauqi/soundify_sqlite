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
  String premiumExpiryDate;
  int royalty;

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
    this.premiumExpiryDate = '',
    this.royalty = 0,
  });

  User copyWith({
    String? userId,
    String? fullName,
    String? username,
    String? email,
    String? password,
    String? profileImageUrl,
    String? bioImageUrl,
    String? bio,
    String? role,
    List<String>? followers,
    List<String>? following,
    List<String>? userLikedSongs,
    List<String>? userLikedAlbums,
    List<String>? userLikedPlaylists,
    String? lastListenedSongId,
    double? lastVolumeLevel,
    String? premiumExpiryDate,
    int? royalty,
  }) {
    return User(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bioImageUrl: bioImageUrl ?? this.bioImageUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      userLikedSongs: userLikedSongs ?? this.userLikedSongs,
      userLikedAlbums: userLikedAlbums ?? this.userLikedAlbums,
      userLikedPlaylists: userLikedPlaylists ?? this.userLikedPlaylists,
      lastListenedSongId: lastListenedSongId ?? this.lastListenedSongId,
      lastVolumeLevel: lastVolumeLevel ?? this.lastVolumeLevel,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      royalty: royalty ?? this.royalty,
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
      premiumExpiryDate: map['premium'] ?? 'premiumExpiryDate',
      royalty: map['royalty'] ?? 0,
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
      'premiumExpiryDate': premiumExpiryDate,
      'royalty': royalty,
    };
  }
}
