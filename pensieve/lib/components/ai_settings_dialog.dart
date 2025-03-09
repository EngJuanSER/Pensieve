import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AISettingsDialog extends StatefulWidget {
  final Function()? onSettingsChanged;
  
  const AISettingsDialog({
    super.key, 
    this.onSettingsChanged,
  });

  @override
  State<AISettingsDialog> createState() => _AISettingsDialogState();
}

class _AISettingsDialogState extends State<AISettingsDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _obscureText = true;
  bool _hasApiKey = false;
  String? _currentApiKey;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    setState(() => _isLoading = true);
    
    try {
      _hasApiKey = await AIService.hasApiKey();
      if (_hasApiKey) {
        final currentKey = await AIService.getCurrentApiKey();
        if (currentKey.length > 4) {
          _currentApiKey = '••••••••' + currentKey.substring(currentKey.length - 4);
        } else {
          _currentApiKey = '••••••••';
        }
      }
    } catch (e) {
      debugPrint('Error al cargar la clave de API: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final success = await AIService.saveApiKey(_apiKeyController.text);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API Key guardada correctamente')),
          );
          
          await _loadApiKey(); 
          _apiKeyController.clear();
          
          if (widget.onSettingsChanged != null) {
            widget.onSettingsChanged!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar la API Key'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al guardar la API Key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la API Key'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Configuración de IA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_hasApiKey) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle, 
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'API Key configurada: $_currentApiKey',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.warning, 
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No hay API Key configurada',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.blueGrey.shade800 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkTheme ? Colors.blueGrey.shade700 : Colors.blue.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Qué es la API Key?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'La API Key es necesaria para utilizar las funciones de IA de esta aplicación, como la generación automática de etiquetas y descripciones para documentos.',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '¿Cómo obtener una API Key?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white70 : Colors.black87,
                            ),
                            children: [
                              const TextSpan(
                                text: '1. Visita ',
                              ),
                              TextSpan(
                                text: 'https://aistudio.google.com/app/apikey',
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(
                                text: '\n2. Inicia sesión con tu cuenta Google',
                              ),
                              const TextSpan(
                                text: '\n3. Crea una API Key (o usa una existente)',
                              ),
                              const TextSpan(
                                text: '\n4. Copia y pega la clave aquí abajo',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'Nueva API Key',
                      hintText: 'Ingresa tu clave de API de Google AI',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            tooltip: _obscureText ? 'Mostrar' : 'Ocultar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: _saveApiKey,
                            tooltip: 'Guardar API Key',
                          ),
                        ],
                      ),
                    ),
                    obscureText: _obscureText,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una API Key';
                      }
                      if (value.length < 10) {
                        return 'La API Key parece demasiado corta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}