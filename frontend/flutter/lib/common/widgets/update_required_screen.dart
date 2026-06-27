import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class UpdateRequiredScreen extends StatelessWidget {
  static const String routeName = "/updateRequired";
  const UpdateRequiredScreen({super.key});

  Future<void> _launchStore() async {
    final String url = Platform.isIOS
        ? 'https://apps.apple.com/app/idYOUR_APP_ID'
        : 'https://play.google.com/store/apps/details?id=com.creatorio.creatorio';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Update Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A new version of Creator.io is available! Please update to continue using the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _launchStore,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Update Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
