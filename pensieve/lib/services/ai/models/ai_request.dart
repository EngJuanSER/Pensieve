import 'dart:async';

class AIRequest<T> {
  final String id;
  
  final Future<T?> Function() action;
  
  final Completer<T?> completer = Completer<T?>();
  
  final DateTime queuedAt = DateTime.now();
  
  int retryCount = 0;
  
  AIRequest(this.id, this.action);
  
  bool get isExpired => DateTime.now().difference(queuedAt).inMinutes > 5;
  
  int get priority {
    if (id.startsWith('desc_')) return 1;
    if (id.startsWith('tags_')) return 2;
    return 3;
  }
}