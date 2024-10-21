import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/view/style/style.dart';

class SearchArtistId extends StatefulWidget {
  const SearchArtistId({super.key});

  @override
  State<SearchArtistId> createState() => _SearchArtistIdState();
}

class _SearchArtistIdState extends State<SearchArtistId> {
  final TextEditingController searchArtistController = TextEditingController();
  final TextEditingController artistIdController = TextEditingController();
  List<User> users = [];
  List<User> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    searchArtistController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchArtistController.removeListener(_onSearchChanged);
    searchArtistController.dispose();
    artistIdController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        filteredUsers = _filterUsers(users);
      });
    }
  }

  // Function to fetch data from SQLite
  Future<void> _loadUsers() async {
    List<Map<String, dynamic>> userMaps = await DatabaseHelper.instance.getUsers();
    List<User> loadedUsers = userMaps.map((map) => User.fromMap(map)).toList();

    if (mounted) {
      setState(() {
        users = loadedUsers;
        filteredUsers = users; // Initially display all users
      });
    }
  }

  // Function to filter users
  List<User> _filterUsers(List<User> userList) {
    String query = searchArtistController.text.toLowerCase();
    if (query.isEmpty) {
      return userList;
    } else {
      return userList.where((user) {
        return user.username.toLowerCase().contains(query);
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
              "Select Artist ID",
              style: TextStyle(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              style: const TextStyle(color: Colors.white),
              controller: searchArtistController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(8),
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            filteredUsers = _filterUsers(users);
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                    const VerticalDivider(
                      color: Colors.white,
                      width: 1,
                      thickness: 1,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                hintText: 'Search Username',
                hintStyle: const TextStyle(color: Colors.white),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getUsers(),
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
                    child: Text('No users found', style: TextStyle(color: Colors.white)),
                  );
                }

                List<User> allUsers = snapshot.data!.map((map) => User.fromMap(map)).toList();
                List<User> displayedUsers = _filterUsers(allUsers);

                return ListView.builder(
                  itemCount: displayedUsers.length,
                  itemBuilder: (context, index) {
                    User user = displayedUsers[index];
                    return ListTile(
                      title: Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () {
                        Provider.of<SongProvider>(context, listen: false)
                            .setArtistId(user.userId);
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
}