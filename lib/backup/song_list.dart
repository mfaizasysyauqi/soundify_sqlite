// import 'dart:io';

// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:soundify/components/hover_icons_widget.dart';
// import 'package:soundify/database/database_helper.dart';
// import 'package:soundify/models/song.dart';
// import 'package:soundify/models/user.dart';
// import 'package:soundify/provider/like_provider.dart';
// import 'package:soundify/provider/song_list_item_provider.dart';
// import 'package:soundify/provider/song_provider.dart';
// import 'package:soundify/provider/widget_state_provider_1.dart';
// import 'package:soundify/provider/widget_state_provider_2.dart';
// import 'package:soundify/view/container/primary/album_container.dart';
// import 'package:soundify/view/container/secondary/show_detail_song.dart';
// import 'package:soundify/view/container/secondary/menu/song_menu.dart';
// import 'package:soundify/view/style/style.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';

// class SongList extends StatefulWidget {
//   final String userId;
//   final String pageName;
//   final String playlistId;
//   final String albumId;

//   const SongList({
//     super.key,
//     required this.userId,
//     required this.pageName,
//     required this.playlistId,
//     required this.albumId,
//   });

//   @override
//   State<SongList> createState() => _SongListState();
// }

// TextEditingController searchListController = TextEditingController();

// class _SongListState extends State<SongList> {
//   DatabaseHelper dbHelper = DatabaseHelper.instance;

//   @override
//   void initState() {
//     super.initState();
//     _loadSongs();
//     _fetchLastListenedSongId();
//     searchListController.addListener(_handleSearchChange);
//   }

//   @override
//   void dispose() {
//     searchListController.removeListener(_handleSearchChange);
//     super.dispose();
//   }

//   void _handleSearchChange() {
//     if (mounted) {
//       final provider =
//           Provider.of<SongListItemProvider>(context, listen: false);
//       provider.filterSongs(searchListController.text);
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     final currentWidgetName =
//         Provider.of<WidgetStateProvider1>(context, listen: true).widgetName;
//     final provider = Provider.of<SongListItemProvider>(context, listen: false);
//     bool wasSearch = provider.isSearch;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       provider.setIsSearch(currentWidgetName != "HomeContainer");
//       if (provider.isSearch && !wasSearch) {
//         searchListController.clear();
//       }
//     });
//   }

//   Future<void> _fetchLastListenedSongId() async {
//     User? currentUser = await dbHelper.getCurrentUser();
//     if (currentUser != null && mounted) {
//       Provider.of<SongListItemProvider>(context, listen: false)
//           .setLastListenedSongId(currentUser.lastListenedSongId);
//     }
//   }

//   Future<void> _loadSongs() async {
//     List<Song> fetchedSongs = [];
//     switch (widget.pageName) {
//       case "HomeContainer":
//         fetchedSongs = await dbHelper.getSongs();
//         break;
//       case "PersonalProfileContainer":
//       case "OtherProfileContainer":
//         fetchedSongs = await dbHelper.getSongsByArtist(widget.userId);
//         break;
//       case "AlbumContainer":
//         fetchedSongs = await dbHelper.getSongsByAlbum(widget.albumId);
//         break;
//       case "PlaylistContainer":
//         fetchedSongs = await dbHelper.getSongsByPlaylist(widget.playlistId);
//         break;
//       case "LikedSongContainer":
//         User? currentUser = await dbHelper.getCurrentUser();
//         if (currentUser != null) {
//           fetchedSongs = await dbHelper.getLikedSongs(currentUser.userId);
//         }
//         break;
//       default:
//         fetchedSongs = await dbHelper.getSongs();
//     }

//     if (mounted) {
//       final provider =
//           Provider.of<SongListItemProvider>(context, listen: false);
//       provider.setSongs(fetchedSongs);

//       if (provider.lastListenedSongId != null) {
//         provider.setClickedIndex(fetchedSongs
//             .indexWhere((song) => song.songId == provider.lastListenedSongId));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<SongProvider, SongListItemProvider>(
//       builder: (context, songProvider, listProvider, child) {
//         List<Song> displayedSongs = listProvider.filteredSongs;
//         displayedSongs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

//         return ListView.builder(
//           itemCount: displayedSongs.length,
//           itemBuilder: (context, index) {
//             int reversedIndex = displayedSongs.length - 1 - index;
//             int ascendingIndex = index;

//             // Set the indices in provider
//             listProvider.setIndices(reversedIndex, ascendingIndex);

//             return SongListItem(); // No need to pass indices anymore
//           },
//         );
//       },
//     );
//   }
// }

// class SongListItem extends StatefulWidget {
//   const SongListItem({super.key});

//   @override
//   _SongListItemState createState() => _SongListItemState();
// }

// class _SongListItemState extends State<SongListItem> {
//   SongProvider? songProvider;
//   bool _isHovering = false;

//   void _handleHoverChange(bool isHovering) {
//     if (_isHovering != isHovering) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           setState(() {
//             _isHovering = isHovering;
//           });
//         }
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       songProvider = Provider.of<SongProvider>(context, listen: false);

//       final listProvider =
//           Provider.of<SongListItemProvider>(context, listen: false);
//       final song = listProvider.filteredSongs[listProvider.originalIndex];

//       if (song.songId == listProvider.lastListenedSongId) {
//         _playSelectedSong();

//         Provider.of<LikeProvider>(context, listen: false)
//             .checkIfLiked(song.songId);
//       }
//     });
//   }

//   void _playSelectedSong() async {
//     final listProvider =
//         Provider.of<SongListItemProvider>(context, listen: false);
//     final song = listProvider.filteredSongs[listProvider.originalIndex];

//     if (songProvider?.songId == song.songId && songProvider!.isPlaying) {
//       songProvider!.pauseOrResume();
//     } else {
//       songProvider!.stop();
//       songProvider!.setSong(
//         song.songId,
//         song.senderId,
//         song.artistId,
//         song.songTitle,
//         song.profileImageUrl,
//         song.songImageUrl,
//         song.bioImageUrl,
//         song.artistName,
//         song.songUrl,
//         song.songDuration,
//         listProvider.currentIndex, // Changed from widget.index
//       );
//       if (!mounted) return;
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Consumer<SongListItemProvider>(
//       builder: (context, listProvider, child) {
//         final song = listProvider.filteredSongs[listProvider.originalIndex];
//         final isClicked =
//             listProvider.clickedIndex == listProvider.currentIndex;
//         final formattedDuration = _formatDuration(song.songDuration);
//         final formattedDate = DateFormat('MMM d, yyyy').format(song.timestamp);

//         return MouseRegion(
//           onEnter: (_) => _handleHoverChange(true),
//           onExit: (_) => _handleHoverChange(false),
//           child: GestureDetector(
//             onTap: () => _handleSongTap(listProvider),
//             child: _buildSongListItem(screenWidth, song, isClicked,
//                 formattedDuration, formattedDate, listProvider),
//           ),
//         );
//       },
//     );
//   }

//   void _handleSongTap(SongListItemProvider listProvider) {
//     listProvider.setClickedIndex(listProvider.currentIndex);
//     listProvider.setLastListenedSongId(
//         listProvider.filteredSongs[listProvider.originalIndex].songId);
//     _playSelectedSong();
//     songProvider?.setShouldPlay(true);

//     if (!mounted) return;
//     Provider.of<WidgetStateProvider2>(context, listen: false)
//         .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
//   }

//   Widget _buildSongListItem(
//     double screenWidth,
//     Song song,
//     bool isClicked,
//     String formattedDuration,
//     String formattedDate,
//     SongListItemProvider listProvider,
//   ) {
//     return Container(
//       color: isClicked
//           ? primaryTextColor.withOpacity(0.1)
//           : (_isHovering
//               ? primaryTextColor.withOpacity(0.1)
//               : Colors.transparent),
//       child: Table(
//         border: TableBorder.all(
//           color: transparentColor,
//           width: 1,
//         ),
//         columnWidths: _getColumnWidths(screenWidth),
//         children: [
//           TableRow(
//             children: [
//               _buildIndexNumber(listProvider),
//               _buildSongInfo(screenWidth, song),
//               if (screenWidth > 1280)
//                 _buildAlbumName(screenWidth, song)
//               else
//                 const SizedBox.shrink(),
//               if (screenWidth > 1480)
//                 _buildDate(formattedDate)
//               else
//                 const SizedBox.shrink(),
//               _buildControls(formattedDuration, song, isClicked, listProvider),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Map<int, TableColumnWidth> _getColumnWidths(double screenWidth) {
//     return {
//       0: const FixedColumnWidth(50),
//       1: FlexColumnWidth(2),
//       2: screenWidth > 1280
//           ? const FlexColumnWidth(2)
//           : const FixedColumnWidth(0),
//       3: screenWidth > 1480
//           ? const FlexColumnWidth(2)
//           : const FixedColumnWidth(0),
//       4: const FixedColumnWidth(168),
//     };
//   }

//   Widget _buildIndexNumber(SongListItemProvider listProvider) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
//       decoration: BoxDecoration(
//         border: Border.all(color: transparentColor),
//       ),
//       child: SizedBox(
//         width: 35,
//         child: Text(
//           listProvider.originalIndex + 1 >= 1000
//               ? "𝅗𝅥"
//               : '${listProvider.originalIndex + 1}',
//           textAlign: TextAlign.right,
//           style: const TextStyle(
//             color: primaryTextColor,
//             fontWeight: mediumWeight,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSongInfo(double screenWidth, song) {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       decoration: BoxDecoration(
//         border: Border.all(color: transparentColor),
//       ),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: SizedBox(
//               height: 50,
//               width: 50,
//               child: song.songImageUrl.isNotEmpty
//                   ? (Uri.tryParse(song.songImageUrl)?.hasAbsolutePath ?? false
//                       ? Image.file(
//                           File(song.songImageUrl),
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) =>
//                               Container(
//                             color: Colors.grey,
//                             child: const Icon(Icons.broken_image,
//                                 color: Colors.white),
//                           ),
//                         )
//                       : Container(
//                           color: Colors.grey,
//                           child: const Icon(Icons.broken_image,
//                               color: Colors.white),
//                         ))
//                   : const SizedBox.shrink(),
//             ),
//           ),
//           const SizedBox(width: 10),
//           SizedBox(
//             width: screenWidth * 0.1,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   song.songTitle,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: primaryTextColor,
//                     fontWeight: mediumWeight,
//                     fontSize: smallFontSize,
//                   ),
//                 ),
//                 Text(
//                   song.artistName ?? '',
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: quaternaryTextColor,
//                     fontWeight: mediumWeight,
//                     fontSize: microFontSize,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAlbumName(double screenWidth, song) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
//       decoration: BoxDecoration(
//         border: Border.all(color: transparentColor),
//       ),
//       child: SizedBox(
//         width: screenWidth * 0.125,
//         child: IntrinsicWidth(
//           child: RichText(
//             text: TextSpan(
//               text: song.albumName ?? '',
//               style: const TextStyle(
//                 color: primaryTextColor,
//                 fontWeight: mediumWeight,
//               ),
//               recognizer: TapGestureRecognizer()
//                 ..onTap = () {
//                   Provider.of<WidgetStateProvider1>(context, listen: false)
//                       .changeWidget(
//                     AlbumContainer(albumId: song.albumId),
//                     'Album Container',
//                   );
//                 },
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDate(String formattedDate) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 23),
//       decoration: BoxDecoration(
//         border: Border.all(color: transparentColor),
//       ),
//       child: SizedBox(
//         width: 82,
//         child: Text(
//           formattedDate,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             color: primaryTextColor,
//             fontWeight: mediumWeight,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildControls(String formattedDuration, song, bool isClicked,
//       SongListItemProvider listProvider) {
//     final likeProvider = Provider.of<LikeProvider>(context);
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       decoration: BoxDecoration(
//         border: Border.all(color: transparentColor),
//       ),
//       child: MouseRegion(
//         onEnter: (_) => setState(() => _isHovering = true),
//         onExit: (_) => setState(() => _isHovering = false),
//         child: SizedBox(
//           height: 66,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (isClicked || _isHovering)
//                 SizedBox(
//                   width: 45,
//                   child: GestureDetector(
//                     child: Icon(
//                       likeProvider.isLiked
//                           ? Icons.favorite
//                           : Icons.favorite_border,
//                       color: likeProvider.isLiked ? secondaryColor : primaryTextColor,
//                       size: smallFontSize,
//                     ),
//                     onTap: () async {
//                       await likeProvider.toggleLike(song.songId);
//                     },
//                   ),
//                 )
//               else
//                 const SizedBox(width: 45),
//               const SizedBox(width: 15),
//               SizedBox(
//                 width: 45,
//                 child: Text(
//                   formattedDuration,
//                   style: const TextStyle(
//                     color: primaryTextColor,
//                     fontWeight: mediumWeight,
//                   ),
//                 ),
//               ),
//               HoverIconsWidget(
//                 isClicked: isClicked,
//                 onItemTapped: (index) {
//                   Provider.of<WidgetStateProvider2>(context, listen: false)
//                       .changeWidget(
//                     SongMenu(
//                       onChangeWidget: (Widget) {},
//                       songId: song.songId,
//                       songUrl: song.songUrl,
//                       songImageUrl: song.songImageUrl,
//                       artistId: song.artistId,
//                       artistName: song.artistName,
//                       albumId: song.albumId,
//                       artistSongIndex: song.artistSongIndex,
//                       songTitle: song.songTitle,
//                       songDuration: song.songDuration,
//                       originalIndex: listProvider
//                           .originalIndex, // Changed from widget.originalIndex
//                       likedIds: song.likeIds,
//                     ),
//                     'SongMenu',
//                   );
//                 },
//                 index: listProvider
//                     .currentIndex, // Changed from listProvider.index
//                 isHoveringParent: _isHovering,
//                 onHoverChange: _handleHoverChange,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     String minutes = twoDigits(duration.inMinutes.remainder(60));
//     String seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
// }
