// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:soundify/backup/song_provider.dart';
// import 'package:soundify/database/file_storage_helper.dart';
// import 'package:soundify/provider/album_provider.dart';
// import 'package:soundify/provider/image_provider.dart';
// import 'package:soundify/provider/widget_state_provider_2.dart';
// import 'package:soundify/view/container/secondary/create/search_album_id.dart';
// import 'package:soundify/view/container/secondary/create/search_artist_Id.dart';
// import 'package:soundify/view/container/secondary/create/show_image.dart';
// import 'package:soundify/view/container/secondary/show_detail_song.dart';
// import 'package:soundify/view/style/style.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:soundify/database/database_helper.dart';
// import 'package:soundify/models/song.dart';
// import 'package:soundify/models/album.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:path/path.dart' as path;
// import 'package:audioplayers/audioplayers.dart';

// class AddSongContainer extends StatefulWidget {
//   final Function(Widget) onChangeWidget;

//   const AddSongContainer({Key? key, required this.onChangeWidget})
//       : super(key: key);

//   @override
//   _AddSongContainerState createState() => _AddSongContainerState();
// }

// class _AddSongContainerState extends State<AddSongContainer> {
//   String? _songPath;
//   String? _imagePath;

//   late SongProvider _songProvider;
//   bool _isPickerActive = false;
//   bool _isSongSelected = false;
//   bool _isImageSelected = false;
//   bool _isPlaying = false;
//   bool _isArtistIdEdited = false;
//   bool _isAlbumIdEdited = false;

//   Duration? songDuration;
//   int? songDurationS;

//   final TextEditingController _songFileNameController = TextEditingController();
//   final TextEditingController _songImageFileNameController =
//       TextEditingController();
//   final TextEditingController _songTitleController = TextEditingController();
//   final TextEditingController _albumIdController = TextEditingController();
//   final TextEditingController _artistIdController = TextEditingController();

//   String? senderId;

//   // Hover states
//   final Map<String, bool> _hoverStates = {
//     'songFileName': false,
//     'imageFileName': false,
//     'artistId': false,
//     'albumId': false,
//     'songTitle': false,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _songProvider = Provider.of<SongProvider>(context, listen: false);
//     _loadCurrentUserId();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<WidgetStateProvider2>(context, listen: false)
//           .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
//     });
//   }

//   Future<void> _loadCurrentUserId() async {
//     senderId = await DatabaseHelper.instance.getCurrentUserId();
//     setState(() {});
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (mounted) {
//       updateArtistIdController();
//       updateAlbumIdController();
//     }
//   }

//   void updateArtistIdController() {
//     final newArtistId = Provider.of<SongProvider>(context).artistId;
//     if (!_isArtistIdEdited) {
//       _artistIdController.text = newArtistId;
//     }
//   }

//   void updateAlbumIdController() {
//     final newAlbumId = Provider.of<AlbumProvider>(context).albumId;
//     if (!_isAlbumIdEdited) {
//       _albumIdController.text = newAlbumId;
//     }
//   }

//   Future<String> _saveBytesToFile(
//       Uint8List bytes, String fileName, String directory) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final soundifyDir =
//         Directory(path.join(appDir.path, 'soundify_database', directory));
//     if (!await soundifyDir.exists()) {
//       await soundifyDir.create(recursive: true);
//     }
//     final file = File(path.join(soundifyDir.path, fileName));
//     await file.writeAsBytes(bytes);
//     return file.path;
//   }

//   void onSongPathChanged(String? newSongPath, SongProvider songProvider) async {
//     if (_isPlaying) {
//       await songProvider.audioPlayer.stop();
//     }

//     if (mounted) {
//       setState(() {
//         _songPath = newSongPath;
//         _songFileNameController.text = newSongPath?.split('/').last ?? '';
//         currentPosition = null;
//         _isSongSelected = true;
//       });
//     }

//     if (_songPath != null && _isPlaying) {
//       songProvider.playSong;
//     }

//     if (_songPath != null) {
//       try {
//         await songProvider.audioPlayer
//             .setSource(DeviceFileSource(_songPath!)); // Set file source
//       } catch (e) {
//         print("Error setting file path: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error setting file: $e')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No song path found')),
//       );
//     }
//   }

//   void onImagePathChanged(String? newImagePath) {
//     if (mounted) {
//       setState(() {
//         _imagePath = newImagePath;
//         _songImageFileNameController.text = newImagePath?.split('/').last ?? '';
//       });
//     }
//   }

//   Duration? currentPosition;

//   bool _isFormValid() {
//     return _isSongSelected &&
//         _isImageSelected &&
//         _artistIdController.text.isNotEmpty &&
//         _albumIdController.text.isNotEmpty &&
//         _songTitleController.text.isNotEmpty;
//   }

//   Future<void> _submitSongData() async {
//     if (senderId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User is not logged in')),
//       );
//       return;
//     }

//     if (_songPath == null || _imagePath == null || songDurationS == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//               'Please select both song and image and ensure song duration is loaded'),
//         ),
//       );
//       return;
//     }

//     try {
//       // Save song file to local storage
//       String savedSongPath = await _saveFile(_songPath!, 'songs', 'song_file');

//       // Save image file to local storage
//       String savedImagePath =
//           await _saveFile(_imagePath!, 'song_images', 'song_image');

//       // Get the appropriate artistFileIndex
//       List<Song> existingSongs = await DatabaseHelper.instance.getSongs();
//       int artistFileIndex = existingSongs
//               .where((song) => song.artistId == _artistIdController.text)
//               .length +
//           1;

//       // Create new Song object
//       Song newSong = Song(
//         songId: DateTime.now().millisecondsSinceEpoch.toString(),
//         senderId: senderId!,
//         artistId: _artistIdController.text,
//         songTitle: _songTitleController.text,
//         songImageUrl: savedImagePath,
//         songUrl: savedSongPath,
//         songDuration: Duration(seconds: songDurationS!),
//         timestamp: DateTime.now(),
//         albumId: _albumIdController.text,
//         artistSongIndex: artistFileIndex,
//         likeIds: [],
//         playlistIds: [],
//         albumIds: [_albumIdController.text],
//         playedIds: [],
//       );

//       // Insert song into database
//       await DatabaseHelper.instance.insertSong(newSong);

//       // Update album
//       Album? album = await DatabaseHelper.instance
//           .getAlbumByCreatorId(_albumIdController.text);
//       if (album != null) {
//         album.songListIds?.add(newSong.songId);
//         album.totalDuration =
//             Duration(seconds: album.totalDuration.inSeconds + songDurationS!);
//         await DatabaseHelper.instance.updateAlbum(album);
//       }

//       // Update songs.json
//       await _updateSongsJson(newSong);

//       // Reset form and state after successful submission
//       _resetForm();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content:
//                 Text('Song data successfully submitted and added to album')),
//       );

//       // Reset providers
//       Provider.of<SongProvider>(context, listen: false).resetArtistId();
//       Provider.of<AlbumProvider>(context, listen: false).resetAlbumId();

//       // Change widget to show detail song
//       Provider.of<WidgetStateProvider2>(context, listen: false)
//           .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
//     } catch (e) {
//       print('Error submitting song data: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to submit song data: $e')),
//       );
//     }
//   }

//   Future<void> _updateSongsJson(Song newSong) async {
//     try {
//       final fileHelper = FileStorageHelper.instance;
//       Map<String, dynamic>? songData = await fileHelper.readData('songs.json');
//       if (songData == null) {
//         songData = {'songs': []};
//       }

//       List<dynamic> songs = songData['songs'];
//       songs.add({
//         'songId': newSong.songId,
//         'senderId': newSong.senderId,
//         'artistId': newSong.artistId,
//         'songTitle': newSong.songTitle,
//         'songImageUrl': newSong.songImageUrl,
//         'songUrl': newSong.songUrl,
//         'songDuration': newSong.songDuration.inSeconds,
//         'timestamp': newSong.timestamp.toIso8601String(),
//         'albumId': newSong.albumId,
//         'artistSongIndex': newSong.artistSongIndex,
//         'likeIds': newSong.likeIds,
//         'playlistIds': newSong.playlistIds,
//         'albumIds': newSong.albumIds,
//         'playedIds': newSong.playedIds,
//       });

//       await fileHelper.writeData('songs.json', songData);
//     } catch (e) {
//       print('Error updating songs.json: $e');
//     }
//   }

//   Future<String> _saveFile(
//       String filePath, String folderName, String filePrefix) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final folderPath = '${directory.path}/soundify_database/$folderName';

//       final folder = Directory(folderPath);
//       if (!await folder.exists()) {
//         await folder.create(recursive: true);
//       }

//       final originalFileName = path.basename(filePath);
//       final newFileName =
//           '${DateTime.now().millisecondsSinceEpoch}_${filePrefix}_$originalFileName';
//       final newFilePath = path.join(folderPath, newFileName);

//       final file = File(filePath);
//       if (!await file.exists()) {
//         throw Exception('Source file does not exist');
//       }

//       await file.copy(newFilePath);
//       return newFilePath;
//     } catch (e) {
//       print('Error saving file: $e');
//       throw Exception('Failed to save file: $e');
//     }
//   }

//   void _resetForm() {
//     if (!mounted) return; // Add this check

//     setState(() {
//       // Clear the text without using clear() method
//       _songFileNameController.text = '';
//       _songImageFileNameController.text = '';
//       _songTitleController.text = '';
//       _artistIdController.text = '';
//       _albumIdController.text = '';

//       _imagePath = null;
//       _songPath = null;
//       _isSongSelected = false;
//       _isImageSelected = false;
//     });
//   }

//   @override
//   void dispose() {
//     // Remove the _resetForm() call from here
//     _songTitleController.dispose();
//     _artistIdController.dispose();
//     _albumIdController.dispose();
//     _songFileNameController.dispose();
//     _songImageFileNameController.dispose();
//     super.dispose();
//   }

//   // Optional: Add this method if you need to reset the form before disposal
//   void cleanupBeforeDispose() {
//     if (mounted) {
//       setState(() {
//         _imagePath = null;
//         _songPath = null;
//         _isSongSelected = false;
//         _isImageSelected = false;
//       });
//     }
//   }

//   void _handleSongSelection(String filePath) async {
//     try {
//       setState(() {
//         _songPath = filePath;
//         _songFileNameController.text = filePath.split('/').last;
//         _isSongSelected = true;
//       });

//       // Set up audio player with the selected song
//       await _songProvider.audioPlayer.setSource(DeviceFileSource(filePath));

//       // Get song duration
//       Duration? duration = await _songProvider.audioPlayer.getDuration();
//       songDuration = duration;
//       songDurationS = duration?.inSeconds;

//       _songProvider.setSong(
//         DateTime.now().toString(), // temporary songId
//         senderId ?? '',
//         _artistIdController.text,
//         _songTitleController.text,
//         null, // profileImageUrl
//         _imagePath ?? '',
//         null, // bioImageUrl
//         null, // artistName
//         filePath,
//         duration ?? Duration.zero,
//         0, // temporary index
//       );
//     } catch (e) {
//       print('Error handling song selection: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error selecting song: $e')),
//       );
//     }
//   }

//   void _handleImageSelection(String filePath) {
//     setState(() {
//       _imagePath = filePath;
//       _songImageFileNameController.text = filePath.split('/').last;
//       _isImageSelected = true;
//     });

//     Provider.of<ImageProviderData>(context, listen: false)
//         .setImageData(filePath);
//   }

//   Future<void> _pickFile({
//     required FileType type,
//     required Function(String) onSelected,
//   }) async {
//     if (_isPickerActive) return;

//     setState(() => _isPickerActive = true);

//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: type,
//         allowMultiple: false,
//       );

//       if (result != null &&
//           result.files.isNotEmpty &&
//           result.files.first.path != null) {
//         final file = File(result.files.first.path!);
//         if (await file.exists()) {
//           onSelected(result.files.first.path!);
//         } else {
//           throw Exception('Selected file does not exist');
//         }
//       }
//     } catch (e) {
//       print("Error picking file: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error selecting file: $e')),
//       );
//     } finally {
//       setState(() => _isPickerActive = false);
//     }
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     required String hoverKey,
//     bool readOnly = true,
//     VoidCallback? onIconPressed,
//     Widget? suffixIcon,
//   }) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hoverStates[hoverKey] = true),
//       onExit: (_) => setState(() => _hoverStates[hoverKey] = false),
//       child: TextFormField(
//         style: const TextStyle(color: primaryTextColor),
//         controller: controller,
//         readOnly: readOnly,
//         decoration: InputDecoration(
//           contentPadding: const EdgeInsets.all(8),
//           prefixIcon: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 onPressed: onIconPressed,
//                 icon: Icon(icon, color: primaryTextColor),
//               ),
//               SizedBox(
//                 height: 50, // Ensures divider has a proper height.
//                 child: const VerticalDivider(
//                   color: primaryTextColor,
//                   width: 1,
//                   thickness: 1,
//                 ),
//               ),
//               const SizedBox(width: 12),
//             ],
//           ),
//           suffixIcon: suffixIcon,
//           hintText: label,
//           hintStyle: const TextStyle(color: primaryTextColor),
//           border: const OutlineInputBorder(
//             borderSide: BorderSide(color: primaryTextColor),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderSide: BorderSide(
//               color: _hoverStates[hoverKey]! ? secondaryColor : senaryColor,
//             ),
//           ),
//           focusedBorder: const OutlineInputBorder(
//             borderSide: BorderSide(color: secondaryColor),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<SongProvider>(
//       builder: (context, songProvider, _) {
//         return ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: Scaffold(
//             backgroundColor: primaryColor,
//             body: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   _buildTextField(
//                     label: 'Song File Name',
//                     controller: _songFileNameController,
//                     icon: Icons.music_note,
//                     hoverKey: 'songFileName',
//                     onIconPressed: () => _pickFile(
//                       type: FileType.audio,
//                       onSelected: _handleSongSelection,
//                     ),
//                     suffixIcon: _isSongSelected
//                         ? IconButton(
//                             onPressed: songProvider.togglePlayPause,
//                             icon: Icon(
//                               songProvider.isPlaying
//                                   ? Icons.pause
//                                   : Icons.play_arrow,
//                               color: primaryTextColor,
//                             ),
//                           )
//                         : null,
//                   ),
//                   const SizedBox(
//                     height: 8,
//                   ),
//                   _buildTextField(
//                     label: 'Image File Name',
//                     controller: _songImageFileNameController,
//                     icon: Icons.image,
//                     hoverKey: 'imageFileName',
//                     onIconPressed: () => _pickFile(
//                       type: FileType.image,
//                       onSelected: _handleImageSelection,
//                     ),
//                     suffixIcon: _isImageSelected
//                         ? IconButton(
//                             onPressed: () {
//                               setState(() {
//                                 // Mengganti widget di dalam Provider dengan dua argumen
//                                 Provider.of<WidgetStateProvider2>(context,
//                                         listen: false)
//                                     .changeWidget(
//                                         const ShowImage(), 'ShowImage');
//                               });
//                             },
//                             icon: const Icon(
//                               Icons.visibility,
//                               color: primaryTextColor,
//                             ),
//                           )
//                         : null,
//                   ),
//                   const SizedBox(
//                     height: 8,
//                   ),
//                   _buildTextField(
//                     label: 'Artist ID',
//                     controller: _artistIdController,
//                     icon: Icons.person,
//                     hoverKey: 'artistId',
//                     onIconPressed: () {
//                       _isArtistIdEdited =
//                           false; // Mengganti widget di dalam Provider dengan dua argumen
//                       Provider.of<WidgetStateProvider2>(context, listen: false)
//                           .changeWidget(const SearchArtistId(), 'ShowArtistId');
//                     },
//                   ),
//                   const SizedBox(
//                     height: 8,
//                   ),
//                   _buildTextField(
//                     label: 'Album ID',
//                     controller: _albumIdController,
//                     icon: Icons.album,
//                     hoverKey: 'albumId',
//                     onIconPressed: () {
//                       setState(() {
//                         _isAlbumIdEdited =
//                             false; // Mengganti widget di dalam Provider dengan dua argumen
//                         Provider.of<WidgetStateProvider2>(context,
//                                 listen: false)
//                             .changeWidget(
//                                 const SearchAlbumId(), 'SearchAlbumId');
//                       });
//                     },
//                   ),
//                   const SizedBox(
//                     height: 8,
//                   ),
//                   _buildTextField(
//                     label: 'Song Title',
//                     controller: _songTitleController,
//                     icon: Icons.headset,
//                     hoverKey: 'songTitle',
//                     onIconPressed: () {},
//                     readOnly: false,
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () {
//                       if (_isFormValid()) {
//                         _submitSongData();
//                         Provider.of<WidgetStateProvider2>(context,
//                                 listen: false)
//                             .changeWidget(
//                                 const ShowDetailSong(), 'ShowDetailSong');
//                       }
//                     },
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: Container(
//                         color:
//                             _isFormValid() ? quinaryColor : tertiaryTextColor,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12.0,
//                             vertical: 8.0,
//                           ),
//                           child: Text(
//                             "Submit",
//                             style: TextStyle(
//                               color: _isFormValid()
//                                   ? primaryTextColor
//                                   : secondaryTextColor,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
