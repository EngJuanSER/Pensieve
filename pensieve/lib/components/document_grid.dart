import 'package:flutter/material.dart';
import '../models/document.dart';
import 'document_card.dart';

class DocumentGridView extends StatelessWidget {
  final List<Document> documents;
  final int gridColumns;
  final void Function(Document) onDocumentTap;
  final void Function(String) onFavoriteToggle;
  final void Function(String) onDelete;

  const DocumentGridView({
    super.key,
    required this.documents,
    required this.gridColumns,
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
    
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(
          document: document,
          onTap: () => onDocumentTap(document),
          onFavoriteToggle: () => onFavoriteToggle(document.id),
          onDelete: () => onDelete(document.id),
        );
      },
    );
  }
}