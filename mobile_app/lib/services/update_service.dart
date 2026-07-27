import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String _githubReleasesUrl = 'https://api.github.com/repos/Fellarity/mygate-app/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    // Only check for updates on Android devices
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(_githubReleasesUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String?;
        final assets = data['assets'] as List<dynamic>?;
        
        String? apkDownloadUrl;
        if (assets != null) {
          for (var asset in assets) {
            final name = asset['name'] as String?;
            if (name != null && name.endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        if (tagName != null && apkDownloadUrl != null) {
          String latestVersion = tagName.replaceAll('v', '');
          
          if (_isNewerVersion(currentVersion, latestVersion)) {
            _showUpdateDialog(context, latestVersion, apkDownloadUrl);
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

  static void _showUpdateDialog(BuildContext context, String newVersion, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDownloading = false;
        double progress = 0.0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isDownloading ? 'Downloading Update...' : 'Update Available'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDownloading) ...[
                    Text('A new version of the app (v$newVersion) is available!'),
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
                              'Note: You may need to enable "Install from Unknown Sources" in your device settings to install the update.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    LinearProgressIndicator(value: progress > 0 ? progress : null),
                    SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(1)}% Completed'),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Later', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => isDownloading = true);
                      
                      try {
                        final dir = await getExternalStorageDirectory();
                        if (dir == null) throw Exception("Cannot get storage directory");
                        
                        final filePath = '${dir.path}/update_v$newVersion.apk';
                        final file = File(filePath);

                        final client = http.Client();
                        final request = http.Request('GET', Uri.parse(apkUrl));
                        
                        // GitHub releases usually redirect, http package handles redirects automatically,
                        // but it might not handle progress well if redirects drop Content-Length.
                        // We will try our best.
                        final response = await client.send(request);

                        final totalBytes = response.contentLength ?? 0;
                        int receivedBytes = 0;
                        final sink = file.openWrite();

                        await response.stream.map((chunk) {
                          receivedBytes += chunk.length;
                          if (totalBytes > 0) {
                            setState(() {
                              progress = receivedBytes / totalBytes;
                            });
                          }
                          return chunk;
                        }).pipe(sink);

                        client.close();

                        // Launch installer
                        await OpenFilex.open(filePath);
                        
                        // Close dialog
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        setState(() => isDownloading = false);
                        debugPrint('Download error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to download update: $e')),
                          );
                        }
                      }
                    },
                    child: Text('Download & Install'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
