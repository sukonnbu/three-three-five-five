import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String githubRepoOwner = 'sukonbu04299';
  static const String githubRepoName = 'ttff';
  static const String githubApiUrl =
      'https://api.github.com/repos/$githubRepoOwner/$githubRepoName/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');

        if (_compareVersions(latestVersion, currentVersion) > 0) {
          _showUpdateDialog(context, latestVersion, data['html_url']);
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.');
    final v2Parts = version2.split('.');

    for (int i = 0; i < v1Parts.length; i++) {
      if (i >= v2Parts.length) return 1;

      final v1Part = int.parse(v1Parts[i]);
      final v2Part = int.parse(v2Parts[i]);

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }

    return v1Parts.length == v2Parts.length ? 0 : -1;
  }

  static void _showUpdateDialog(
      BuildContext context, String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '업데이트 알림',
          style: TextStyle(
            fontFamily: "Pat",
            fontSize: 24,
          ),
        ),
        content: Text(
          '새로운 버전($latestVersion)이 있습니다. 업데이트하시겠습니까?',
          style: TextStyle(
            fontFamily: "Pat",
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '나중에',
              style: TextStyle(
                fontFamily: "Pat",
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(downloadUrl))) {
                await launchUrl(Uri.parse(downloadUrl));
              }
              Navigator.of(context).pop();
            },
            child: Text(
              '업데이트',
              style: TextStyle(
                fontFamily: "Pat",
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
