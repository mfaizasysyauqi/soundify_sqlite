import 'package:flutter/material.dart';
import 'package:soundify/provider/image_provider.dart'; // Sesuaikan dengan path yang benar
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // Untuk penggunaan File

class ShowImage extends StatefulWidget {
  const ShowImage({super.key});

  @override
  State<ShowImage> createState() => _ShowImageState();
}

class _ShowImageState extends State<ShowImage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ImageProviderData>(
      builder: (context, imageProvider, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20), // Membuat sudut melengkung pada Scaffold
          child: Scaffold(
            backgroundColor: primaryColor,
            body: Padding(
              padding: const EdgeInsets.all(8.0), // Menambahkan padding di seluruh Scaffold
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (imageProvider.imagePath != null) // Menampilkan gambar jika ada path
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AspectRatio(
                            aspectRatio: 1, // Set rasio 1:1 agar gambar tetap kotak
                            child: Image.file(
                              File(imageProvider.imagePath!), // Gunakan File untuk gambar dari path
                              fit: BoxFit.cover, // Pastikan gambar memenuhi container
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      overflow: TextOverflow.ellipsis,
                      imageProvider.imagePath ?? 'No Image Selected', // Nama file yang dipilih atau placeholder
                      style: const TextStyle(color: primaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
