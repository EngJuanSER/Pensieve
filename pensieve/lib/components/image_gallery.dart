import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'image_viewer.dart';
import 'image_grid_item.dart';

class ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final Function(List<String>) onImageUrlsChanged;
  final Color iconColor;

  const ImageGallery({
    super.key, 
    required this.imageUrls, 
    required this.onImageUrlsChanged, 
    this.iconColor = Colors.black,
  });

  @override
  State<ImageGallery> createState() => ImageGalleryState();
}

class ImageGalleryState extends State<ImageGallery> {
  List<String> imageUrls = [];
  bool isDragging = false;
  final Map<String, Size> imageSizes = {};

  @override
  void initState() {
    super.initState();
    imageUrls = List<String>.from(widget.imageUrls);
    _loadImageSizes();
  }

  Future<void> _loadImageSizes() async {
    for (var url in imageUrls) {
      imageSizes[url] = await _getImageDimensions(url);
    }
    if (mounted) setState(() {});
  }

  Future<Size> _getImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('Error al obtener dimensiones: $e');
      return const Size(100, 100);
    }
  }

  Future<void> pickImage() async {
    try {
      final XTypeGroup imagesTypeGroup = XTypeGroup(
        label: 'Imágenes',
        extensions: ['jpg', 'jpeg', 'png', 'gif'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: [imagesTypeGroup],
      );

      if (file != null) {
        final String filePath = file.path;
        imageSizes[filePath] = await _getImageDimensions(filePath);
        imageUrls.add(filePath);
        widget.onImageUrlsChanged(imageUrls);
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Galería de Imágenes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await pickImage();
                  setState(() {});
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Agregar Imagen'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: DropTarget(
              onDragDone: (details) async {
                for (final file in details.files) {
                  final extension = path.extension(file.path).toLowerCase();
                  if (['.jpg', '.jpeg', '.png', '.gif'].contains(extension)) {
                    imageSizes[file.path] = await _getImageDimensions(file.path);
                    setState(() {
                      imageUrls.add(file.path);
                      widget.onImageUrlsChanged(imageUrls);
                      isDragging = false;
                    });
                  }
                }
              },
              onDragEntered: (details) => setState(() => isDragging = true),
              onDragExited: (details) => setState(() => isDragging = false),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDragging ? Colors.blue : Colors.grey.withOpacity(0.3),
                    width: isDragging ? 2 : 1,
                    style: BorderStyle.none,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    if (imageUrls.isEmpty)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 48),
                            SizedBox(height: 8),
                            Text('Arrastra imágenes aquí'),
                          ],
                        ),
                      )
                    else
                      MasonryGridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        padding: const EdgeInsets.all(16),
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          final url = imageUrls[index];
                          return imageSizes.containsKey(url)
                            ? ImageGridItem(
                                imagePath: url,
                                index: index,
                                onTap: _showFullScreenImage,
                                onDelete: (idx) {
                                  setState(() {
                                    imageUrls.removeAt(idx);
                                    widget.onImageUrlsChanged(imageUrls);
                                  });
                                },
                                imageSize: imageSizes[url]!,
                              )
                            : const SizedBox(
                                height: 100,
                                child: Center(child: CircularProgressIndicator()),
                              );
                        },
                      ),
                    if (isDragging)
                      Container(
                        color: Colors.blue.withOpacity(0.1),
                        child: const Center(
                          child: Icon(Icons.cloud_upload, size: 64, color: Colors.blue),
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
  }
}