import 'package:flutter/material.dart';
import '../models/document.dart';
import '../utils/file_utils.dart';
import 'document_card.dart';

class DocumentGroupedView extends StatelessWidget {
  final List<Document> documents;
  final String groupBy; 
  final void Function(Document) onDocumentTap;
  final void Function(String) onFavoriteToggle;
  final void Function(String) onDelete;
  
  const DocumentGroupedView({
    super.key,
    required this.documents,
    this.groupBy = 'type',
    required this.onDocumentTap,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(
        child: Text(
          'No hay documentos disponibles.\nAgrega documentos con el botón +',
          textAlign: TextAlign.center,
        ),
      );
    }
    
    final Map<String, List<Document>> groupedDocuments = {};
    
    if (groupBy == 'type') {
      for (final doc in documents) {
        final type = doc.fileType.toUpperCase();
        groupedDocuments.putIfAbsent(type, () => []).add(doc);
      }
    } else {
      // Documentos sin etiquetas
      final noTags = documents.where((doc) => doc.tags.isEmpty).toList();
      if (noTags.isNotEmpty) {
        groupedDocuments['Sin etiquetas'] = noTags;
      }
      
      // Documentos con etiquetas
      for (final doc in documents.where((doc) => doc.tags.isNotEmpty)) {
        for (final tag in doc.tags) {
          groupedDocuments.putIfAbsent(tag, () => []).add(doc);
        }
      }
    }
    
    // Ordenar las claves para mostrarlas alfabéticamente
    final keys = groupedDocuments.keys.toList()..sort();
    
    return ListView.builder(
      itemCount: keys.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final key = keys[index];
        final docsInGroup = groupedDocuments[key]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    if (groupBy == 'type')
                      Icon(
                        FileUtils.getIconForFileType(key.toLowerCase()),
                        color: FileUtils.getColorForFileType(key.toLowerCase()),
                      )
                    else
                      const Icon(Icons.label, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      '$key (${docsInGroup.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docsInGroup.length,
                  itemBuilder: (context, i) {
                    final doc = docsInGroup[i];
                    return SizedBox(
                      width: 180,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 12),
                        child: DocumentCard(
                          document: doc,
                          onTap: () => onDocumentTap(doc),
                          onFavoriteToggle: () => onFavoriteToggle(doc.id),
                          onDelete: () => onDelete(doc.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}