import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/view/style/style.dart';
import 'package:audioplayers/audioplayers.dart';

class BottomContainer extends StatefulWidget {
  const BottomContainer({super.key});

  @override
  State<BottomContainer> createState() => _BottomContainerState();
}

class _BottomContainerState extends State<BottomContainer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentPosition = 0.0;
  double _currentVolume = 0.5;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  String _currentSongUrl = '';
  List<Song> _originalPlaylist = [];
  List<Song> _shuffledPlaylist = [];
  bool _isHoveredSkipPrevious = false;
  bool _isHoveredSkipNext = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadUserPreferences();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final dbHelper = DatabaseHelper.instance;
    _originalPlaylist = await dbHelper.getSongs();
    _shuffledPlaylist = List.from(_originalPlaylist);
  }

  void _initializeAudioPlayer() {
    _loadUserPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final songProvider = Provider.of<SongProvider>(context, listen: false);
      _setupSongProviderListener(songProvider);
    });
    _setupAudioPlayerListeners();
  }

  void _setupSongProviderListener(SongProvider songProvider) {
    songProvider.addListener(() {
      if (songProvider.songUrl.isNotEmpty &&
          songProvider.songUrl != _currentSongUrl) {
        _handleSongChange(songProvider.songUrl, songProvider.shouldPlay);
        songProvider.saveLastListenedSongToSQLite();
      }
    });
  }

  Future<void> _setupAudioPlayerListeners() async {
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position.inSeconds.toDouble());
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (mounted) {
        setState(() => _isPlaying = playerState == PlayerState.playing);
      }
    });

    // Add listener for song completion
    _audioPlayer.onPlayerComplete.listen((_) {
      _onSongComplete();
    });
  }

  Future<void> _handleSongChange(String newSongUrl, bool shouldPlay) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    }

    _currentSongUrl = newSongUrl;
    String fixedPath = newSongUrl.replaceAll(r'\', '/');

    await _audioPlayer.setSource(DeviceFileSource(fixedPath));

    // Set ReleaseMode based on repeat mode
    await _audioPlayer
        .setReleaseMode(_isRepeatMode ? ReleaseMode.loop : ReleaseMode.release);

    setState(() {
      _currentPosition = 0.0;
    });

    if (shouldPlay) {
      await _audioPlayer.resume();
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume(); // Use resume instead of play
      }
    } catch (e) {
      print("Error toggling play/pause: $e");
    }
  }

  // Fungsi untuk memutar lagu
  Future<void> _playSong(String songUrl) async {
    try {
      await _audioPlayer.setSourceUrl(songUrl);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();

      if (!mounted) return;
      setState(() {
        _currentPosition = 0.0;
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  Future<void> _loadUserPreferences() async {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    Map<String, dynamic> prefs = await songProvider.loadUserPreferences();

    if (prefs.containsKey('lastVolumeLevel')) {
      var lastVolumeLevel = prefs['lastVolumeLevel'];

      setState(() async {
        if (lastVolumeLevel is double) {
          _currentVolume = lastVolumeLevel;
        } else if (lastVolumeLevel is int) {
          _currentVolume = lastVolumeLevel.toDouble();
        }
        await _audioPlayer.setVolume(_currentVolume);
      });
    }
  }

  Future<void> _toggleMute() async {
    try {
      if (_isMuted) {
        await _audioPlayer.setVolume(_currentVolume);
      } else {
        await _audioPlayer.setVolume(0);
      }

      if (!mounted) return;
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      print("Error toggling mute: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _buildSongInfo(constraints, songProvider),
            Expanded(child: _buildPlayerControls(constraints)),
            _buildVolumeControls(constraints),
          ],
        );
      },
    );
  }

  Widget _buildSongInfo(BoxConstraints constraints, SongProvider songProvider) {
    return Container(
      width: constraints.maxWidth * 0.3,
      height: 50,
      color: quaternaryColor,
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildSongImage(songProvider),
          const SizedBox(width: 10),
          Expanded(child: _buildSongDetails(songProvider)),
        ],
      ),
    );
  }

  Widget _buildSongImage(SongProvider songProvider) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: songProvider.songImageUrl.isNotEmpty
            ? (Uri.tryParse(songProvider.songImageUrl)?.isAbsolute ?? false
                ? Image.file(
                    File(songProvider.songImageUrl), // Load local file image
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildErrorImage(),
                  )
                : _buildErrorImage()) // Handle cases where the path is not valid
            : const SizedBox.shrink(), // Empty space if the URL is not provided
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey,
      child: const Icon(Icons.broken_image, color: Colors.white),
    );
  }

  Widget _buildSongDetails(SongProvider songProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          songProvider.songTitle,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: primaryTextColor, fontSize: smallFontSize),
        ),
        Text(
          songProvider.artistName ?? '',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: quaternaryTextColor, fontSize: microFontSize),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(BoxConstraints constraints) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShuffleButton(),
            const SizedBox(
              width: 24,
            ),
            _buildSkipPreviousButton(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildPlayPauseButton(),
            ),
            _buildSkipNextButton(),
            const SizedBox(
              width: 24,
            ),
            _buildRepeatButton(),
          ],
        ),
        const SizedBox(height: 6),
        _buildProgressBar(constraints),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: primaryTextColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: primaryColor,
          size: 28,
        ),
      ),
    );
  }

  void _toggleShuffleMode() async {
    setState(() {
      _isShuffleMode = !_isShuffleMode;
      if (_isShuffleMode) {
        // Get the current song
        int currentSongIndex = _originalPlaylist
            .indexWhere((song) => song.songUrl == _currentSongUrl);

        // Create a temporary list without the current song
        var tempList = List<Song>.from(_originalPlaylist);
        if (currentSongIndex != -1) {
          var currentSong = tempList.removeAt(currentSongIndex);

          // Shuffle the remaining songs
          tempList.shuffle(Random());

          // Put the current song back at the beginning
          _shuffledPlaylist = [currentSong, ...tempList];
        } else {
          _shuffledPlaylist = List.from(_originalPlaylist)..shuffle(Random());
        }
      } else {
        // Restore original order
        _shuffledPlaylist = List.from(_originalPlaylist);
      }
    });
  }

  void _toggleRepeatMode() async {
    setState(() {
      _isRepeatMode = !_isRepeatMode;
    });

    // Update audio player's release mode
    await _audioPlayer
        .setReleaseMode(_isRepeatMode ? ReleaseMode.loop : ReleaseMode.release);
  }

  Future<void> _onSongComplete() async {
    if (!_isRepeatMode) {
      await _skipToNextSong();
    }
  }

  Future<void> _skipToNextSong() async {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final dbHelper = DatabaseHelper.instance;

    // Use shuffled playlist if shuffle mode is on, otherwise use original playlist
    List<Song> currentPlaylist =
        _isShuffleMode ? _shuffledPlaylist : await dbHelper.getSongs();

    // Get current song index
    int currentIndex =
        currentPlaylist.indexWhere((song) => song.songUrl == _currentSongUrl);
    // Calculate next index
    int nextIndex = currentIndex + 1;
    if (nextIndex >= currentPlaylist.length) {
      nextIndex = 0; // Loop back to the first song
    }

    if (currentPlaylist.isNotEmpty && nextIndex < currentPlaylist.length) {
      Song nextSong = currentPlaylist[nextIndex];

      // Update the song provider with new song details
      songProvider.setSong(
        nextSong.songId,
        nextSong.senderId,
        nextSong.artistId,
        nextSong.songTitle,
        nextSong.profileImageUrl,
        nextSong.songImageUrl,
        nextSong.bioImageUrl,
        nextSong.artistName,
        nextSong.songUrl,
        nextSong.songDuration,
        nextIndex,
      );

      // Save last listened song to current user
      User? currentUser = await dbHelper.getCurrentUser();
      if (currentUser != null) {
        currentUser.lastListenedSongId = nextSong.songId;
        await dbHelper.updateUser(currentUser);
      }
    }
  }

  Future<void> _skipToPreviousSong() async {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final dbHelper = DatabaseHelper.instance;

    // Use shuffled playlist if shuffle mode is on, otherwise use original playlist
    List<Song> currentPlaylist =
        _isShuffleMode ? _shuffledPlaylist : await dbHelper.getSongs();

    // Get current song index
    int currentIndex =
        currentPlaylist.indexWhere((song) => song.songUrl == _currentSongUrl);

    // Get current song index
    List<Song> songs = await dbHelper.getSongs();

    // Calculate previous index
    int previousIndex = currentIndex - 1;
    if (previousIndex < 0) {
      previousIndex = songs.length - 1; // Loop to last song
    }

    if (songs.isNotEmpty && previousIndex < songs.length) {
      Song previousSong = songs[previousIndex];

      // Update the song provider with new song details
      songProvider.setSong(
        previousSong.songId,
        previousSong.senderId,
        previousSong.artistId,
        previousSong.songTitle,
        previousSong.profileImageUrl,
        previousSong.songImageUrl,
        previousSong.bioImageUrl,
        previousSong.artistName,
        previousSong.songUrl,
        previousSong.songDuration,
        previousIndex,
      );

      // Save last listened song to current user
      User? currentUser = await dbHelper.getCurrentUser();
      if (currentUser != null) {
        currentUser.lastListenedSongId = previousSong.songId;
        await dbHelper.updateUser(currentUser);
      }
    }
  }

  Widget _buildSkipPreviousButton() {
    return MouseRegion(
      onEnter: (event) => setState(() {
        _isHoveredSkipPrevious = true;
      }),
      onExit: (event) => setState(() {
        _isHoveredSkipPrevious = false;
      }),
      child: GestureDetector(
        onTap: _skipToPreviousSong,
        child: Icon(
          Icons.skip_previous,
          color: _isHoveredSkipPrevious ? secondaryColor : quaternaryTextColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSkipNextButton() {
    return MouseRegion(
      onEnter: (event) => setState(() {
        _isHoveredSkipNext = true;
      }),
      onExit: (event) => setState(() {
        _isHoveredSkipNext = false;
      }),
      child: GestureDetector(
        onTap: _skipToNextSong,
        child: Icon(
          Icons.skip_next,
          color: _isHoveredSkipNext ? secondaryColor : quaternaryTextColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildShuffleButton() {
    return GestureDetector(
      onTap: _toggleShuffleMode,
      child: Icon(
        Icons.shuffle,
        color: _isShuffleMode ? secondaryColor : quaternaryTextColor,
        size: 24,
      ),
    );
  }

  Widget _buildRepeatButton() {
    return GestureDetector(
      onTap: _toggleRepeatMode,
      child: Icon(
        Icons.repeat,
        color: _isRepeatMode ? secondaryColor : quaternaryTextColor,
        size: 24,
      ),
    );
  }

  Widget _buildProgressBar(BoxConstraints constraints) {
    final songProvider = Provider.of<SongProvider>(context);
    return Row(
      children: [
        SizedBox(width: constraints.maxWidth * 0.01),
        Text(
          _formatDuration(Duration(seconds: _currentPosition.toInt())),
          style: const TextStyle(
              color: quaternaryTextColor, fontSize: microFontSize),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.7,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: primaryTextColor,
              inactiveTrackColor: tertiaryColor,
            ),
            child: Slider(
              value: _currentPosition,
              min: 0,
              max: songProvider.songDuration.inSeconds.toDouble(),
              onChanged: (value) async {
                if (mounted) {
                  setState(() => _currentPosition = value);
                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _formatDuration(songProvider.songDuration),
          style: const TextStyle(
              color: quaternaryTextColor, fontSize: microFontSize),
        ),
        SizedBox(width: constraints.maxWidth * 0.01),
      ],
    );
  }

  Widget _buildVolumeControls(BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth * 0.3,
      height: 50,
      color: quaternaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _toggleMute,
            child: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: primaryTextColor,
              size: mediumFontSize,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: constraints.maxWidth *
                0.12, // Adjust this value to change the slider width
            child: _buildVolumeSlider(),
          ),
          const SizedBox(width: 8),
          Text(
            "${(_isMuted ? 0 : (_currentVolume * 100).toInt())}%",
            style: const TextStyle(
                color: primaryTextColor, fontSize: microFontSize),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2, // Make the track thinner
        thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 6), // Make the thumb smaller
        overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 12), // Make the overlay smaller
        activeTrackColor: primaryTextColor,
        inactiveTrackColor: tertiaryColor,
      ),
      child: Slider(
        value: _isMuted ? 0 : _currentVolume,
        min: 0,
        max: 1,
        label: "${(_currentVolume * 100).toInt()}%",
        onChanged: _handleVolumeChange,
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.3),
      ),
    );
  }

  void _handleVolumeChange(double value) async {
    if (mounted) {
      setState(() async {
        _currentVolume = value;
        await _audioPlayer.setVolume(value);
        if (_isMuted) _toggleMute();
      });

      try {
        await Provider.of<SongProvider>(context, listen: false)
            .saveVolumeToSQLiteAndJson(_currentVolume);
        // print("Volume saved successfully: $_currentVolume");
      } catch (e) {
        print("Error saving volume: $e");
      }
    }
  }

  // Update the _formatDuration method to accept a Duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    super.dispose();
  }
}
