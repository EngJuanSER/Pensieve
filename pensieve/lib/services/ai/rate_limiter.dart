import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../ai/models/ai_request.dart';

class RateLimiter {
  static final Map<String, bool> _activeRequests = {};
  static final Map<String, DateTime> _lastRequestTimes = {};
  
  static int _requestCount = 0;
  static DateTime? _lastRateLimitReset;
  static const int _maxRequestsPerMinute = 8;
  static final List<AIRequest> _requestQueue = [];
  static bool _isProcessingQueue = false;
  
  static Future<T?> enqueueRequest<T>(String requestId, Future<T?> Function() apiCall) async {
    // Evitar solicitudes duplicadas
    if (_activeRequests[requestId] == true) {
      debugPrint('🔄 Solicitud "$requestId" ya en proceso, ignorando duplicado');
      return null;
    }
    
    if (_lastRequestTimes.containsKey(requestId)) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTimes[requestId]!);
      if (timeSinceLastRequest.inSeconds < 5) {
        debugPrint('⏱️ Solicitud "$requestId" procesada recientemente, ignorando');
        return null;
      }
    }
    
    final request = AIRequest<T>(requestId, apiCall);
    _requestQueue.add(request);
    debugPrint('📥 Añadida a cola: $requestId (Total: ${_requestQueue.length})');
    
    if (!_isProcessingQueue) {
      _processQueue();
    }
    
    return request.completer.future;
  }
  
  static void _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    
    try {
      while (_requestQueue.isNotEmpty) {
        await _applyRateLimit();
        
        final request = _requestQueue.removeAt(0);
        final requestId = request.id;
        
        if (request.isExpired) {
          debugPrint('⏰ Solicitud expirada: $requestId');
          request.completer.complete(null);
          continue;
        }
        
        try {
          _activeRequests[requestId] = true;
          debugPrint('🚀 Procesando solicitud: $requestId');
          
          final result = await request.action().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏰ Timeout en solicitud: $requestId');
              throw TimeoutException('Timeout en solicitud: $requestId');
            }
          );
          
          request.completer.complete(result);
          
        } catch (e) {
          final isQuotaError = e.toString().contains('Resource has been exhausted');
          final isTimeout = e is TimeoutException;
          
          if ((isQuotaError || isTimeout) && request.retryCount < 2) {
            final backoffSeconds = math.pow(2, request.retryCount + 1).toInt();
            debugPrint('🔄 Reintentando solicitud $requestId después de $backoffSeconds segundos');
            request.retryCount++;
            
            await Future.delayed(Duration(seconds: backoffSeconds));
            _requestQueue.add(request); 
          } else {
            debugPrint('❌ Error en solicitud $requestId: $e');
            request.completer.complete(null);
          }
        } finally {
          _activeRequests.remove(requestId);
          _lastRequestTimes[requestId] = DateTime.now();
          debugPrint('✅ Finalizada solicitud: $requestId');
          
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }
  
  static Future<void> _applyRateLimit() async {
    final now = DateTime.now();
    
    // Reiniciar contador cada minuto
    if (_lastRateLimitReset == null || 
        now.difference(_lastRateLimitReset!).inMinutes >= 1) {
      _lastRateLimitReset = now;
      _requestCount = 0;
    }
    
    if (_requestCount >= _maxRequestsPerMinute) {
      final timeSinceReset = now.difference(_lastRateLimitReset!).inMilliseconds;
      if (timeSinceReset < 60000) {
        final waitTime = 60000 - timeSinceReset + 1000; 
        debugPrint('⏳ Límite de solicitudes alcanzado, esperando ${waitTime}ms');
        await Future.delayed(Duration(milliseconds: waitTime));
        _lastRateLimitReset = DateTime.now();
        _requestCount = 0;
      }
    }
    
    _requestCount++;
  }
}