import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/provider/album_provider.dart';
import 'package:soundify/view/style/style.dart';
import 'package:uuid/uuid.dart';

class SearchAlbumId extends StatefulWidget {
  const SearchAlbumId({Key? key}) : super(key: key);

  @override
  State<SearchAlbumId> createState() => _SearchAlbumIdState();
}

class _SearchAlbumIdState extends State<SearchAlbumId> {
  bool _isTextFilled = false;
  bool _isSecondFieldVisible = false;

  late TextEditingController _albumNameController;
  late TextEditingController searchAlbumController;
  late TextEditingController albumIdController;

  @override
  void initState() {
    super.initState();
    _albumNameController = TextEditingController();
    searchAlbumController = TextEditingController();
    albumIdController = TextEditingController();

    _albumNameController.addListener(_onAlbumNameChanged);
    searchAlbumController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _albumNameController.removeListener(_onAlbumNameChanged);
    searchAlbumController.removeListener(_onSearchChanged);
    _albumNameController.dispose();
    searchAlbumController.dispose();
    albumIdController.dispose();
    super.dispose();
  }

  void _onAlbumNameChanged() {
    if (mounted) {
      setState(() {
        _isTextFilled = _albumNameController.text.isNotEmpty;
      });
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Function to filter albums based on search query
  List<Album> _filterAlbums(List<Album> albums) {
    String query = searchAlbumController.text.toLowerCase();
    if (query.isEmpty) {
      return albums;
    } else {
      return albums.where((album) {
        return album.albumName.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Select Album ID",
              style: TextStyle(color: primaryTextColor),
            ),
          ),
          // First TextFormField for search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              style: const TextStyle(color: primaryTextColor),
              controller: searchAlbumController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(8),
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.search,
                        color: primaryTextColor,
                      ),
                    ),
                    const VerticalDivider(
                      color: primaryTextColor,
                      width: 1,
                      thickness: 1,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isSecondFieldVisible = !_isSecondFieldVisible;
                    });
                  },
                  icon: Icon(
                    _isSecondFieldVisible ? Icons.remove : Icons.add,
                    color: primaryTextColor,
                  ),
                ),
                hintText: 'Search Album Name',
                hintStyle: const TextStyle(color: primaryTextColor),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: primaryTextColor,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: primaryTextColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // Second TextFormField for adding album name
          if (_isSecondFieldVisible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                style: const TextStyle(color: primaryTextColor),
                controller: _albumNameController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.album,
                          color: primaryTextColor,
                        ),
                      ),
                      const VerticalDivider(
                        color: primaryTextColor,
                        width: 1,
                        thickness: 1,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  suffixIcon: _isTextFilled
                      ? IconButton(
                          onPressed: () {
                            _submitAlbumData();
                          },
                          icon: const Icon(
                            Icons.check,
                            color: primaryTextColor,
                          ),
                        )
                      : null,
                  hintText: 'Album Name',
                  hintStyle: const TextStyle(color: primaryTextColor),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: primaryTextColor,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8.0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(),
          ),
          // Expanded widget with FutureBuilder
          Expanded(
            child: FutureBuilder<List<Album>>(
              future: DatabaseHelper.instance.getAlbums(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryTextColor,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No albums found',
                        style: TextStyle(color: primaryTextColor)),
                  );
                }

                List<Album> allAlbums = snapshot.data!;
                List<Album> filteredAlbums = _filterAlbums(allAlbums);

                return ListView.builder(
                  itemCount: filteredAlbums.length,
                  itemBuilder: (context, index) {
                    var album = filteredAlbums[index];
                    return ListTile(
                      title: Text(
                        album.albumName,
                        style: const TextStyle(
                          color: primaryTextColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () {
                        Provider.of<AlbumProvider>(context, listen: false)
                            .setAlbumId(album.albumId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAlbumData() async {
    String albumName = _albumNameController.text.trim();

    if (albumName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album name is missing.')),
      );
      return;
    }

    String? currentUserId = await DatabaseHelper.instance.getCurrentUserId();
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not logged in')),
      );
      return;
    }

    try {
      List<Album> userAlbums = await DatabaseHelper.instance.getAlbums();
      userAlbums = userAlbums
          .where((album) => album.creatorId == currentUserId)
          .toList();

      int albumUserIndex = userAlbums.length + 1;

      // Generate UUID for the albumId
      var uuid = Uuid();
      Album newAlbum = Album(
        albumId: uuid.v4(), // Using UUID here
        creatorId: currentUserId,
        albumName: albumName,
        albumDescription: "",
        albumImageUrl: "",
        timestamp: DateTime.now(),
        albumUserIndex: albumUserIndex,
        songListIds: [],
        albumLikeIds: [],
        totalDuration: Duration.zero,
      );

      await DatabaseHelper.instance.insertAlbum(newAlbum);

      _albumNameController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album successfully created')),
      );
    } catch (e) {
      print('Error submitting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create album: $e')),
      );
    }
  }
}
