import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/provider/playlist_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/bottom_container.dart';
import 'package:soundify/view/container/primary/add_song_container.dart';
import 'package:soundify/view/container/primary/home_container.dart';
import 'package:soundify/view/container/primary/liked_song_container.dart';
import 'package:soundify/view/container/primary/playlist_container.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/splash_screen.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/play_list.dart';
import 'package:soundify/view/widget/song_list.dart';
import 'package:uuid/uuid.dart';

class MainPage extends StatefulWidget {
  final activeWidget1;
  final activeWidget2;
  const MainPage(
      {super.key, required this.activeWidget1, required this.activeWidget2});

  @override
  State<MainPage> createState() => _MainPageState();
}

bool showModal = false;

late Widget activeWidget1;
late Widget activeWidget2;

bool isSearch = true;
FocusNode searchFocusNode = FocusNode();

final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

class _MainPageState extends State<MainPage> {
  bool _isHoveredSearch = false;

  @override
  void initState() {
    super.initState();
    // _getUserId(); // Dapatkan userId saat widget diinisialisasi
    fetchPlaylists();
  }

  Future<void> fetchPlaylists() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get current user from SQLite
      final user = await DatabaseHelper.instance.getCurrentUser();
      print("User ID: ${user?.userId}"); // Print User ID to ensure its value

      if (user == null) {
        print("User tidak ditemukan. Gagal menambahkan playlist.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan playlist: User tidak ditemukan'),
          ),
        );
        return;
      }

      // Query playlists by creatorId
      final creatorPlaylists = await db.query(
        'playlists',
        where: 'creatorId = ?',
        whereArgs: [user.userId],
      );
      print("Creator Playlists: ${creatorPlaylists.length}");

      // Query liked playlists
      final likedPlaylists = await db.query(
        'playlists',
        where: 'playlistLikeIds LIKE ?',
        whereArgs: ['%${user.userId}%'],
      );
      print("Liked Playlists: ${likedPlaylists.length}");

      if (mounted) {
        final Set<String> playlistIds = {};
        final List<Map<String, dynamic>> combinedPlaylists = [];

        // Cache to store fetched usernames to avoid duplicate queries
        Map<String, String?> userNameCache = {};

        // Function to fetch username and cache it
        Future<String> fetchUserName(String creatorId) async {
          if (userNameCache.containsKey(creatorId)) {
            return userNameCache[creatorId] ?? 'Creator name not found';
          }

          // Fetch username from SQLite
          final creator = await DatabaseHelper.instance.getUserById(creatorId);
          final creatorName = creator?.fullName ?? 'Creator name not found';
          userNameCache[creatorId] = creatorName;
          return creatorName;
        }

        // Process and combine creator playlists
        for (var playlist in creatorPlaylists) {
          final playlistId = (playlist['playlistId'] ?? '').toString();
          if (!playlistIds.contains(playlistId)) {
            playlistIds.add(playlistId);

            final creatorId = (playlist['creatorId'] ?? '').toString();
            final creatorName = await fetchUserName(creatorId);

            combinedPlaylists.add({
              'creatorId': creatorId,
              'creatorName': creatorName,
              'playlistId': playlistId,
              'playlistName': (playlist['playlistName'] ?? '').toString(),
              'playlistDescription':
                  (playlist['playlistDescription'] ?? '').toString(),
              'playlistImageUrl':
                  (playlist['playlistImageUrl'] ?? '').toString(),
              'timestamp':
                  DateTime.parse((playlist['timestamp'] ?? '').toString()),
              'playlistUserIndex': playlist['playlistUserIndex'] ?? 0,
              'songListIds': playlist['songListIds'] != null
                  ? (playlist['songListIds'] as String).split(',')
                  : [],
              'totalDuration': playlist['totalDuration'] is int
                  ? Duration(seconds: playlist['totalDuration'] as int)
                  : (playlist['totalDuration'] as Duration?) ?? Duration.zero,
            });
          }
        }

        // Process and combine liked playlists, avoiding duplicates
        for (var playlist in likedPlaylists) {
          final playlistId = (playlist['playlistId'] ?? '').toString();
          if (!playlistIds.contains(playlistId)) {
            playlistIds.add(playlistId);

            final creatorId = (playlist['creatorId'] ?? '').toString();
            final creatorName = await fetchUserName(creatorId);

            combinedPlaylists.add({
              'creatorId': creatorId,
              'creatorName': creatorName,
              'playlistId': playlistId,
              'playlistName': (playlist['playlistName'] ?? '').toString(),
              'playlistDescription':
                  (playlist['playlistDescription'] ?? '').toString(),
              'playlistImageUrl':
                  (playlist['playlistImageUrl'] ?? '').toString(),
              'timestamp':
                  DateTime.parse((playlist['timestamp'] ?? '').toString()),
              'playlistUserIndex': playlist['playlistUserIndex'] ?? 0,
              'songListIds': playlist['songListIds'] != null
                  ? (playlist['songListIds'] as String).split(',')
                  : [],
              'totalDuration': playlist['totalDuration'] is int
                  ? Duration(seconds: playlist['totalDuration'] as int)
                  : (playlist['totalDuration'] as Duration?) ?? Duration.zero,
            });
          }
        }

        print(
            "Combined Playlists (after deduplication): ${combinedPlaylists.length}");

        // Sort playlists by playlistUserIndex in descending order
        combinedPlaylists.sort(
            (a, b) => b['playlistUserIndex'].compareTo(a['playlistUserIndex']));

        // Update StreamController with the combined and deduplicated playlists
        _playlistsController.add(combinedPlaylists);
      }
    } catch (error) {
      print("Error fetching playlists from SQLite: $error");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentWidgetName =
        Provider.of<WidgetStateProvider1>(context, listen: true).widgetName;
    setState(() {
      isSearch = currentWidgetName == "HomeContainer";
    });
  }

  void navigateToHomeContainer() {
    if (!isSearch) {
      Provider.of<WidgetStateProvider1>(context, listen: false).changeWidget(
        const HomeContainer(),
        'HomeContainer',
      );
      setState(() {
        activeWidget2 = const ShowDetailSong();
        isSearch = true;
      });
    }
  }

  Future<void> _logout() async {
    // Assuming you have a method in your DatabaseHelper to clear the current session
    await DatabaseHelper.instance
        .clearSession(); // Clear the user session in SQLite

    // Navigate to the SplashScreen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (Route<dynamic> route) => false, // Remove all routes from the stack
    );
  }

  OverlayEntry? _overlayEntry;
  void _showModal(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // GestureDetector untuk mendeteksi klik di luar area modal
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _closeModal(); // Tutup modal jika area luar modal diklik
              },
              child: Container(
                color: Colors.transparent, // Area di luar modal transparan
              ),
            ),
          ),
          Positioned(
            left: 12, // Posisi modal container
            top: 120, // Posisi modal container
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  color: tertiaryColor, // Background container
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IntrinsicWidth(
                      child: TextButton(
                        onPressed: () async {
                          // Panggil fungsi untuk menyimpan data playlist
                          await _submitPlaylistData(context);

                          // Ambil playlist terbaru dari SQLite
                          var latestPlaylist;
                          try {
                            // Mengambil semua playlist dari SQLite dan mencari yang terbaru
                            final playlists =
                                await DatabaseHelper.instance.getPlaylists();
                            if (playlists.isNotEmpty) {
                              playlists.sort((a, b) => b.playlistUserIndex
                                  .compareTo(a
                                      .playlistUserIndex)); // Urutkan descending
                              latestPlaylist =
                                  playlists.first; // Ambil playlist terbaru
                            }
                          } catch (error) {
                            print("Error fetching playlist: $error");
                          }

                          if (latestPlaylist != null) {
                            setState(() {
                              Provider.of<PlaylistProvider>(context,
                                      listen: false)
                                  .updatePlaylistProvider(
                                latestPlaylist.playlistId ?? '',
                                latestPlaylist.creatorId ?? '',
                                latestPlaylist.playlistName ??
                                    'Untitled Playlist',
                                latestPlaylist.playlistDescription ?? '',
                                latestPlaylist.playlistImageUrl ?? '',
                                latestPlaylist
                                    .timestamp, // gunakan timestamp dari SQLite
                                latestPlaylist.playlistUserIndex,
                                latestPlaylist.songListIds,
                                latestPlaylist.playlistLikeIds,
                                latestPlaylist.totalDuration ?? Duration.zero,
                              );

                              activeWidget2 = const ShowDetailSong();
                            });
                          }

                          Provider.of<WidgetStateProvider1>(context,
                                  listen: false)
                              .changeWidget(
                            PlaylistContainer(
                                playlistId: latestPlaylist['playlistId']),
                            'PlaylistContainer',
                          );

                          // Tutup modal setelah tindakan selesai
                          _closeModal();
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.playlist_add,
                              color: primaryTextColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Create Playlist",
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: smallFontSize),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicWidth(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            Provider.of<WidgetStateProvider1>(context,
                                    listen: false)
                                .changeWidget(
                              AddSongContainer(
                                onChangeWidget: (newWidget) {
                                  setState(() {
                                    activeWidget2 =
                                        newWidget; // Ganti widget aktif
                                  });
                                },
                              ),
                              'Add Song Container',
                            );

                            // activeWidget2 = const ShowDetailSong();
                          });
                          _closeModal(); // Tutup modal setelah action
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add,
                              color: primaryTextColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Add Song",
                              style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!); // Tampilkan overlay
  }

  void _closeModal() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove(); // Hapus overlay
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: secondaryTextColor,
        body: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 10.0, bottom: 18.0),
                            child: TextButton(
                              onPressed: () {
                                setState(
                                  () {
                                    Provider.of<WidgetStateProvider1>(context,
                                            listen: false)
                                        .changeWidget(
                                      const HomeContainer(),
                                      'Home Container',
                                    );

                                    activeWidget2 = const ShowDetailSong();
                                  },
                                );
                              },
                              child: const Text(
                                "Soundify",
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(
                                      20), // Sudut melengkung
                                ),
                                width: 155,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 12.0,
                                            right: 12.0,
                                            top: 10,
                                            bottom: 3.0),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  showModal =
                                                      true; // Menampilkan modal container
                                                });
                                                _showModal(
                                                    context); // Pastikan fungsi dipanggil
                                              },
                                              child: const Text(
                                                'Menu',
                                                style: TextStyle(
                                                  color: primaryTextColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  showModal =
                                                      true; // Menampilkan modal container
                                                });
                                                _showModal(
                                                    context); // Pastikan fungsi dipanggil
                                              },
                                              child: const Icon(
                                                Icons.add,
                                                color: primaryTextColor,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Divider(
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: Container(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(
                                                        () {
                                                          Provider.of<WidgetStateProvider1>(
                                                                  context,
                                                                  listen: false)
                                                              .changeWidget(
                                                            const LikedSongContainer(),
                                                            'Liked Song Container',
                                                          );

                                                          activeWidget2 =
                                                              const ShowDetailSong();
                                                        },
                                                      );
                                                    },
                                                    child: Container(
                                                      height: 40,
                                                      color: primaryColor,
                                                      child: Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            child: Container(
                                                              width: 35,
                                                              height: 35,
                                                              color:
                                                                  secondaryColor,
                                                              child: Icon(
                                                                Icons.favorite,
                                                                color:
                                                                    primaryColor,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          const Text(
                                                            'Liked Songs',
                                                            style: TextStyle(
                                                              color:
                                                                  primaryTextColor,
                                                              fontSize:
                                                                  smallFontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                                  child: StreamBuilder<
                                                      List<
                                                          Map<String,
                                                              dynamic>>>(
                                                    stream: _playlistsController
                                                        .stream,
                                                    builder:
                                                        (context, snapshot) {
                                                      if (!snapshot.hasData) {
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color:
                                                                primaryTextColor,
                                                          ), // Spi,
                                                        );
                                                      }

                                                      final playlists =
                                                          snapshot.data!;

                                                      return ListView.builder(
                                                        shrinkWrap:
                                                            true, // Prevent ListView from expanding indefinitely
                                                        physics:
                                                            const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
                                                        itemCount:
                                                            playlists.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final playlist =
                                                              playlists[index];

                                                          // Wrap PlayList widget with GestureDetector or InkWell for handling tap
                                                          return GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                Provider.of<PlaylistProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .updatePlaylistProvider(
                                                                  playlist[
                                                                      'playlistId'],
                                                                  playlist[
                                                                      'creatorId'],
                                                                  playlist[
                                                                      'playlistName'],
                                                                  playlist[
                                                                      'playlistDescription'],
                                                                  playlist[
                                                                      'playlistImageUrl'],
                                                                  playlist[
                                                                      'timestamp'],
                                                                  playlist[
                                                                      'playlistUserIndex'],
                                                                  playlist[
                                                                      'songListIds'],
                                                                  playlist[
                                                                      'playlistLikeIds'],
                                                                  playlist[
                                                                      'totalDuration'],
                                                                );
                                                              });

                                                              Provider.of<WidgetStateProvider1>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .changeWidget(
                                                                PlaylistContainer(
                                                                  playlistId:
                                                                      playlist[
                                                                          'playlistId'],
                                                                ),
                                                                'PlaylistContainer',
                                                              );
                                                            },
                                                            child: PlayList(
                                                              playlistImageUrl:
                                                                  playlist[
                                                                      'playlistImageUrl'],
                                                              playlistName:
                                                                  playlist[
                                                                      'playlistName'],
                                                              creatorName: playlist[
                                                                  'creatorName'],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MouseRegion(
                                  onEnter: (event) => setState(() {
                                    _isHoveredSearch = true;
                                  }),
                                  onExit: (event) => setState(() {
                                    _isHoveredSearch = false;
                                  }),
                                  child: TextFormField(
                                    controller: searchListController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(8),
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(
                                            left: 12.0, right: 8.0),
                                        child: Icon(Icons.search,
                                            color: primaryTextColor),
                                      ),
                                      hintText: 'What do you want to play?',
                                      hintStyle: const TextStyle(
                                          color: primaryTextColor),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30)),
                                        borderSide:
                                            BorderSide(color: secondaryColor),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30)),
                                        borderSide:
                                            BorderSide(color: secondaryColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(30)),
                                        borderSide: BorderSide(
                                          color: _isHoveredSearch
                                              ? secondaryColor
                                              : primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    onTap: navigateToHomeContainer,
                                    onChanged: (value) {
                                      // Ensure we're on the search list when typing
                                      navigateToHomeContainer();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                backgroundColor:
                                    primaryTextColor, // Warna latar belakang
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      Provider.of<WidgetStateProvider1>(context,
                                              listen: false)
                                          .changeWidget(
                                        const HomeContainer(),
                                        'Home Container',
                                      );

                                      activeWidget2 = const ShowDetailSong();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.home,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Material(
                                shape: const CircleBorder(), // Bentuk lingkaran
                                color: Colors
                                    .transparent, // Atur background ke transparent agar hanya efek klik yang terlihat
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors
                                          .transparent, // Latar belakang tidak gelap
                                      builder: (BuildContext context) {
                                        return Stack(
                                          children: [
                                            Positioned(
                                              top: 73, // Jarak dari atas layar
                                              right:
                                                  14, // Jarak dari ujung kanan
                                              child: Material(
                                                color: Colors
                                                    .transparent, // Transparan agar decoration terlihat
                                                child: IntrinsicWidth(
                                                  // Menjaga ukuran popup sesuai konten
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20),
                                                    decoration: BoxDecoration(
                                                      color: tertiaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16), // Membuat ujung melengkung
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors
                                                              .black26, // Warna shadow
                                                          blurRadius:
                                                              10, // Ukuran blur shadow
                                                          offset: Offset(0,
                                                              4), // Posisi shadow
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(
                                                              () {
                                                                // Provider.of<WidgetStateProvider1>(
                                                                //         context,
                                                                //         listen:
                                                                //             false)
                                                                //     .changeWidget(
                                                                //   PersonalProfileContainer(
                                                                //     userId:
                                                                //         currentUser!
                                                                //             .uid,
                                                                //   ),
                                                                //   'Profile Container',
                                                                // );

                                                                // activeWidget2 =
                                                                //     const ShowDetailSong();
                                                              },
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Profile',
                                                            style: TextStyle(
                                                              color:
                                                                  primaryTextColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const Divider(
                                                          color:
                                                              primaryTextColor,
                                                        ),
                                                        TextButton(
                                                          onPressed: _logout,
                                                          child: const Text(
                                                            "Log Out",
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .redAccent, // Sesuaikan warna teks
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: primaryTextColor,
                                      // (_profileImageUrl == null ||
                                      //         _profileImageUrl!.isEmpty)
                                      //     ? primaryTextColor
                                      //     : quaternaryColor,
                                      // backgroundImage: (_profileImageUrl !=
                                      //             null &&
                                      //         _profileImageUrl!.isNotEmpty)
                                      //     ? NetworkImage(_profileImageUrl!)
                                      //     : null, // Tampilkan NetworkImage jika profileImageUrl tersedia
                                      child: Icon(
                                        Icons.person,
                                        color: quaternaryColor,
                                      )
                                      // (_profileImageUrl == null ||
                                      //         _profileImageUrl!.isEmpty)
                                      //     ? Icon(
                                      //         Icons.person,
                                      //         color: quaternaryColor,
                                      //       ) // Tampilkan icon jika tidak ada gambar
                                      //     : null,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 2.0, right: 2.0, top: 12, bottom: 0),
                              child: Row(
                                children: [
                                  // Kontainer pertama
                                  Expanded(
                                    flex:
                                        2, // Kontainer pertama menggunakan 2/3 ruang
                                    child: LayoutBuilder(
                                      builder: (BuildContext context,
                                          BoxConstraints constraints) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          Provider.of<WidgetSizeProvider>(
                                                  context,
                                                  listen: false)
                                              .updateExpandedWidth(
                                                  constraints.maxWidth);
                                        });

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(
                                                20), // Membuat sudut melengkung
                                          ),
                                          child: Consumer2<WidgetSizeProvider,
                                              WidgetStateProvider1>(
                                            builder: (context,
                                                widgetSizeProvider,
                                                widgetStateProvider,
                                                child) {
                                              // Mengambil currentWidget setiap kali state berubah
                                              Widget activeWidget1 =
                                                  widgetStateProvider
                                                      .currentWidget;

                                              // You can use widgetSizeProvider.expandedWidth here if needed

                                              return activeWidget1;
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Kontainer kedua akan dihilangkan jika resolusi lebih kecil dari iPad
                                  if (MediaQuery.of(context).size.width >=
                                      800) ...[
                                    const SizedBox(width: 12),
                                    Flexible(
                                      flex: MediaQuery.of(context).size.width <=
                                              1300
                                          ? 1
                                          : 0, // Menggunakan flex 1 jika lebar layar <= 1000
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          maxWidth:
                                              370, // Atur max lebar kontainer kedua
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(
                                              20), // Membuat sudut melengkung
                                        ),
                                        child: Consumer<WidgetStateProvider2>(
                                          builder: (context,
                                              widgetStateProvider, child) {
                                            // Mengambil currentWidget setiap kali state berubah
                                            Widget activeWidget2 =
                                                widgetStateProvider
                                                    .currentWidget;
                                            return activeWidget2;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Container baru yang berada di bagian paling bawah
            Container(
              width: double.infinity,
              height: 70,
              color: quaternaryColor, // Warna container
              child: const Center(
                child: BottomContainer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final StreamController<List<Map<String, dynamic>>> _playlistsController =
      StreamController();

  Future<void> _submitPlaylistData(BuildContext context) async {
    try {
      // Dapatkan pengguna saat ini dari SQLite
      final user = await DatabaseHelper.instance.getCurrentUser();

      if (user == null) {
        print("User tidak ditemukan. Gagal menambahkan playlist.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan playlist: User tidak ditemukan'),
          ),
        );
        return;
      }

      // Ambil instance database SQLite
      final db = await DatabaseHelper.instance.database;

      // Ambil jumlah playlist yang ada di SQLite untuk menghitung `playlistUserIndex`
      final List<Map<String, dynamic>> existingPlaylists = await db.query(
        'playlists',
        where: 'creatorId = ?',
        whereArgs: [user.userId],
      );

      int playlistUserIndex = existingPlaylists.length + 1;

      final playlistId = Uuid().v4();

      // Buat objek Playlist baru
      final newPlaylist = Playlist(
        playlistId: playlistId, // Menggunakan UUID sebagai playlistId
        creatorId: user.userId,
        playlistName: "Playlist #$playlistUserIndex",
        playlistDescription: "",
        playlistImageUrl: "",
        timestamp: DateTime.now(),
        playlistUserIndex: playlistUserIndex,
        songListIds: [],
        playlistLikeIds: [],
        totalDuration: Duration.zero,
      );

      // Simpan playlist di SQLite
      await DatabaseHelper.instance.insertPlaylist(newPlaylist);

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist berhasil ditambahkan!')),
      );
    } catch (e) {
      print('Error submitting playlist data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan playlist: $e')),
      );
    }
  }
}
