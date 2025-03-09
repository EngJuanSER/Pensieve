import 'package:flutter/material.dart';
import '../models/document.dart';
import 'document_list_item.dart';

class DocumentListView extends StatelessWidget {
  final List<Document> documents;
  final void Function(Document) onDocumentTap;
  final void Function(String) onFavoriteToggle;
  final void Function(String) onDelete;

  const DocumentListView({
    super.key,
    required this.documents,
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
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentListItem(
          document: document,
          onTap: () => onDocumentTap(document),
          onFavoriteToggle: () => onFavoriteToggle(document.id),
          onDelete: () => onDelete(document.id),
        );
      },
    );
  }
}