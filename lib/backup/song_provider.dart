// // song_provider.dart
// import 'package:flutter/material.dart';
// import 'package:soundify/database/database_helper.dart';
// import 'package:soundify/database/file_storage_helper.dart';
// import 'package:soundify/models/song.dart';
// import 'package:soundify/models/user.dart';
// import 'package:audioplayers/audioplayers.dart';

// class SongProvider with ChangeNotifier {
//   final AudioPlayer audioPlayer = AudioPlayer();
//   final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
//   // final FileStorageHelper _fileStorageHelper = FileStorageHelper.instance;

//   // Make the instance static and singleton
//   static final SongProvider _instance = SongProvider._internal();
//   factory SongProvider() => _instance;

//   String _songId = '';
//   String _senderId = '';
//   String _artistId = '';
//   String _songTitle = '';
//   String? _profileImageUrl = '';
//   String _songImageUrl = '';
//   String? _bioImageUrl = '';
//   String? _artistName = '';
//   String _songUrl = '';
//   Duration _songDuration = Duration.zero;
//   Duration _currentPosition = Duration.zero;
//   double _currentVolume = 0.5;
//   bool _isPlaying = false;
//   bool _isMuted = false;
//   bool _isShuffleMode = false;
//   bool _isRepeatMode = false;
//   bool _shouldPlay = false;

//   List<Song> _originalPlaylist = [];
//   List<Song> _shuffledPlaylist = [];
//   int _currentIndex = 0;

//   String userBio = '';

//   // Getters
//   String get songId => _songId;
//   String get senderId => _senderId;
//   String get artistId => _artistId;
//   String get songTitle => _songTitle;
//   String? get profileImageUrl => _profileImageUrl;
//   String get songImageUrl => _songImageUrl;
//   String? get bioImageUrl => _bioImageUrl;
//   String? get artistName => _artistName;
//   String get songUrl => _songUrl;
//   Duration get songDuration => _songDuration;
//   Duration get currentPosition => _currentPosition;
//   double get currentVolume => _currentVolume;
//   bool get isPlaying => _isPlaying;
//   bool get isMuted => _isMuted;
//   bool get isShuffleMode => _isShuffleMode;
//   bool get isRepeatMode => _isRepeatMode;
//   bool get shouldPlay => _shouldPlay;

//   SongProvider._internal() {
//     _initializeAudioPlayer();
//     _loadUserPreferences();
//     _loadPlaylist();
//   }

//   void _initializeAudioPlayer() {
//     _setupAudioPlayerListeners();
//   }

//   Future<void> _setupAudioPlayerListeners() async {
//     audioPlayer.onPositionChanged.listen((position) {
//       _currentPosition = position; // Now this matches types correctly
//       notifyListeners();
//     });

//     audioPlayer.onPlayerStateChanged.listen((playerState) {
//       _isPlaying = playerState == PlayerState.playing;
//       notifyListeners();
//     });

//     audioPlayer.onPlayerComplete.listen((_) {
//       _onSongComplete();
//     });
//   }

//   Future<void> _loadPlaylist() async {
//     _originalPlaylist = await _databaseHelper.getSongs();
//     _shuffledPlaylist = List.from(_originalPlaylist);
//   }

//   // Add error handling for audio source setting in SongProvider
//   Future<void> setSong(
//     String songId,
//     String senderId,
//     String artistId,
//     String title,
//     String? profileImageUrl,
//     String songImageUrl,
//     String? bioImageUrl,
//     String? artistName,
//     String songUrl,
//     Duration songDuration,
//     int songIndex,
//   ) async {
//     try {
//       if (_songId != songId) {
//         await stop();
//         _songId = songId;
//         _senderId = senderId;
//         _artistId = artistId;
//         _songTitle = title;
//         _profileImageUrl = profileImageUrl;
//         _songImageUrl = songImageUrl;
//         _bioImageUrl = bioImageUrl;
//         _artistName = artistName;
//         _songUrl = songUrl;
//         _songDuration = songDuration;
//         _currentIndex = songIndex;

//         if (songUrl.isNotEmpty) {
//           String fixedPath = songUrl.replaceAll(r'\', '/');
//           try {
//             await audioPlayer.setSource(DeviceFileSource(fixedPath));
//             await audioPlayer.setReleaseMode(
//                 _isRepeatMode ? ReleaseMode.loop : ReleaseMode.release);

//             // Save last listened song
//             await _saveLastListenedSong(songId);
//           } catch (e) {
//             print('Error setting audio source: $e');
//             return;
//           }

//           if (_shouldPlay) {
//             await resume();
//           }
//         }

//         await fetchUserBio();
//         notifyListeners();
//       }
//     } catch (e) {
//       print('Error in setSong: $e');
//     }
//   }

//   Future<void> togglePlayPause() async {
//     if (_isPlaying) {
//       await pause();
//     } else {
//       await resume();
//     }
//   }

//   Future<void> pause() async {
//     await audioPlayer.pause();
//     _isPlaying = false;
//     notifyListeners();
//   }

//   Future<void> resume() async {
//     await audioPlayer.resume();
//     _isPlaying = true;
//     notifyListeners();
//   }

//   Future<void> stop() async {
//     await audioPlayer.stop();
//     _isPlaying = false;
//     notifyListeners();
//   }

//   Future<void> seek(Duration position) async {
//     await audioPlayer.seek(position);
//     _currentPosition = position;
//     notifyListeners();
//   }

//   // Update the setter to handle Duration
//   set currentPosition(Duration position) {
//     _currentPosition = position;
//     notifyListeners();
//   }

//   void setArtistId(String newArtistId) {
//     _artistId = newArtistId;
//     notifyListeners();
//   }

//   void resetArtistId() {
//     _artistId = '';
//     notifyListeners();
//   }

//   void setShouldPlay(bool value) {
//     _shouldPlay = value;
//     notifyListeners();
//   }

//   // Fetch user bio from SQLite
//   Future<void> fetchUserBio() async {
//     if (userBio.isEmpty) {
//       try {
//         User? user = await _databaseHelper.getUserById(_artistId);
//         if (user != null) {
//           userBio = user.bio;
//           notifyListeners();
//         }
//       } catch (e) {
//         print("Error fetching user bio: $e");
//       }
//     }
//   }

//   void playSong() {
//     if (!_isPlaying) {
//       _isPlaying = true;
//       // Add your audio player logic here
//       notifyListeners();
//     }
//   }

//   void stopCurrentSong() {
//     // Stop the current song (e.g., stop the audio player)
//   }

//   void pauseOrResume() {
//     _isPlaying ? pause() : resume();
//   }

//   Future<void> setVolume(double volume) async {
//     try {
//       await audioPlayer.setVolume(volume);
//       _currentVolume = volume;
//       if (_isMuted && volume > 0) {
//         _isMuted = false;
//       }

//       // Save volume to both SQLite and JSON
//       await _saveVolumePreference(volume);

//       notifyListeners();
//     } catch (e) {
//       print('Error setting volume: $e');
//     }
//   }

//   Future<void> toggleMute() async {
//     if (_isMuted) {
//       await audioPlayer.setVolume(_currentVolume);
//     } else {
//       await audioPlayer.setVolume(0);
//     }
//     _isMuted = !_isMuted;
//     notifyListeners();
//   }

//   void toggleShuffleMode() {
//     _isShuffleMode = !_isShuffleMode;
//     if (_isShuffleMode) {
//       int currentSongIndex =
//           _originalPlaylist.indexWhere((song) => song.songUrl == _songUrl);
//       var tempList = List<Song>.from(_originalPlaylist);

//       if (currentSongIndex != -1) {
//         var currentSong = tempList.removeAt(currentSongIndex);
//         tempList.shuffle();
//         _shuffledPlaylist = [currentSong, ...tempList];
//       } else {
//         _shuffledPlaylist = List.from(_originalPlaylist)..shuffle();
//       }
//     } else {
//       _shuffledPlaylist = List.from(_originalPlaylist);
//     }
//     notifyListeners();
//   }

//   Future<void> toggleRepeatMode() async {
//     _isRepeatMode = !_isRepeatMode;
//     await audioPlayer
//         .setReleaseMode(_isRepeatMode ? ReleaseMode.loop : ReleaseMode.release);
//     notifyListeners();
//   }

//   Future<void> _onSongComplete() async {
//     if (!_isRepeatMode) {
//       await skipToNextSong();
//     }
//   }

//   Future<void> skipToNextSong() async {
//     List<Song> currentPlaylist =
//         _isShuffleMode ? _shuffledPlaylist : _originalPlaylist;

//     int nextIndex = _currentIndex + 1;
//     if (nextIndex >= currentPlaylist.length) {
//       nextIndex = 0;
//     }

//     if (currentPlaylist.isNotEmpty) {
//       // Set shouldPlay to true before setting the song
//       setShouldPlay(true);

//       Song nextSong = currentPlaylist[nextIndex];
//       await setSong(
//         nextSong.songId,
//         nextSong.senderId,
//         nextSong.artistId,
//         nextSong.songTitle,
//         nextSong.profileImageUrl,
//         nextSong.songImageUrl,
//         nextSong.bioImageUrl,
//         nextSong.artistName,
//         nextSong.songUrl,
//         nextSong.songDuration,
//         nextIndex,
//       );

//       // Ensure the song starts playing
//       await resume();

//       await saveLastListenedSongToSQLite();
//     }
//   }

//   Future<void> skipToPreviousSong() async {
//     List<Song> currentPlaylist =
//         _isShuffleMode ? _shuffledPlaylist : _originalPlaylist;

//     int previousIndex = _currentIndex - 1;
//     if (previousIndex < 0) {
//       previousIndex = currentPlaylist.length - 1;
//     }

//     if (currentPlaylist.isNotEmpty) {
//       // Set shouldPlay to true before setting the song
//       setShouldPlay(true);

//       Song previousSong = currentPlaylist[previousIndex];
//       await setSong(
//         previousSong.songId,
//         previousSong.senderId,
//         previousSong.artistId,
//         previousSong.songTitle,
//         previousSong.profileImageUrl,
//         previousSong.songImageUrl,
//         previousSong.bioImageUrl,
//         previousSong.artistName,
//         previousSong.songUrl,
//         previousSong.songDuration,
//         previousIndex,
//       );

//       // Ensure the song starts playing
//       await resume();

//       await saveLastListenedSongToSQLite();
//     }
//   }

//   Future<void> saveVolumeToSQLiteAndJson(double volume) async {
//     try {
//       // Update SQLite
//       User? currentUser = await _databaseHelper.getCurrentUser();
//       if (currentUser != null) {
//         User updatedUser = currentUser.copyWith(lastVolumeLevel: volume);

//         await _databaseHelper.updateUser(updatedUser);

//         // Update JSON file
//         await FileStorageHelper.instance.updateJsonWithLatestUser();
//       }
//     } catch (e) {
//       print("Error saving volume to SQLite or JSON: $e");
//     }
//   }

//   // Save last listened song to SQLite
//   Future<void> saveLastListenedSongToSQLite() async {
//     try {
//       User? currentUser = await _databaseHelper.getCurrentUser();
//       if (currentUser != null) {
//         User updatedUser = currentUser.copyWith(lastListenedSongId: _songId);
//         await _databaseHelper.updateUser(updatedUser);
//       }
//     } catch (e) {
//       print("Error saving last listened song to SQLite: $e");
//     }
//   }

//   // Load user preferences from SQLite
//   Future<void> _loadUserPreferences() async {
//     try {
//       User? currentUser = await _databaseHelper.getCurrentUser();
//       if (currentUser != null) {
//         // Set volume from saved preferences
//         double savedVolume = currentUser.lastVolumeLevel;
//         await setVolume(savedVolume);

//         // Load last played song if it exists
//         Song? lastSong =
//             await _databaseHelper.getSongById(currentUser.lastListenedSongId);
//         if (lastSong != null) {
//           await setSong(
//             lastSong.songId,
//             lastSong.senderId,
//             lastSong.artistId,
//             lastSong.songTitle,
//             lastSong.profileImageUrl,
//             lastSong.songImageUrl,
//             lastSong.bioImageUrl,
//             lastSong.artistName,
//             lastSong.songUrl,
//             lastSong.songDuration,
//             _currentIndex,
//           );
//         }
//       }
//     } catch (e) {
//       print('Error loading user preferences: $e');
//     }
//   }

//   Future<void> _saveVolumePreference(double volume) async {
//     try {
//       User? currentUser = await _databaseHelper.getCurrentUser();
//       if (currentUser != null) {
//         // Update user with new volume
//         User updatedUser = currentUser.copyWith(lastVolumeLevel: volume);

//         // Save to SQLite
//         await _databaseHelper.updateUser(updatedUser);

//         // Save to JSON
//         // await _fileStorageHelper.saveUserToJson(updatedUser);
//       }
//     } catch (e) {
//       print('Error saving volume preference: $e');
//     }
//   }

//   Future<void> _saveLastListenedSong(String songId) async {
//     try {
//       User? currentUser = await _databaseHelper.getCurrentUser();
//       if (currentUser != null) {
//         // Update user with new last listened song
//         User updatedUser = currentUser.copyWith(lastListenedSongId: songId);

//         // Save to SQLite
//         await _databaseHelper.updateUser(updatedUser);

//         // Save to JSON
//         // await _fileStorageHelper.saveUserToJson(updatedUser);
//       }
//     } catch (e) {
//       print('Error saving last listened song: $e');
//     }
//   }

//   @override
//   void dispose() {
//     audioPlayer.dispose();
//     super.dispose();
//   }
// }
