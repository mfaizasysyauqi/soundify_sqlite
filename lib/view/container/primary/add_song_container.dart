import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/provider/album_provider.dart';
import 'package:soundify/provider/image_provider.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/secondary/create/search_album_id.dart';
import 'package:soundify/view/container/secondary/create/search_artist_Id.dart';
import 'package:soundify/view/container/secondary/create/show_image.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/style/style.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/album.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

class AddSongContainer extends StatefulWidget {
  final Function(Widget) onChangeWidget;

  const AddSongContainer({Key? key, required this.onChangeWidget})
      : super(key: key);

  @override
  _AddSongContainerState createState() => _AddSongContainerState();
}

class _AddSongContainerState extends State<AddSongContainer> {
  String? _songPath;
  String? _imagePath;

  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPickerActive = false;
  bool _isSongSelected = false;
  bool _isImageSelected = false;
  bool _isPlaying = false;
  bool _isArtistIdEdited = false;
  bool _isAlbumIdEdited = false;
  final bool _isFetchingDuration = false;

  Duration? songDuration;
  int? songDurationS;

  final TextEditingController _songFileNameController = TextEditingController();
  final TextEditingController _songImageFileNameController =
      TextEditingController();
  final TextEditingController _songTitleController = TextEditingController();
  final TextEditingController _albumIdController = TextEditingController();
  final TextEditingController _artistIdController = TextEditingController();

  String? senderId;

  bool _isHoveredSongFileName = false;
  bool _isHoveredImageFileName = false;
  bool _isHoveredArtistId = false;
  bool _isHoveredAlbumId = false;
  bool _isHoveredSongTitle = false;

  @override
  void initState() {
    super.initState();
    _resetForm();
    _initializeAudioPlayer();
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WidgetStateProvider2>(context, listen: false)
          .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
    });
  }

  void _initializeAudioPlayer() {
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            songDuration = duration;
            songDurationS = duration.inSeconds;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            currentPosition = position;
          });
        }
      });
    } catch (e) {
      print("Error initializing audioplayer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing audio player: $e')),
      );
    }
  }

  Future<void> _loadCurrentUserId() async {
    senderId = await DatabaseHelper.instance.getCurrentUserId();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      updateArtistIdController();
      updateAlbumIdController();
    }
  }

  void updateArtistIdController() {
    final newArtistId = Provider.of<SongProvider>(context).artistId;
    if (!_isArtistIdEdited) {
      _artistIdController.text = newArtistId;
    }
  }

  void updateAlbumIdController() {
    final newAlbumId = Provider.of<AlbumProvider>(context).albumId;
    if (!_isAlbumIdEdited) {
      _albumIdController.text = newAlbumId;
    }
  }

  Future<String> _saveBytesToFile(
      Uint8List bytes, String fileName, String directory) async {
    final appDir = await getApplicationDocumentsDirectory();
    final soundifyDir =
        Directory(path.join(appDir.path, 'soundify_database', directory));
    if (!await soundifyDir.exists()) {
      await soundifyDir.create(recursive: true);
    }
    final file = File(path.join(soundifyDir.path, fileName));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void onSongPathChanged(String? newSongPath) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }

    if (mounted) {
      setState(() {
        _songPath = newSongPath;
        _songFileNameController.text = newSongPath?.split('/').last ?? '';
        currentPosition = null;
        _isSongSelected = true;
      });
    }

    if (_songPath != null && _isPlaying) {
      await playSong();
    }

    if (_songPath != null) {
      try {
        await _audioPlayer
            .setSource(DeviceFileSource(_songPath!)); // Set file source
      } catch (e) {
        print("Error setting file path: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No song path found')),
      );
    }
  }

  void onImagePathChanged(String? newImagePath) {
    if (mounted) {
      setState(() {
        _imagePath = newImagePath;
        _songImageFileNameController.text = newImagePath?.split('/').last ?? '';
      });
    }
  }

  Duration? currentPosition;

  Future<void> playSong() async {
    if (currentPosition != null) {
      // Resume from the last position
      await _audioPlayer.seek(currentPosition!);
      await _audioPlayer
          .play(DeviceFileSource(_songPath!)); // Add the source here
    } else if (_songPath != null) {
      // Play from the beginning
      try {
        await _audioPlayer
            .play(DeviceFileSource(_songPath!)); // Set the file path
      } catch (e) {
        print("Error setting file path: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to set audio file: $e')),
        );
        return;
      }
    }
  }

  Future<void> pauseSong() async {
    await _audioPlayer.pause();
  }

  bool _isFormValid() {
    return _isSongSelected &&
        _isImageSelected &&
        _artistIdController.text.isNotEmpty &&
        _albumIdController.text.isNotEmpty &&
        _songTitleController.text.isNotEmpty &&
        !_isFetchingDuration;
  }

  Future<void> _submitSongData() async {
    if (senderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not logged in')),
      );
      return;
    }

    if (songDurationS == null || _songPath == null || _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select both song and image and play the song to fetch duration')),
      );
      return;
    }

    try {
      // Save song file to local storage
      String savedSongPath = await _saveFile(_songPath!, 'songs', 'song_file');

      // Save image file to local storage
      String savedImagePath =
          await _saveFile(_imagePath!, 'song_images', 'song_image');

      // Generate unique song ID
      String songId = Uuid().v4();

      // Get the appropriate artistFileIndex
      List<Song> existingSongs = await DatabaseHelper.instance.getSongs();
      int artistFileIndex = existingSongs
              .where((song) => song.artistId == _artistIdController.text)
              .length +
          1;

      // Create new Song object
      Song newSong = Song(
        songId: songId,
        senderId: senderId!,
        artistId: _artistIdController.text,
        songTitle: _songTitleController.text,
        songImageUrl: savedImagePath,
        songUrl: savedSongPath,
        songDuration: Duration(seconds: songDurationS!),
        timestamp: DateTime.now(),
        albumId: _albumIdController.text,
        artistSongIndex: artistFileIndex,
        likeIds: [],
        playlistIds: [],
        albumIds: [_albumIdController.text],
        playedIds: [],
      );

      // Insert song into database
      await DatabaseHelper.instance.insertSong(newSong);

      // Update album with the new song
      Album? album =
          await DatabaseHelper.instance.getAlbumById(_albumIdController.text);
      if (album != null) {
        // Create a new map for the album update
        Map<String, dynamic> updateData = {
          'albumId': album.albumId,
          'songListIds': album.songListIds != null
              ? [...album.songListIds!, songId].join(',')
              : songId,
          'totalDuration': album.totalDuration.inSeconds + songDurationS!
        };

        // Update the album using the updateData map
        await DatabaseHelper.instance
            .update('albums', updateData, 'albumId = ?', [album.albumId]);
      }

      // Update songs.json
      await _updateSongsJson(newSong);

      // Reset form and show success message
      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song successfully added to album')),
      );

      // Reset providers
      Provider.of<SongProvider>(context, listen: false).resetArtistId();
      Provider.of<AlbumProvider>(context, listen: false).resetAlbumId();

      // Navigate back to song detail view
      Provider.of<WidgetStateProvider2>(context, listen: false)
          .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
    } catch (e) {
      print('Error submitting song data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit song data: $e')),
      );
    }
  }

  Future<void> _updateSongsJson(Song newSong) async {
    try {
      final fileHelper = FileStorageHelper.instance;
      Map<String, dynamic>? songData = await fileHelper.readData('songs.json');
      if (songData == null) {
        songData = {'songs': []};
      }

      List<dynamic> songs = songData['songs'];
      songs.add({
        'songId': newSong.songId,
        'senderId': newSong.senderId,
        'artistId': newSong.artistId,
        'songTitle': newSong.songTitle,
        'songImageUrl': newSong.songImageUrl,
        'songUrl': newSong.songUrl,
        'songDuration': newSong.songDuration.inSeconds,
        'timestamp': newSong.timestamp.toIso8601String(),
        'albumId': newSong.albumId,
        'artistSongIndex': newSong.artistSongIndex,
        'likeIds': newSong.likeIds,
        'playlistIds': newSong.playlistIds,
        'albumIds': newSong.albumIds,
        'playedIds': newSong.playedIds,
      });

      await fileHelper.writeData('songs.json', songData);
    } catch (e) {
      print('Error updating songs.json: $e');
    }
  }

  Future<String> _saveFile(
      String filePath, String folderName, String filePrefix) async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = '${directory.path}/soundify_database/$folderName';

    // Create the folder if it doesn't exist
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // Extract just the file name from the full path
    final originalFileName = path.basename(filePath);

    // Create a new file name using the timestamp, prefix, and original file name
    final newFileName =
        '${DateTime.now().millisecondsSinceEpoch}_${filePrefix}_$originalFileName';

    final newFilePath = path.join(folderPath, newFileName);

    try {
      // Copy the file
      final file = File(filePath);
      await file.copy(newFilePath);
      return newFilePath;
    } catch (e) {
      print('Error copying file: $e');
      rethrow;
    }
  }

// Add this method for cleaning up before navigation
  void cleanupBeforeNavigation() {
    if (!mounted) return;

    // Stop audio if playing
    if (_audioPlayer.state == PlayerState.playing) {
      _audioPlayer.stop();
    }

    // Reset state variables without touching controllers
    setState(() {
      _imagePath = null;
      _songPath = null;
      _isSongSelected = false;
      _isImageSelected = false;
    });
  }

// Update _resetForm to use mounted check
  void _resetForm() {
    if (!mounted) return;

    setState(() {
      try {
        // Clear text controllers if the widget is still mounted
        _songFileNameController.text = '';
        _songImageFileNameController.text = '';
        _songTitleController.text = '';
        _artistIdController.text = '';
        _albumIdController.text = '';

        // Reset state variables
        _imagePath = null;
        _songPath = null;
        _isSongSelected = false;
        _isImageSelected = false;
      } catch (e) {
        // Handle any errors that might occur if controllers are already disposed
        print('Error resetting form: $e');
      }
    });
  }

  @override
  void dispose() {
    // First stop the audio player if it's playing
    if (_audioPlayer.state == PlayerState.playing) {
      _audioPlayer.stop();
    }

    // Dispose audio player
    _audioPlayer.dispose();

    // Dispose all controllers
    _songTitleController.dispose();
    _artistIdController.dispose();
    _albumIdController.dispose();
    _songFileNameController.dispose();
    _songImageFileNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 50, // Atur tinggi sesuai kebutuhan
                child: MouseRegion(
                  onEnter: (event) => setState(() {
                    _isHoveredSongFileName = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHoveredSongFileName = false;
                  }),
                  child: TextFormField(
                    style: const TextStyle(color: primaryTextColor),
                    controller:
                        _songFileNameController, // Gunakan controller untuk menampilkan nama file
                    readOnly:
                        true, // Field hanya baca, karena pengguna tidak menginput manual
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(
                          8), // Tambahkan padding jika perlu
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (_isPickerActive) {
                                return; // Cegah klik ganda
                              }
                              if (mounted) {
                                setState(() {
                                  _isPickerActive = true;
                                });
                              }

                              try {
                                final pickedSongFile =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.audio,
                                  allowMultiple: false, // Hanya pilih satu file
                                );
                                if (pickedSongFile != null) {
                                  // Ambil file path dari platform desktop
                                  String? filePath =
                                      pickedSongFile.files.first.path;

                                  if (filePath != null) {
                                    // Update path dan file name
                                    onSongPathChanged(filePath);

                                    // Tampilkan nama file di TextFormField
                                    _songFileNameController.text =
                                        filePath.split('/').last;

                                    // Set _isSongSelected menjadi true setelah file dipilih
                                    setState(() {
                                      _isSongSelected = true;
                                    });
                                  }
                                }
                              } catch (e) {
                                print("Error picking file: $e");
                              } finally {
                                if (mounted) {
                                  // Reset _isPickerActive setelah pemilihan file
                                  setState(() {
                                    _isPickerActive = false;
                                  });
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.music_note,
                              color: primaryTextColor,
                            ),
                          ),
                          const VerticalDivider(
                            color: primaryTextColor, // Warna divider
                            width: 1, // Lebar divider
                            thickness: 1, // Ketebalan divider
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      suffixIcon: _isSongSelected
                          ? IconButton(
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    if (_isPlaying) {
                                      pauseSong(); // Fungsi untuk pause musik
                                      _isPlaying = false;
                                      currentPosition = null;
                                    } else {
                                      playSong(); // Fungsi untuk play musik
                                      _isPlaying = true;
                                    }
                                  });
                                }
                              },
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: primaryTextColor,
                              ),
                            )
                          : null,
                      hintText: 'Song File Name',
                      hintStyle: const TextStyle(color: primaryTextColor),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryTextColor,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: secondaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isHoveredSongFileName
                              ? secondaryColor
                              : senaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 50, // Atur tinggi sesuai kebutuhan
                child: MouseRegion(
                  onEnter: (event) => setState(() {
                    _isHoveredImageFileName = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHoveredImageFileName = false;
                  }),
                  child: TextFormField(
                    style: const TextStyle(color: primaryTextColor),
                    controller:
                        _songImageFileNameController, // Use the controller here
                    readOnly:
                        true, // Make the text field read-only since the user doesn't manually input the file name
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(
                          8), // Optional: tambahkan padding jika perlu
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (_isPickerActive) {
                                return; // Prevent multiple clicks
                              }
                              if (mounted) {
                                setState(() {
                                  _isPickerActive = true;
                                });
                              }
                              try {
                                final pickedImageFile =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple:
                                      false, // Jika hanya ingin memilih satu file
                                );
                                if (pickedImageFile != null) {
                                  // Ambil file path dari file yang dipilih
                                  String? filePath =
                                      pickedImageFile.files.first.path;

                                  if (filePath != null) {
                                    onImagePathChanged(filePath);

                                    // Update image data di Provider dengan file path
                                    Provider.of<ImageProviderData>(context,
                                            listen: false)
                                        .setImageData(
                                            filePath); // Mengirim null untuk fileBytes karena kita hanya butuh path

                                    setState(() {
                                      _isImageSelected = true;
                                    });
                                  }
                                }
                              } catch (e) {
                                print("Error picking file: $e");
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isPickerActive = false;
                                  });
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.image,
                              color: primaryTextColor,
                            ),
                          ),
                          const VerticalDivider(
                            color: primaryTextColor, // Warna divider
                            width: 1, // Lebar divider
                            thickness: 1, // Ketebalan divider
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      suffixIcon: _isImageSelected
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  // Mengganti widget di dalam Provider dengan dua argumen
                                  Provider.of<WidgetStateProvider2>(context,
                                          listen: false)
                                      .changeWidget(
                                          const ShowImage(), 'ShowImage');
                                });
                              },
                              icon: const Icon(
                                Icons.visibility,
                                color: primaryTextColor,
                              ),
                            )
                          : null,
                      hintText: 'Image File Name',
                      hintStyle: const TextStyle(color: primaryTextColor),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryTextColor,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: secondaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isHoveredImageFileName
                              ? secondaryColor
                              : senaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 50, // Atur tinggi sesuai kebutuhan
                child: MouseRegion(
                  onEnter: (event) => setState(() {
                    _isHoveredArtistId = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHoveredArtistId = false;
                  }),
                  child: TextFormField(
                    style: const TextStyle(color: primaryTextColor),
                    controller: _artistIdController, // Use the controller here
                    readOnly:
                        true, // Make the text field read-only since the user doesn't manually input the file name
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(
                          8), // Optional: tambahkan padding jika perlu
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isArtistIdEdited =
                                    false; // Mengganti widget di dalam Provider dengan dua argumen
                                Provider.of<WidgetStateProvider2>(context,
                                        listen: false)
                                    .changeWidget(
                                        const SearchArtistId(), 'ShowArtistId');
                              });
                            },
                            icon: const Icon(
                              Icons.person,
                              color: primaryTextColor,
                            ),
                          ),
                          const VerticalDivider(
                            color: primaryTextColor, // Warna divider
                            width: 1, // Lebar divider
                            thickness: 1, // Ketebalan divider
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),

                      hintText: 'Artist ID',
                      hintStyle: const TextStyle(color: primaryTextColor),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryTextColor,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: secondaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              _isHoveredArtistId ? secondaryColor : senaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 50, // Atur tinggi sesuai kebutuhan
                child: MouseRegion(
                  onEnter: (event) => setState(() {
                    _isHoveredAlbumId = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHoveredAlbumId = false;
                  }),
                  child: TextFormField(
                    style: const TextStyle(color: primaryTextColor),
                    controller: _albumIdController, // Use the controller here
                    readOnly:
                        true, // Make the text field read-only since the user doesn't manually input the file name
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(
                          8), // Optional: tambahkan padding jika perlu
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isAlbumIdEdited =
                                    false; // Mengganti widget di dalam Provider dengan dua argumen
                                Provider.of<WidgetStateProvider2>(context,
                                        listen: false)
                                    .changeWidget(
                                        const SearchAlbumId(), 'SearchAlbumId');
                              });
                            },
                            icon: const Icon(
                              Icons.album,
                              color: primaryTextColor,
                            ),
                          ),
                          const VerticalDivider(
                            color: primaryTextColor, // Warna divider
                            width: 1, // Lebar divider
                            thickness: 1, // Ketebalan divider
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),

                      hintText: 'Album ID',
                      hintStyle: const TextStyle(color: primaryTextColor),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryTextColor,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: secondaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              _isHoveredAlbumId ? secondaryColor : senaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 50, // Atur tinggi sesuai kebutuhan
                child: MouseRegion(
                  onEnter: (event) => setState(() {
                    _isHoveredSongTitle = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHoveredSongTitle = false;
                  }),
                  child: TextFormField(
                    style: const TextStyle(color: primaryTextColor),
                    controller: _songTitleController, // Use the controller here
                    readOnly:
                        false, // Make the text field read-only since the user doesn't manually input the file name
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(
                          8), // Optional: tambahkan padding jika perlu
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.headset,
                              color: primaryTextColor,
                            ),
                          ),
                          const VerticalDivider(
                            color: primaryTextColor, // Warna divider
                            width: 1, // Lebar divider
                            thickness: 1, // Ketebalan divider
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      hintText: 'Song Title',
                      hintStyle: const TextStyle(color: primaryTextColor),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryTextColor,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: secondaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isHoveredSongTitle
                              ? secondaryColor
                              : senaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_isFormValid()) {
                    _submitSongData();
                    Provider.of<WidgetStateProvider2>(context, listen: false)
                        .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: _isFormValid() ? quinaryColor : tertiaryTextColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: _isFormValid()
                              ? primaryTextColor
                              : secondaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
