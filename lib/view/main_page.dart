import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/bottom_container.dart';
import 'package:soundify/view/container/primary/add_song_container.dart';
import 'package:soundify/view/splash_screen.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  // final activeWidget1;
  // final activeWidget2;
  // const MainPage(
  //     {super.key, required this.activeWidget1, required this.activeWidget2});
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

bool showModal = false;

// final currentUser = FirebaseAuth.instance.currentUser;

late Widget activeWidget1;
late Widget activeWidget2;

bool isSearch = true;
FocusNode searchFocusNode = FocusNode();

class _MainPageState extends State<MainPage> {
  // String? _profileImageUrl; // Variabel untuk menyimpan URL gambar profil
  // String? _userId; // Variabel untuk menyimpan userId dari currentUser
  // // Pindahkan activeWidget1 dan activeWidget2 ke dalam State

  // @override
  // void initState() {
  //   super.initState();
  //   _getUserId(); // Dapatkan userId saat widget diinisialisasi
  //   fetchPlaylists();
  // }

  // Future<void> fetchPlaylists() async {
  //   final creatorPlaylistsQuery = FirebaseFirestore.instance
  //       .collection('playlists')
  //       .where(
  //         'creatorId',
  //         isEqualTo: currentUser?.uid,
  //       )
  //       .get();

  //   final likedPlaylistsQuery = FirebaseFirestore.instance
  //       .collection('playlists')
  //       .where(
  //         'playlistLikeIds',
  //         arrayContains: currentUser?.uid,
  //       )
  //       .get();

  //   // Jalankan kedua query secara bersamaan
  //   final results =
  //       await Future.wait([creatorPlaylistsQuery, likedPlaylistsQuery]);

  //   if (mounted) {
  //     final creatorPlaylists = results[0].docs;
  //     final likedPlaylists = results[1].docs;

  //     // Set untuk menyimpan playlistId yang sudah dimasukkan agar tidak duplikat
  //     final Set<String> playlistIds = {};

  //     final List<Map<String, dynamic>> combinedPlaylists = [];

  //     // Tambahkan playlists dari creatorPlaylistsQuery
  //     for (var doc in creatorPlaylists) {
  //       final playlistId = doc['playlistId'] ?? '';
  //       if (!playlistIds.contains(playlistId)) {
  //         playlistIds.add(playlistId);
  //         combinedPlaylists.add({
  //           'creatorId': doc['creatorId'] ?? '',
  //           'playlistId': playlistId,
  //           'playlistName': doc['playlistName'] ?? '',
  //           'playlistDescription': doc['playlistDescription'] ?? '',
  //           'playlistImageUrl': doc['playlistImageUrl'] ?? '',
  //           'timestamp':
  //               (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  //           'playlistUserIndex': doc['playlistUserIndex'] ?? 0,
  //           'songListIds': doc['songListIds'] ?? [],
  //           'totalDuration': doc['totalDuration'] ?? 0,
  //         });
  //       }
  //     }

  //     // Tambahkan playlists dari likedPlaylistsQuery, cek duplikat playlistId
  //     for (var doc in likedPlaylists) {
  //       final playlistId = doc['playlistId'] ?? '';
  //       if (!playlistIds.contains(playlistId)) {
  //         playlistIds.add(playlistId);
  //         combinedPlaylists.add({
  //           'creatorId': doc['creatorId'] ?? '',
  //           'playlistId': playlistId,
  //           'playlistName': doc['playlistName'] ?? '',
  //           'playlistDescription': doc['playlistDescription'] ?? '',
  //           'playlistImageUrl': doc['playlistImageUrl'] ?? '',
  //           'timestamp':
  //               (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  //           'playlistUserIndex': doc['playlistUserIndex'] ?? 0,
  //           'songListIds': doc['songListIds'] ?? [],
  //           'totalDuration': doc['totalDuration'] ?? 0,
  //         });
  //       }
  //     }

  //     // Sort by playlistUserIndex
  //     combinedPlaylists.sort(
  //         (a, b) => b['playlistUserIndex'].compareTo(a['playlistUserIndex']));

  //     // Update StreamController dengan playlist yang sudah digabung dan bebas duplikat
  //     _playlistsController.add(combinedPlaylists);
  //   }
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final currentWidgetName =
  //       Provider.of<WidgetStateProvider1>(context, listen: true).widgetName;
  //   setState(() {
  //     isSearch = currentWidgetName == "HomeContainer";
  //   });
  // }

  // void navigateToHomeContainer() {
  //   if (!isSearch) {
  //     Provider.of<WidgetStateProvider1>(context, listen: false).changeWidget(
  //       const HomeContainer(),
  //       'HomeContainer',
  //     );
  //     setState(() {
  //       activeWidget2 = const ShowDetailSong();
  //       isSearch = true;
  //     });
  //   }
  // }

  // // Fungsi untuk mendapatkan userId dari FirebaseAuth
  // void _getUserId() {
  //   User? currentUser =
  //       FirebaseAuth.instance.currentUser; // Ambil pengguna yang sedang login
  //   if (currentUser != null) {
  //     setState(() {
  //       _userId = currentUser.uid; // Dapatkan userId dari currentUser
  //       _getProfileImageUrl(); // Setelah mendapatkan userId, ambil profileImageUrl
  //     });
  //   }
  // }

  // // Fungsi untuk mendapatkan profileImageUrl dari Firestore
  // void _getProfileImageUrl() {
  //   if (_userId != null) {
  //     FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(_userId)
  //         .snapshots()
  //         .listen((snapshot) {
  //       if (snapshot.exists && snapshot.data() != null) {
  //         setState(() {
  //           _profileImageUrl = snapshot.get('profileImageUrl');
  //         });
  //       } else {
  //         setState(() {
  //           _profileImageUrl = null;
  //         });
  //       }
  //     });
  //   }
  // }

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
                width: 155, // Atur lebar container
                height: 90, // Atur tinggi container
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
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 200,
                      child: TextButton(
                        onPressed: () async {
                          // // Panggil fungsi untuk menyimpan data playlist
                          // await _submitPlaylistData(context);
                          // // Fetch the latest playlist
                          // var latestPlaylist;
                          // try {
                          //   final playlistSnapshot = await FirebaseFirestore
                          //       .instance
                          //       .collection('playlists')
                          //       .orderBy('playlistUserIndex', descending: true)
                          //       .limit(1)
                          //       .get();

                          //   if (playlistSnapshot.docs.isNotEmpty) {
                          //     latestPlaylist =
                          //         playlistSnapshot.docs.first.data();
                          //   }
                          // } catch (error) {
                          //   print("Error fetching playlist: $error");
                          // }
                          // if (latestPlaylist != null) {
                          //   var timestamp;
                          //   if (latestPlaylist['timestamp'] != null &&
                          //       latestPlaylist['timestamp'] is Timestamp) {
                          //     timestamp =
                          //         (latestPlaylist['timestamp'] as Timestamp)
                          //             .toDate();
                          //   } else {
                          //     timestamp = DateTime
                          //         .now(); // fallback jika timestamp null atau bukan tipe Timestamp
                          //   }

                          //   setState(() {
                          //     Provider.of<PlaylistProvider>(context,
                          //             listen: false)
                          //         .updatePlaylist(
                          //       latestPlaylist['playlistImageUrl'] ?? '',
                          //       latestPlaylist['playlistName'] ??
                          //           'Untitled Playlist',
                          //       latestPlaylist['playlistDescription'] ?? '',
                          //       latestPlaylist['creatorId'] ?? '',

                          //       latestPlaylist['playlistId'] ?? '',
                          //       timestamp, // gunakan timestamp yang telah diperiksa
                          //       latestPlaylist['playlistUserIndex'] ?? 0,
                          //       latestPlaylist['songListIds'] ?? [],
                          //       latestPlaylist['totalDuration'] ?? 0,
                          //     );

                          //     Provider.of<WidgetStateProvider1>(context,
                          //             listen: false)
                          //         .changeWidget(
                          //       PlaylistContainer(
                          //           playlistId: latestPlaylist['playlistId']),
                          //       'PlaylistContainer',
                          //     );

                          //     activeWidget2 = const ShowDetailSong();
                          //   });
                          // }

                          // // Close modal after action
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
                                fontSize: microFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
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
                                // setState(
                                //   () {
                                //     Provider.of<WidgetStateProvider1>(context,
                                //             listen: false)
                                //         .changeWidget(
                                //       const HomeContainer(),
                                //       'Home Container',
                                //     );

                                //     activeWidget2 = const ShowDetailSong();
                                //   },
                                // );
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
                                                // setState(() {
                                                //   showModal =
                                                //       true; // Menampilkan modal container
                                                // });
                                                // _showModal(
                                                //     context); // Pastikan fungsi dipanggil
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
                                                          // Provider.of<WidgetStateProvider1>(
                                                          //         context,
                                                          //         listen: false)
                                                          //     .changeWidget(
                                                          //   const LikedSongContainer(),
                                                          //   'Liked Song Container',
                                                          // );

                                                          // activeWidget2 =
                                                          //     const ShowDetailSong();
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
                                                // Padding(
                                                //   padding: const EdgeInsets
                                                //       .symmetric(
                                                //     horizontal: 8.0,
                                                //   ),
                                                //   child: StreamBuilder<
                                                //       List<
                                                //           Map<String,
                                                //               dynamic>>>(
                                                //     stream: _playlistsController
                                                //         .stream,
                                                //     builder:
                                                //         (context, snapshot) {
                                                //       if (!snapshot.hasData) {
                                                //         return const Center(
                                                //           child:
                                                //               CircularProgressIndicator(
                                                //             color:
                                                //                 primaryTextColor,
                                                //           ), // Spi,
                                                //         );
                                                //       }

                                                //       final playlists =
                                                //           snapshot.data!;

                                                //       return ListView.builder(
                                                //         shrinkWrap:
                                                //             true, // Prevent ListView from expanding indefinitely
                                                //         physics:
                                                //             const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
                                                //         itemCount:
                                                //             playlists.length,
                                                //         itemBuilder:
                                                //             (context, index) {
                                                //           final playlist =
                                                //               playlists[index];

                                                //           // Wrap PlayList widget with GestureDetector or InkWell for handling tap
                                                //           return GestureDetector(
                                                //             onTap: () {
                                                //               setState(() {
                                                //                 Provider.of<PlaylistProvider>(
                                                //                         context,
                                                //                         listen:
                                                //                             false)
                                                //                     .updatePlaylist(
                                                //                   playlist[
                                                //                       'playlistImageUrl'],
                                                //                   playlist[
                                                //                       'playlistName'],
                                                //                   playlist[
                                                //                       'playlistDescription'],
                                                //                   playlist[
                                                //                       'creatorId'],
                                                //                   playlist[
                                                //                       'playlistId'],
                                                //                   playlist[
                                                //                       'timestamp'],
                                                //                   playlist[
                                                //                       'playlistUserIndex'],
                                                //                   playlist[
                                                //                       'songListIds'],
                                                //                   playlist[
                                                //                       'totalDuration'],
                                                //                 );
                                                //                 // Update widget dengan setState
                                                //                 setState(() {
                                                //                   Provider.of<WidgetStateProvider1>(
                                                //                           context,
                                                //                           listen:
                                                //                               false)
                                                //                       .changeWidget(
                                                //                     PlaylistContainer(
                                                //                       playlistId:
                                                //                           playlist[
                                                //                               'playlistId'],
                                                //                     ),
                                                //                     'Playlist Container',
                                                //                   );

                                                //                   activeWidget2 =
                                                //                       const ShowDetailSong();
                                                //                 });
                                                //               });
                                                //             },
                                                //             child: PlayList(
                                                //               creatorId: playlist[
                                                //                   'creatorId'],
                                                //               playlistId: playlist[
                                                //                   'playlistId'],
                                                //               playlistName:
                                                //                   playlist[
                                                //                       'playlistName'],
                                                //               playlistDescription:
                                                //                   playlist[
                                                //                       'playlistDescription'],
                                                //               playlistImageUrl:
                                                //                   playlist[
                                                //                       'playlistImageUrl'],
                                                //               timestamp: playlist[
                                                //                   'timestamp'],
                                                //               playlistUserIndex:
                                                //                   playlist[
                                                //                       'playlistUserIndex'],
                                                //               songListIds: playlist[
                                                //                   'songListIds'],
                                                //               totalDuration: playlist[
                                                //                           'totalDuration']
                                                //                       is int
                                                //                   ? playlist[
                                                //                       'totalDuration']
                                                //                   : int.tryParse(
                                                //                           playlist['totalDuration']
                                                //                               .toString()) ??
                                                //                       0, // Konversi dari String ke int
                                                //             ),
                                                //           );
                                                //         },
                                                //       );
                                                //     },
                                                //   ),
                                                // ),
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
                                child: TextFormField(
                                  // controller: searchListController,
                                  style:
                                      const TextStyle(color: primaryTextColor),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.all(8),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                          left: 12.0, right: 8.0),
                                      child: Icon(Icons.search,
                                          color: primaryTextColor),
                                    ),
                                    hintText: 'What do you want to play?',
                                    hintStyle:
                                        TextStyle(color: primaryTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      borderSide:
                                          BorderSide(color: primaryTextColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      borderSide:
                                          BorderSide(color: primaryTextColor),
                                    ),
                                  ),
                                  // onTap: navigateToHomeContainer,
                                  // onChanged: (value) {
                                  //   // Ensure we're on the search list when typing
                                  //   navigateToHomeContainer();
                                  // },
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                backgroundColor:
                                    primaryTextColor, // Warna latar belakang
                                child: IconButton(
                                  onPressed: () {
                                    // setState(() {
                                    //   Provider.of<WidgetStateProvider1>(context,
                                    //           listen: false)
                                    //       .changeWidget(
                                    //     const HomeContainer(),
                                    //     'Home Container',
                                    //   );

                                    //   activeWidget2 = const ShowDetailSong();
                                    // });
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

  // final StreamController<List<Map<String, dynamic>>> _playlistsController =
  //     StreamController();

  // Future<void> _submitPlaylistData(BuildContext context) async {
  //   try {
  //     final currentUser = FirebaseAuth.instance.currentUser;
  //     if (currentUser == null) return;

  //     // Step 1: Get the number of playlists created by the current user
  //     QuerySnapshot userPlaylists = await FirebaseFirestore.instance
  //         .collection('playlists')
  //         .where('creatorId', isEqualTo: currentUser.uid)
  //         .get();

  //     // Calculate playlistUserIndex (number of existing playlists + 1)
  //     int playlistUserIndex = userPlaylists.docs.length + 1;

  //     // Step 3: Add playlist data to Firestore 'playlists' collection
  //     DocumentReference playlistRef =
  //         await FirebaseFirestore.instance.collection('playlists').add({
  //       'playlistId': '',
  //       'creatorId': currentUser.uid,
  //       'playlistName': "Playlist # $playlistUserIndex",
  //       'playlistDescription': "",
  //       'playlistImageUrl': "",
  //       'timestamp': FieldValue.serverTimestamp(),
  //       'playlistUserIndex': playlistUserIndex,
  //       'songListIds': [],
  //       'playlistLikeIds': [],
  //       'totalDuration': 0,
  //     });

  //     // Step 4: Get playlistId from the newly added document
  //     String playlistId = playlistRef.id;

  //     // Step 5: Update the playlist document with the generated playlistId
  //     await playlistRef.update({'playlistId': playlistId});
  //   } catch (e) {
  //     print('Error submitting playlist data: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to submit playlist data: $e')),
  //     );
  //   }
  // }
}
