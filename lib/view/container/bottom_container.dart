import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/view/style/style.dart';
import 'package:audioplayers/audioplayers.dart';

class BottomContainer extends StatefulWidget {
  const BottomContainer({super.key});

  @override
  State<BottomContainer> createState() => _BottomContainerState();
}

class _BottomContainerState extends State<BottomContainer> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // This will now work
  double _currentPosition = 0.0;
  double _currentVolume = 0.5;
  bool _isPlaying = false;
  bool _isMuted = false;
  String _currentSongUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadUserPreferences();
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

  void _setupAudioPlayerListeners() {
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
  }

  Future<void> _handleSongChange(String newSongUrl, bool shouldPlay) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    }

    _currentSongUrl = newSongUrl;

    // Convert backslashes to forward slashes to avoid issues on Windows
    String fixedPath = newSongUrl.replaceAll(r'\', '/');
    
    // Use FileSource for local files
    await _audioPlayer.setSource(DeviceFileSource(fixedPath)); // Updated for local file
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Correct LoopMode to ReleaseMode

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

      setState(() {
        if (lastVolumeLevel is double) {
          _currentVolume = lastVolumeLevel;
        } else if (lastVolumeLevel is int) {
          _currentVolume = lastVolumeLevel.toDouble();
        }
        _audioPlayer.setVolume(_currentVolume);
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
        _buildPlayPauseButton(),
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
      setState(() {
        _currentVolume = value;
        _audioPlayer.setVolume(value);
        if (_isMuted) _toggleMute();
      });

      try {
        await Provider.of<SongProvider>(context, listen: false)
            .saveVolumeToSQLiteAndJson(_currentVolume);
        print("Volume saved successfully: $_currentVolume");
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
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
