import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  
  const ImageViewer({super.key, required this.imageUrl});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PhotoViewController controller;
  double currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    controller = PhotoViewController()..scale = currentScale;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imagen Completa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                currentScale = (controller.scale ?? 1.0) * 1.25;
                controller.scale = currentScale;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                currentScale = (controller.scale ?? 1.0) * 0.8;
                controller.scale = currentScale;
              });
            },
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: FileImage(File(widget.imageUrl)),
        controller: controller,
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 4,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: BoxDecoration(
          color: Colors.blueGrey[100],
        ),
        enableRotation: false,
        enablePanAlways: true, // Permite arrastrar la imagen cuando hay zoom
        scaleStateChangedCallback: (state) {
          setState(() {
            currentScale = controller.scale ?? 1.0;
          });
        },
      ),
    );
  }
}