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
      child: Row(
        children: [
          for (var i = 0; i < math.min(2, imageUrls.length); i++)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(imageUrls[i]),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (imageUrls.length > 2)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '+${imageUrls.length - 2}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}