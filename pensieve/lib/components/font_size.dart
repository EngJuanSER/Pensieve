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
    return Dialog(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Tamaño de fuente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${currentFontSize.toInt()}',
              style: const TextStyle(fontSize: 14),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (currentFontSize > 8.0) {
                      setState(() {
                        currentFontSize--;
                        widget.onFontSizeChanged(currentFontSize);
                      });
                    }
                  },
                ),
                Expanded(
                  child: Slider(
                    value: currentFontSize,
                    min: 8.0,
                    max: 50.0,
                    divisions: 42,
                    onChanged: (double value) {
                      setState(() {
                        currentFontSize = value;
                        widget.onFontSizeChanged(value);
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (currentFontSize < 50.0) {
                      setState(() {
                        currentFontSize++;
                        widget.onFontSizeChanged(currentFontSize);
                      });
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}