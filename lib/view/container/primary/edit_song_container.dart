import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/provider/album_provider.dart';
import 'package:soundify/provider/image_provider.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/primary/home_container.dart';
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

class EditSongContainer extends StatefulWidget {
  final Function(Widget)
      onChangeWidget; // Tambahkan callback function ke constructor
  final String songId;
  final String songUrl;
  final String songImageUrl;
  final String artistId;
  final String albumId;
  final int artistSongIndex;
  final String songTitle;
  final Duration songDuration;
  const EditSongContainer({
    super.key,
    required this.onChangeWidget,
    required this.songId,
    required this.songUrl,
    required this.songImageUrl,
    required this.artistId,
    required this.albumId,
    required this.artistSongIndex,
    required this.songTitle,
    required this.songDuration,
  });

  @override
  _EditSongContainerState createState() => _EditSongContainerState();
}

class _EditSongContainerState extends State<EditSongContainer> {
  String? _songPath;
  String? _imagePath;

  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPickerActive = false;
  bool _isSongSelected = false;
  bool _isImageSelected = false;
  bool _isPlaying = false;
  bool _isArtistIdEdited = false;
  bool _isAlbumIdEdited = false;
  bool _isFetchingDuration = false;

  Duration? songDuration;
  int? songDurationS;

  TextEditingController _songFileNameController = TextEditingController();
  TextEditingController _songImageFileNameController = TextEditingController();
  TextEditingController _songTitleController = TextEditingController();
  TextEditingController _albumIdController = TextEditingController();
  TextEditingController artistIdController = TextEditingController();

  String? senderId;

  bool _isHoveredSongFileName = false;
  bool _isHoveredImageFileName = false;
  bool _isHoveredArtistId = false;
  bool _isHoveredAlbumId = false;
  bool _isHoveredSongTitle = false;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WidgetStateProvider2>(context, listen: false)
          .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
    });

    // Controller for the song file name
    _songFileNameController = TextEditingController();
    _songImageFileNameController = TextEditingController();
    artistIdController = TextEditingController();
    _albumIdController = TextEditingController();

    _songTitleController = TextEditingController(
      text: widget.songTitle, // Set the initial value from widget.songTitle
    );

    artistIdController.text = widget.artistId;
    _albumIdController.text = widget.albumId;
    _initializeAudioPlayer();

    // Flags to handle image and song selection
    _isSongSelected = false;
    _isImageSelected = false;
    _isArtistIdEdited = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dapatkan old widget dari context
    final oldWidget =
        context.findAncestorWidgetOfExactType<EditSongContainer>();

    if (oldWidget != null && oldWidget.songTitle != widget.songTitle) {
      _songTitleController.text = widget.songTitle; // Update controller text
    }
    // Ensure the widget is mounted and dependencies have been provided
    if (mounted) {
      // Safely update controllers with new values
      updateArtistIdController();
      updateAlbumIdController();
    }
  }

  void updateArtistIdController() {
    final newArtistId = Provider.of<SongProvider>(context).artistId;

    // Only update if the new value differs from the current one
    if (_isArtistIdEdited == false) {
      artistIdController.text = newArtistId;
    } else if (_isArtistIdEdited == true) {
      artistIdController.text = widget.artistId;
      if (_isArtistIdEdited == false) {
        artistIdController.text = newArtistId;
      }
    }
  }

  void updateAlbumIdController() {
    final newAlbumId = Provider.of<AlbumProvider>(context).albumId;

    // Only update if the new value differs from the current one
    if (_isAlbumIdEdited == false) {
      _albumIdController.text = newAlbumId;
    } else if (_isAlbumIdEdited == true) {
      _albumIdController.text = widget.albumId;
      if (_isAlbumIdEdited == false) {
        _albumIdController.text = newAlbumId;
      }
    }
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
        setState(() {
          songDuration = duration;
          songDurationS = duration.inSeconds;
        });
      });

      _audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          currentPosition = position;
        });
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
    if (currentPosition != null && mounted) {
      // Resume from the last position
      await _audioPlayer.seek(currentPosition!);
      await _audioPlayer
          .play(DeviceFileSource(_songPath!)); // Add the source here
    } else if (_songPath != null && mounted) {
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

  @override
  void dispose() {
    _audioPlayer.dispose(); // Pastikan audio player berhenti
    _songFileNameController.dispose();
    _songImageFileNameController.dispose();
    _songTitleController.dispose();
    artistIdController.dispose();
    _albumIdController.dispose();
    _isDisposed = true;
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
                    controller: _songFileNameController.text.isNotEmpty
                        ? _songFileNameController
                        : TextEditingController(
                            text: widget.songUrl,
                          ),
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
                    controller: _songImageFileNameController.text.isNotEmpty
                        ? _songImageFileNameController
                        : TextEditingController(
                            text:
                                widget.songImageUrl), // Use the controller here
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
                    controller: artistIdController.text.isNotEmpty
                        ? artistIdController
                        : TextEditingController(
                            text: widget.artistId), // Use the controller here
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
                    controller: _albumIdController.text.isNotEmpty
                        ? _albumIdController
                        : TextEditingController(
                            text: widget.albumId), // Use the controller here
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
                    controller: _songTitleController,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    hoverColor: primaryTextColor.withOpacity(0.1),
                    onTap: () {
                      Provider.of<WidgetStateProvider1>(context, listen: false)
                          .changeWidget(
                              const HomeContainer(), 'Home Container');

                      Provider.of<WidgetStateProvider2>(context, listen: false)
                          .changeWidget(
                              const ShowDetailSong(), 'ShowDetailSong');
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: secondaryColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  InkWell(
                    hoverColor: primaryTextColor.withOpacity(0.1),
                    onTap: () async {
                      // Call the function to edit song data
                      await _handleEditSubmission(context);

                      // Check if the widget is still mounted before calling setState
                      if (mounted) {
                        setState(() {
                          _isArtistIdEdited = true;
                          _isAlbumIdEdited = true;
                        });

                        // Change the active widget state
                        Provider.of<WidgetStateProvider1>(context,
                                listen: false)
                            .changeWidget(
                                const HomeContainer(), 'Home Container');
                        Provider.of<WidgetStateProvider2>(context,
                                listen: false)
                            .changeWidget(
                                const ShowDetailSong(), 'Show Detail Song');

                        // Reset artistId using SongProvider
                        final artistIdProvider =
                            Provider.of<SongProvider>(context, listen: false);
                        artistIdProvider.resetArtistId();

                        // Reset albumId using AlbumProvider
                        final albumIdProvider =
                            Provider.of<AlbumProvider>(context, listen: false);
                        albumIdProvider.resetAlbumId();
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: secondaryColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Safe setState that checks if widget is mounted
  void setStateIfMounted(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _handleEditSubmission(BuildContext context) async {
    if (_isFetchingDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taking song duration, please wait...')),
      );
      return;
    }

    try {
      await _editSongData();

      if (!_isDisposed) {
        // Update providers and navigation only if widget is still mounted
        _updateProvidersAndNavigate(context);
      }
    } catch (e) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit song data: $e')),
        );
      }
    }
  }

  void _updateProvidersAndNavigate(BuildContext context) {
    // Update providers
    Provider.of<SongProvider>(context, listen: false).resetArtistId();
    Provider.of<AlbumProvider>(context, listen: false).resetAlbumId();

    // Navigate
    Provider.of<WidgetStateProvider1>(context, listen: false)
        .changeWidget(const HomeContainer(), 'Home Container');
    Provider.of<WidgetStateProvider2>(context, listen: false)
        .changeWidget(const ShowDetailSong(), 'Show Detail Song');
  }

  Future<void> _editSongData() async {
    if (_isDisposed) return;

    String songTitle = _songTitleController.text.isNotEmpty
        ? _songTitleController.text
        : widget.songTitle;
    String artistId = artistIdController.text.isNotEmpty
        ? artistIdController.text
        : widget.artistId;
    String albumId = _albumIdController.text.isNotEmpty
        ? _albumIdController.text
        : widget.albumId;

    try {
      String? songDownloadUrl;
      String? imageDownloadUrl;

      // Only save new song file if one was selected
      if (_songPath != null) {
        songDownloadUrl = await _saveFileFromPath(
          _songPath!,
          'songs',
          'song_${widget.artistSongIndex}',
        );
      }

      if (_imagePath != null) {
        imageDownloadUrl = await _saveFileFromPath(
          _imagePath!,
          'song_images',
          'image_${widget.artistSongIndex}',
        );
      }

      final dbHelper = DatabaseHelper.instance;
      Song? existingSong = await dbHelper.getSongById(widget.songId);

      if (existingSong != null) {
        await _handleAlbumChange(dbHelper, existingSong.albumId, albumId);

        // Create a new Song instance instead of modifying existing one
        final updatedSong = Song(
          songId: existingSong.songId,
          songUrl: songDownloadUrl ??
              existingSong.songUrl, // Use existing URL if no new file
          songImageUrl: imageDownloadUrl ?? existingSong.songImageUrl,
          songTitle: songTitle,
          artistId: artistId,
          albumId: albumId,
          artistSongIndex: widget.artistSongIndex,
          songDuration:
              Duration(seconds: songDurationS ?? widget.songDuration.inSeconds),
          // Copy other necessary fields from existingSong
          senderId: existingSong.senderId,
          timestamp: existingSong.timestamp,
          likeIds: existingSong.likeIds,
          playlistIds: existingSong.playlistIds,
          albumIds: existingSong.albumIds,
          playedIds: existingSong.playedIds,
        );

        await dbHelper.updateSong(updatedSong);
        await _updateSongsJson(updatedSong);

        if (!_isDisposed) {
          _resetForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song data successfully edited')),
          );
        }
      }
    } catch (e) {
      print('Error editing song data: $e');
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit song data: $e')),
        );
      }
      rethrow;
    }
  }

  Future<void> _handleAlbumChange(
      DatabaseHelper dbHelper, String currentAlbumId, String newAlbumId) async {
    if (newAlbumId.isNotEmpty && currentAlbumId != newAlbumId) {
      // Remove from old album
      if (currentAlbumId.isNotEmpty) {
        Album? oldAlbum = await dbHelper.getAlbumById(currentAlbumId);
        if (oldAlbum != null) {
          List<String> oldSongListIds = oldAlbum.songListIds ?? [];
          oldSongListIds.remove(widget.songId);
          oldAlbum.songListIds = oldSongListIds;
          await dbHelper.updateAlbum(oldAlbum);
        }
      }

      // Add to new album
      Album? newAlbum = await dbHelper.getAlbumById(newAlbumId);
      if (newAlbum != null) {
        List<String> newSongListIds = newAlbum.songListIds ?? [];
        if (!newSongListIds.contains(widget.songId)) {
          newSongListIds.add(widget.songId);
          newAlbum.songListIds = newSongListIds;
          await dbHelper.updateAlbum(newAlbum);
        }
      }
    }
  }

  // New helper method to save files from path
  Future<String> _saveFileFromPath(
      String sourcePath, String folderName, String filePrefix) async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = '${directory.path}/soundify_database/$folderName';

    // Create the folder if it doesn't exist
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // Create a new file name using timestamp
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$filePrefix${path.extension(sourcePath)}';
    final destinationPath = '$folderPath/$fileName';

    try {
      // Copy file to new location
      final File sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      return destinationPath;
    } catch (e) {
      print('Error saving file: $e');
      rethrow;
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

  void _resetForm() {
    _songFileNameController.clear();
    _songImageFileNameController.clear();
    _songTitleController.clear();
    artistIdController.clear();
    _albumIdController.clear();
    setState(() {
      _imagePath = null;
      _songPath = null;
      _isSongSelected = false;
      _isImageSelected = false;
    });
  }
}
