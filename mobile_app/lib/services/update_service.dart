import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _githubReleasesUrl = 'https://api.github.com/repos/Fellarity/mygate-app/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    // Only check for updates on Android devices (not on Web or iOS)
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.4.0"

      final response = await http.get(Uri.parse(_githubReleasesUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String?; // e.g. "v1.4.0" or "v1.4"
        final htmlUrl = data['html_url'] as String?;

        if (tagName != null && htmlUrl != null) {
          String latestVersion = tagName.replaceAll('v', '');
          
          if (_isNewerVersion(currentVersion, latestVersion)) {
            _showUpdateDialog(context, latestVersion, htmlUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    List<int> currentParts = currentVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> latestParts = latestVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int current = i < currentParts.length ? currentParts[i] : 0;
      int latest = i < latestParts.length ? latestParts[i] : 0;

      if (latest > current) return true;
      if (latest < current) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String newVersion, String url) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to at least tap 'Cancel' or 'Update'
      builder: (context) {
        return AlertDialog(
          title: Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A new version of the app (v$newVersion) is available! Please update to get the latest features and bug fixes.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: You may need to enable "Install from Unknown Sources" in your device settings to install the downloaded APK.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text('Download Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
