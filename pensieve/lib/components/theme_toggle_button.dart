import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        context.watch<ThemeProvider>().isDarkMode
          ? Icons.light_mode 
          : Icons.dark_mode
      ),
      onPressed: () {
        context.read<ThemeProvider>().toggleTheme();
      },
      tooltip: 'Cambiar tema',
    );
  }
}