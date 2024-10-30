import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/provider/profile_provider.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/style/style.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({
    super.key,
  });

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  late DatabaseHelper _databaseHelper;
  OverlayEntry? _overlayEntry;
  String? _selectedImagePath;
  String? _selectedBioImagePath;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadCurrentUser();
    });
  }

  Future<void> _loadUserData() async {
    final currentUser = await _databaseHelper.getCurrentUser();
    if (currentUser != null) {
      setState(() {});
    }
  }

  Future<void> _pickImage(Function(String) onImagePicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        onImagePicked(file.path!);
      }
    }
  }

  Future<void> _handleImageUpload(String imagePath) async {
    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final currentUser = profileProvider.currentUser;

      if (currentUser != null) {
        final String savedImagePath = await FileStorageHelper.instance
            .saveProfileImage(currentUser.userId, imagePath);

        await profileProvider.updateProfile(profileImageUrl: savedImagePath);

        setState(() {
          _selectedImagePath = null;
        });
      }
    } catch (e) {
      print('Error updating profile image: $e');
    }
  }

  void _showEditProfileModal(BuildContext context) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    TextEditingController usernameController =
        TextEditingController(text: profileProvider.username);
    TextEditingController fullNameController =
        TextEditingController(text: profileProvider.fullName);

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _closeModal();
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 480,
                    height: 248,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: tertiaryColor,
                      borderRadius: BorderRadius.circular(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _closeModal();
                              },
                              child: const Icon(
                                Icons.close,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Content
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await _pickImage((path) {
                                  setState(() {
                                    _selectedImagePath = path;
                                  });
                                });
                              },
                              child: Consumer<ProfileProvider>(
                                builder: (context, provider, _) {
                                  return CircleAvatar(
                                    radius: 80,
                                    backgroundColor:
                                        _selectedImagePath == null &&
                                                provider.profileImageUrl.isEmpty
                                            ? primaryTextColor
                                            : tertiaryColor,
                                    backgroundImage: _selectedImagePath != null
                                        ? FileImage(File(_selectedImagePath!))
                                        : provider.profileImageUrl.isNotEmpty
                                            ? FileImage(
                                                File(provider.profileImageUrl))
                                            : null,
                                    child: _selectedImagePath == null &&
                                            provider.profileImageUrl.isEmpty
                                        ? Icon(Icons.person,
                                            color: primaryColor, size: 80)
                                        : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: usernameController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Username',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      hintText: 'Enter username',
                                      hintStyle:
                                          TextStyle(color: primaryTextColor),
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: fullNameController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Full name',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      hintText: 'Enter full name',
                                      hintStyle:
                                          TextStyle(color: primaryTextColor),
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          _closeModal();
                                          await profileProvider
                                              .deleteProfileImage();
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            color: primaryColor,
                                            width: 170,
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Delete profile image',
                                              style: TextStyle(
                                                color: tertiaryTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            // Handle image upload if new image is selected
                                            String? newImagePath =
                                                _selectedImagePath;
                                            if (_selectedImagePath != null) {
                                              newImagePath =
                                                  await FileStorageHelper
                                                      .instance
                                                      .saveProfileImage(
                                                profileProvider
                                                    .currentUser!.userId,
                                                _selectedImagePath!,
                                              );
                                            }

                                            // Update profile with all changes
                                            await profileProvider.updateProfile(
                                              username: usernameController.text,
                                              fullName: fullNameController.text,
                                              profileImageUrl: newImagePath,
                                            );

                                            _closeModal();
                                          } catch (e) {
                                            print('Error updating profile: $e');
                                            // You might want to show an error message to the user
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            color: primaryColor,
                                            width: 80,
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: primaryTextColor,
                                                fontSize: smallFontSize,
                                                fontWeight: FontWeight.bold,
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showEditBioModal(BuildContext context) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    TextEditingController bioController =
        TextEditingController(text: profileProvider.bio);

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _closeModal();
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 480,
                    height: 273,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: tertiaryColor,
                      borderRadius: BorderRadius.circular(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Bio',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _closeModal();
                              },
                              child: const Icon(
                                Icons.close,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Content
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await _pickImage((path) {
                                  setState(() {
                                    _selectedBioImagePath = path;
                                  });
                                });
                              },
                              child: Consumer<ProfileProvider>(
                                builder: (context, provider, _) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      width: 190,
                                      height: 190,
                                      decoration: BoxDecoration(
                                        color: _selectedBioImagePath == null &&
                                                provider.bioImageUrl.isEmpty
                                            ? primaryTextColor
                                            : tertiaryColor,
                                        image: _selectedBioImagePath != null
                                            ? DecorationImage(
                                                image: FileImage(File(
                                                    _selectedBioImagePath!)),
                                                fit: BoxFit.cover,
                                              )
                                            : provider.bioImageUrl.isNotEmpty
                                                ? DecorationImage(
                                                    image: FileImage(File(
                                                        provider.bioImageUrl)),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                      ),
                                      child: _selectedBioImagePath == null &&
                                              provider.bioImageUrl.isEmpty
                                          ? Icon(Icons.portrait,
                                              color: primaryColor, size: 90)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    minLines: 5,
                                    maxLines: 5,
                                    controller: bioController,
                                    style: const TextStyle(
                                        color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(8),
                                      labelText: 'Bio',
                                      labelStyle:
                                          TextStyle(color: primaryTextColor),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      hintText: 'Enter bio',
                                      hintStyle:
                                          TextStyle(color: primaryTextColor),
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: primaryTextColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          _closeModal();
                                          await profileProvider
                                              .deleteBioImage();
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            color: primaryColor,
                                            width: 160,
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Delete bio image',
                                              style: TextStyle(
                                                color: tertiaryTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            // Handle bio image upload if new image is selected
                                            String? newBioImageUrl =
                                                _selectedBioImagePath;
                                            if (_selectedBioImagePath != null) {
                                              newBioImageUrl =
                                                  await FileStorageHelper
                                                      .instance
                                                      .saveBioImage(
                                                // Menggunakan saveBioImage
                                                profileProvider
                                                    .currentUser!.userId,
                                                _selectedBioImagePath!,
                                              );
                                            }

                                            // Update bio with all changes
                                            await profileProvider.updateBio(
                                              bio: bioController.text,
                                              bioImageUrl: newBioImageUrl,
                                            );

                                            _closeModal();
                                          } catch (e) {
                                            print('Error updating bio: $e');
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            color: primaryColor,
                                            width: 80,
                                            height: 40,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: primaryTextColor,
                                                fontSize: smallFontSize,
                                                fontWeight: FontWeight.bold,
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!); // Show overlay
  }

  Future<void> _deleteBioImage() async {
    final currentUser = await _databaseHelper.getCurrentUser();
    if (currentUser != null) {
      // Delete the image file
      await FileStorageHelper.instance.deleteImage(currentUser.bioImageUrl);

      // Update user in database with empty bio image URL
      final updatedUser = currentUser.copyWith(bioImageUrl: '');
      await _databaseHelper.updateUser(updatedUser);
      await _loadUserData();
    }
  }

  void _closeModal() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // final user = profileProvider.currentUser;

        if (profileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: <Widget>[
            buildUserInfo(profileProvider),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Divider(
                thickness: 1,
                color: primaryTextColor,
              ),
            ),
            buildEditProfile(profileProvider),
            buildEditBio(profileProvider),
          ],
        );
      },
    );
  }

  Widget buildUserInfo(ProfileProvider profileProvider) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8.0, right: 8.0),
      child: Row(
        children: [
          // Only show index if it exists
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: const Text(
              '𝅗𝅥',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: mediumWeight,
                fontSize: smallFontSize,
              ),
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          // Song image
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 50,
              width: 50,
              child: profileProvider.profileImageUrl.isEmpty
                  ? Container(
                      color: primaryTextColor,
                      child: Icon(Icons.library_music,
                          color: primaryColor, size: 25))
                  : Image.file(
                      File(profileProvider.profileImageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: senaryColor,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white, size: 25),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Song title and artist name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileProvider.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontWeight: mediumWeight,
                    fontSize: smallFontSize,
                  ),
                ),
                Text(
                  profileProvider.username,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: quaternaryTextColor,
                    fontWeight: mediumWeight,
                    fontSize: microFontSize,
                  ),
                )
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<WidgetStateProvider2>(context, listen: false)
                    .changeWidget(const ShowDetailSong(), 'ShowDetailSong');
              });
            },
            icon: const Icon(
              Icons.close,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditProfile(ProfileProvider profileProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: primaryTextColor.withOpacity(0.1),
        onTap: () {
          setState(() {});
          _showEditProfileModal(context); // Menampilkan AlertDialog
        },
        child: Padding(
          padding: const EdgeInsets.only(
              left: 11, right: 8.0, top: 10.0, bottom: 10.0),
          child: SizedBox(
            width: double.infinity,
            child: const Row(
              children: [
                Icon(
                  Icons.edit,
                  color: primaryTextColor,
                ),
                SizedBox(width: 12),
                Text(
                  "Edit Profile",
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEditBio(ProfileProvider profileProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: primaryTextColor.withOpacity(0.1),
        onTap: () {
          setState(() {});
          _closeModal(); // Tutup modal setelah action
          _showEditBioModal(context); // Menampilkan AlertDialog
        },
        child: Padding(
          padding: const EdgeInsets.only(
              left: 11, right: 8.0, top: 10.0, bottom: 10.0),
          child: SizedBox(
            width: double.infinity,
            child: const Row(children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: primaryTextColor,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Edit Bio",
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
