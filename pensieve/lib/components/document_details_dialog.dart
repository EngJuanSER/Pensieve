import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/document.dart';
import '../utils/file_utils.dart';
import 'tag_manager.dart';
import 'image_viewer.dart';

class DocumentDetailsDialog extends StatefulWidget {
  final Document document;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final Function(List<String>) onUpdateTags;
  final VoidCallback onDelete;
  final Function(String) onUpdateDescription;

  const DocumentDetailsDialog({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onUpdateTags,
    required this.onDelete,
    required this.onUpdateDescription,
  });

  @override
  State<DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<DocumentDetailsDialog> {
  late TextEditingController _descriptionController;
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.document.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).dialogBackgroundColor, // Asegurar color de fondo adecuado
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewSection(),
                      const Divider(height: 32),
                      _buildInfoSection(),
                      const Divider(height: 32),
                      _buildDescriptionSection(),
                      const Divider(height: 32),
                      _buildTagsSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.document.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              widget.document.isFavorite ? Icons.star : Icons.star_outline,
              color: widget.document.isFavorite ? Colors.amber : Colors.white,
            ),
            onPressed: widget.onToggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.document.path));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta copiada al portapapeles')),
                );
              }
            },
            tooltip: 'Copiar ruta',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista previa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            height: 200,
            child: _buildPreview(),
          ),
        ),
      ],
    );
  }

Widget _buildPreview() {
  final extension = widget.document.fileType.toLowerCase();
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);

  if (isImage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(imageUrl: widget.document.path),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(
            File(widget.document.path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackPreview();
            },
          ),
          
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  } else {
    return widget.document.thumbnailPath != null ? 
      Image.file(
        File(widget.document.thumbnailPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackPreview(),
      ) : 
      _buildFallbackPreview();
  }
}

  Widget _buildFallbackPreview() {
    final IconData iconData = FileUtils.getIconForFileType(widget.document.fileType);
    final Color bgColor = FileUtils.getColorForFileType(widget.document.fileType);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 80, color: bgColor),
          const SizedBox(height: 8),
          Text(
            widget.document.fileType.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: bgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final lastAccessed = widget.document.lastAccessed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _infoRow('Nombre:', widget.document.name),
        _infoRow('Tipo:', widget.document.fileType.toUpperCase()),
        _infoRow('Tamaño:', FileUtils.formatFileSize(widget.document.fileSize)),
        _infoRow('Ubicación:', widget.document.path),
        _infoRow('Fecha de agregado:', FileUtils.formatFileDate(widget.document.addedAt)),
        if (lastAccessed != null)
          _infoRow('Último acceso:', FileUtils.formatFileDate(lastAccessed)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final hintColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(_isEditingDescription ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditingDescription) {
                  widget.onUpdateDescription(_descriptionController.text);
                }
                setState(() {
                  _isEditingDescription = !_isEditingDescription;
                });
              },
              tooltip: _isEditingDescription ? 'Guardar' : 'Editar',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditingDescription)
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Escribe una descripción...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.document.description ?? 'Sin descripción',
              style: TextStyle(
                color: widget.document.description != null ? textColor : hintColor,
                fontStyle: widget.document.description != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTagsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final Color chipBackground = isDarkMode ? Colors.blueGrey.shade700 : Colors.blueGrey.shade100;
    
    final Color chipTextColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Etiquetas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showTagManager,
              tooltip: 'Editar etiquetas',
            ),
          ],
        ),
        const SizedBox(height: 8),
        widget.document.tags.isEmpty
          ? const Text(
              'Sin etiquetas',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.document.tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: TextStyle(color: chipTextColor),
                ),
                backgroundColor: chipBackground,
              )).toList(),
            ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir'),
            onPressed: () {
              widget.onOpen();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: const Text('¿Estás seguro de que quieres eliminar este documento? Esta acción no elimina el archivo original.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              
              Navigator.of(context).pop();
              
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }

  void _showTagManager() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestionar etiquetas'),
        content: TagManager(
          tags: widget.document.tags,
          onTagsChanged: widget.onUpdateTags,
          iconColor: Colors.blueGrey,
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}