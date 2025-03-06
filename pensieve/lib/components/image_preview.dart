import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;

class ImagePreview extends StatelessWidget {
  final List<String> imageUrls;

  const ImagePreview({
    super.key,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int maxImages = math.max(1, constraints.maxWidth ~/ 48);
          int visibleImages = math.min(maxImages, imageUrls.length);
          bool hasMore = imageUrls.length > visibleImages;

          return Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (var i = 0; i < visibleImages; i++)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(imageUrls[i]),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              if (hasMore)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '+${imageUrls.length - visibleImages}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
      ),
    );
  }
}