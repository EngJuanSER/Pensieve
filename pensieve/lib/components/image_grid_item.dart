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

    // Obtener dimensiones originales
    double aspectRatio = imageSize.width / imageSize.height;
    double finalWidth;
    double finalHeight;

    // Calcular dimensiones finales basadas en el ancho
    if (imageSize.width < minWidth) {
      // Si el ancho es menor al mínimo, escalamos hasta alcanzar el mínimo
      finalWidth = minWidth;
      finalHeight = minWidth / aspectRatio;
    } else if (imageSize.width > maxWidth) {
      // Si el ancho es mayor al máximo, escalamos hasta alcanzar el máximo
      finalWidth = maxWidth;
      finalHeight = maxWidth / aspectRatio;
    } else {
      // Si está dentro del rango, mantenemos las dimensiones originales
      finalWidth = imageSize.width;
      finalHeight = imageSize.height;
    }

    return Container(
      key: ValueKey(imagePath),
      child: InkWell(
        onTap: () => onTap(imagePath),
        child: SizedBox(
          width: finalWidth,
          height: finalHeight,
          child: Stack(
            children: [
              Container(
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
                    fit: BoxFit.contain,
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
      ),
    );
  }
}