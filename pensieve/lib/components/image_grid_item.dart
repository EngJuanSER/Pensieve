import 'package:flutter/material.dart';
import 'dart:io';

class ImageGridItem extends StatelessWidget {
  final String imagePath;
  final int index;
  final Function(String) onTap;
  final Function(int) onDelete;
  final Size imageSize;

  const ImageGridItem({
    super.key,
    required this.imagePath,
    required this.index,
    required this.onTap,
    required this.onDelete,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    const double minWidth = 100.0;
    const double maxWidth = 300.0;

  double originalWidth = imageSize.width;
  double originalHeight = imageSize.height;
  double scaleFactor = 1.0;

  if (originalWidth < minWidth) {
    scaleFactor = minWidth / originalWidth;
  } else if (originalWidth > maxWidth) {
    scaleFactor = maxWidth / originalWidth;
  }

  double finalWidth = originalWidth * scaleFactor;
  double finalHeight = originalHeight * scaleFactor;

    return SizedBox(
      key: ValueKey(imagePath),
      width: finalWidth, 
      height: finalHeight, 
      child: InkWell(
        onTap: () => onTap(imagePath),
        child: Stack(
          fit: StackFit.expand, 
          children: [
            Container(
              width: finalWidth,
              height: finalHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  width: finalWidth,
                  height: finalHeight,
                  fit: BoxFit.fill, 
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () => onDelete(index),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}