import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soundify/components/current_user_avatar.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/provider/playlist_provider.dart';
import 'package:soundify/provider/profile_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/bottom_container.dart';
import 'package:soundify/view/container/primary/add_song_container.dart';
import 'package:soundify/view/container/primary/home_container.dart';
import 'package:soundify/view/container/primary/liked_song_container.dart';
import 'package:soundify/view/container/primary/personal_profile_container.dart';
import 'package:soundify/view/container/primary/playlist_container.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/splash_screen.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'package:soundify/view/widget/play_list.dart';
import 'package:soundify/view/widget/song_list.dart';

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
  String? _currentUserId;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistProvider>(context, listen: false).fetchPlaylists();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentWidgetName =
        Provider.of<WidgetStateProvider1>(context, listen: true).widgetName;
    setState(() {
      isSearch = currentWidgetName == "HomeContainer";
    });

    // Wrap the profile loading in a post-frame callback
    if (_currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ProfileProvider>(context, listen: false)
            .loadUserById(_currentUserId!);
      });
    }
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

  // Method untuk memuat current user dari SQLite
  Future<void> _loadCurrentUser() async {
    try {
      final user = await DatabaseHelper.instance.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUserId = user.userId;
          _currentUserRole = user.role; // Tambahkan ini
        });

        // Load user profile data after setting currentUserId
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<ProfileProvider>(context, listen: false)
                .loadUserById(user.userId);
          }
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
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
                          await Provider.of<PlaylistProvider>(context,
                                  listen: false)
                              .submitNewPlaylist(context);

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

                          // Navigate to playlist container with the correct ID
                          Provider.of<WidgetStateProvider1>(context,
                                  listen: false)
                              .changeWidget(
                            PlaylistContainer(
                              playlistId: latestPlaylist.playlistId,
                            ),
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
                    // Hanya tampilkan Add Song jika role adalah artist atau admin
                    if (_currentUserRole == 'Artist' ||
                        _currentUserRole == 'Admin') ...[
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
                                      activeWidget2 = newWidget;
                                    });
                                  },
                                ),
                                'Add Song Container',
                              );
                            });
                            _closeModal();
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
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
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
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 18.0),
                                child: TextButton(
                                  onPressed: () {
                                    setState(
                                      () {
                                        Provider.of<WidgetStateProvider1>(
                                                context,
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0),
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                                      listen:
                                                                          false)
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
                                                                child:
                                                                    Container(
                                                                  width: 35,
                                                                  height: 35,
                                                                  color:
                                                                      secondaryColor,
                                                                  child: Icon(
                                                                    Icons
                                                                        .favorite,
                                                                    color:
                                                                        primaryColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 12),
                                                              const Text(
                                                                'Liked Songs',
                                                                style:
                                                                    TextStyle(
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
                                                          horizontal: 8.0),
                                                      child: Consumer<
                                                          PlaylistProvider>(
                                                        builder: (context,
                                                            playlistProvider,
                                                            child) {
                                                          // if (playlistProvider
                                                          //     .isFetching) {
                                                          //   return const Center(
                                                          //     child:
                                                          //         CircularProgressIndicator(
                                                          //       color:
                                                          //           primaryTextColor,
                                                          //     ),
                                                          //   );
                                                          // }

                                                          if (playlistProvider
                                                              .hasError) {
                                                            return Center(
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                      'Failed to load playlists'),
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Provider.of<PlaylistProvider>(
                                                                              context,
                                                                              listen: false)
                                                                          .fetchPlaylists();
                                                                    },
                                                                    child: Text(
                                                                        'Retry'),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }

                                                          if (playlistProvider
                                                              .displayPlaylists
                                                              .isEmpty) {
                                                            return const Center(
                                                              child: Text(
                                                                  'No playlists found'),
                                                            );
                                                          }

                                                          return ListView
                                                              .builder(
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            itemCount:
                                                                playlistProvider
                                                                    .displayPlaylists
                                                                    .length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              final playlist =
                                                                  playlistProvider
                                                                          .displayPlaylists[
                                                                      index];

                                                              return GestureDetector(
                                                                onTap: () {
                                                                  // Perbarui cara akses data playlist
                                                                  Provider.of<PlaylistProvider>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .updatePlaylistProvider(
                                                                    playlist[
                                                                            'playlistId']
                                                                        as String,
                                                                    playlist[
                                                                            'creatorId']
                                                                        as String,
                                                                    playlist[
                                                                            'playlistName']
                                                                        as String,
                                                                    playlist[
                                                                            'playlistDescription']
                                                                        as String?,
                                                                    playlist[
                                                                            'playlistImageUrl']
                                                                        as String?,
                                                                    playlist[
                                                                            'timestamp']
                                                                        as DateTime,
                                                                    playlist[
                                                                            'playlistUserIndex']
                                                                        as int,
                                                                    (playlist['songListIds']
                                                                            as List)
                                                                        .cast<
                                                                            String>(),
                                                                    (playlist['playlistLikeIds']
                                                                            as List)
                                                                        .cast<
                                                                            String>(),
                                                                    playlist[
                                                                            'totalDuration']
                                                                        as Duration,
                                                                  );

                                                                  Provider.of<WidgetStateProvider1>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .changeWidget(
                                                                    PlaylistContainer(
                                                                      playlistId:
                                                                          playlist['playlistId']
                                                                              as String,
                                                                    ),
                                                                    'PlaylistContainer',
                                                                  );
                                                                },
                                                                child: PlayList(
                                                                  playlistImageUrl:
                                                                      playlist[
                                                                              'playlistImageUrl']
                                                                          as String,
                                                                  playlistName:
                                                                      playlist[
                                                                              'playlistName']
                                                                          as String,
                                                                  creatorName: playlist[
                                                                          'creatorName']
                                                                      as String,
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    )
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
                                          contentPadding:
                                              const EdgeInsets.all(8),
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
                                            borderSide: BorderSide(
                                                color: secondaryColor),
                                          ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30)),
                                            borderSide: BorderSide(
                                                color: secondaryColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                const BorderRadius.all(
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
                                          Provider.of<WidgetStateProvider1>(
                                                  context,
                                                  listen: false)
                                              .changeWidget(
                                            const HomeContainer(),
                                            'Home Container',
                                          );

                                          activeWidget2 =
                                              const ShowDetailSong();
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
                                    shape:
                                        const CircleBorder(), // Bentuk lingkaran
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
                                                    top:
                                                        73, // Jarak dari atas layar
                                                    right:
                                                        14, // Jarak dari ujung kanan
                                                    child: Material(
                                                      color: Colors
                                                          .transparent, // Transparan agar decoration terlihat
                                                      child: IntrinsicWidth(
                                                        // Menjaga ukuran popup sesuai konten
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(20),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                tertiaryColor,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16), // Membuat ujung melengkung
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black26, // Warna shadow
                                                                blurRadius:
                                                                    10, // Ukuran blur shadow
                                                                offset: Offset(
                                                                    0,
                                                                    4), // Posisi shadow
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    if (_currentUserId !=
                                                                        null) {
                                                                      Provider.of<WidgetStateProvider1>(
                                                                              context,
                                                                              listen: false)
                                                                          .changeWidget(
                                                                        PersonalProfileContainer(
                                                                          userId:
                                                                              _currentUserId!, // Gunakan _currentUserId
                                                                        ),
                                                                        'Profile Container',
                                                                      );

                                                                      activeWidget2 =
                                                                          const ShowDetailSong();
                                                                    }
                                                                  });
                                                                },
                                                                child:
                                                                    const Text(
                                                                  'Profile',
                                                                  style:
                                                                      TextStyle(
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
                                                                onPressed:
                                                                    _logout,
                                                                child:
                                                                    const Text(
                                                                  "Log Out",
                                                                  style:
                                                                      TextStyle(
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
                                        child: const CurrentUserAvatar(
                                          radius: 20,
                                          iconSize: 20,
                                        )),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 2.0,
                                      right: 2.0,
                                      top: 12,
                                      bottom: 0),
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
                                              child: Consumer2<
                                                  WidgetSizeProvider,
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
                                          flex: MediaQuery.of(context)
                                                      .size
                                                      .width <=
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
                                            child:
                                                Consumer<WidgetStateProvider2>(
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
      },
    );
  }
}
