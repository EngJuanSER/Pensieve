import 'package:flutter/material.dart';

class FontSizeDialog extends StatefulWidget {
  final double initialFontSize;
  final ValueChanged<double> onFontSizeChanged;

  const FontSizeDialog({
    super.key,
    required this.initialFontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<FontSizeDialog> createState() => FontSizeDialogState();
}

class FontSizeDialogState extends State<FontSizeDialog> {
  late double currentFontSize;

  @override
  void initState() {
    super.initState();
    currentFontSize = widget.initialFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return IntrinsicHeight(
          child: Dialog(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ajustar tamaño de fuente'),
                  const SizedBox(height: 8),
                  Text('Tamaño actual: ${currentFontSize.toStringAsFixed(1)}'),
                  Slider(
                    value: currentFontSize,
                    min: 8.0,
                    max: 50.0,
                    divisions: 42,
                    label: currentFontSize.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        currentFontSize = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround, // Centrar los botones
                    children: [
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          widget.onFontSizeChanged(currentFontSize);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}