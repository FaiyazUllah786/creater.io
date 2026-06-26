import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSelectionDialog extends StatefulWidget {
  const ThemeSelectionDialog({super.key});

  @override
  State<ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();
}

class _ThemeSelectionDialogState extends State<ThemeSelectionDialog> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = context.read<ThemeProvider>().themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
              child: Text(
                "Change theme",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            RadioMenuButton<ThemeMode>(
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (mode) => setState(() => _themeMode = mode!),
              child: const Text("System"),
            ),
            RadioMenuButton<ThemeMode>(
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (mode) => setState(() => _themeMode = mode!),
              child: const Text("Light"),
            ),
            RadioMenuButton<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (mode) => setState(() => _themeMode = mode!),
              child: const Text("Dark"),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: whiteColor,
                        backgroundColor: blackColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: whiteColor,
                      backgroundColor: redColor,
                    ),
                    onPressed: () {
                      context.read<ThemeProvider>().setTheme(_themeMode);
                      Navigator.pop(context);
                    },
                    child: const Text("Apply"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
