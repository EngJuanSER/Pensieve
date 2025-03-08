import 'package:flutter/material.dart';
import 'dart:io';
import '../models/document.dart';
import '../utils/file_utils.dart';

class DocumentListItem extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: FileUtils.getColorForFileType(document.fileType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildDocumentPreview(),
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          FileUtils.formatFileDate(document.addedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FileUtils.getColorForFileType(document.fileType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            document.fileType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: FileUtils.getColorForFileType(document.fileType),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          FileUtils.formatFileSize(document.fileSize),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (document.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              document.tags.length > 1 
                                ? '${document.tags.length} etiquetas' 
                                : document.tags.first,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (document.description != null && document.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          document.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Acciones (favorito y eliminar)
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      document.isFavorite ? Icons.star : Icons.star_border,
                      color: document.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: onFavoriteToggle,
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      maxWidth: 32,
                      maxHeight: 32,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _showDeleteConfirmation(context),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      maxWidth: 32,
                      maxHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: const Text('¿Estás seguro de que quieres eliminar este documento de la biblioteca? El archivo original no será eliminado.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    // Para imágenes con thumbnails
    if (document.thumbnailPath != null) {
      return Image.file(
        File(document.thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackPreview(),
      );
    }

    final extension = document.fileType.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return Image.file(
        File(document.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackPreview(),
      );
    }
    
    return _buildFallbackPreview();
  }

  Widget _buildFallbackPreview() {
    final IconData iconData = FileUtils.getIconForFileType(document.fileType);
    final Color color = FileUtils.getColorForFileType(document.fileType);
    
    return Center(
      child: Icon(iconData, color: color, size: 30),
    );
  }
}