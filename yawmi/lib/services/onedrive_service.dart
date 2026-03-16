import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/day_task.dart';

class OneDriveService {
  static final OneDriveService instance = OneDriveService._();
  OneDriveService._();

  static const String _tenantId = 'common';
  static const String _scope    = 'Files.ReadWrite offline_access';
  static const String _fileName = 'wirdi_tasks.json';

  String _accessToken  = '';
  String _refreshToken = '';
  String _clientIdRuntime = '';

  bool get isSignedIn   => _accessToken.isNotEmpty;
  bool get isConfigured => _clientIdRuntime.isNotEmpty;
  String get _tasksUrl  => 'https://graph.microsoft.com/v1.0/me/drive/special/approot:/$_fileName:/content';

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _clientIdRuntime = prefs.getString('od_client_id') ?? '';
    _accessToken     = prefs.getString('od_access_token') ?? '';
    _refreshToken    = prefs.getString('od_refresh_token') ?? '';
  }

  Future<void> saveClientId(String clientId) async {
    _clientIdRuntime = clientId.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('od_client_id', _clientIdRuntime);
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken  = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('od_access_token', access);
    await prefs.setString('od_refresh_token', refresh);
  }

  Future<void> signOut() async {
    _accessToken = '';
    _refreshToken = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('od_access_token');
    await prefs.remove('od_refresh_token');
  }

  Future<Map<String, dynamic>?> requestDeviceCode() async {
    if (_clientIdRuntime.isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse('https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/devicecode'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'client_id': _clientIdRuntime, 'scope': _scope},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('Device code error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('requestDeviceCode error: $e');
      return null;
    }
  }

  Future<bool?> pollForToken(String deviceCode) async {
    if (_clientIdRuntime.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'client_id': _clientIdRuntime,
          'device_code': deviceCode,
        },
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['access_token'] != null) {
        await _saveTokens(data['access_token'], data['refresh_token'] ?? '');
        return true;
      }
      if (data['error'] == 'authorization_pending') return null;
      debugPrint('pollForToken error: ${data['error']}');
      return false;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken.isEmpty || _clientIdRuntime.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientIdRuntime,
          'refresh_token': _refreshToken,
          'scope': _scope,
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(data['access_token'], data['refresh_token'] ?? _refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  Future<http.Response?> _graphGet(String url) async {
    var r = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
    if (r.statusCode == 401) {
      if (!await _refreshAccessToken()) return null;
      r = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
    }
    return r;
  }

  Future<http.Response?> _graphPut(String url, String body) async {
    var r = await http.put(Uri.parse(url), headers: _headers, body: body).timeout(const Duration(seconds: 20));
    if (r.statusCode == 401) {
      if (!await _refreshAccessToken()) return null;
      r = await http.put(Uri.parse(url), headers: _headers, body: body).timeout(const Duration(seconds: 20));
    }
    return r;
  }

  Future<bool> uploadTasks(List<DayTask> tasks) async {
    if (!isSignedIn) return false;
    try {
      final body = jsonEncode(tasks.map((t) => t.toSupabaseMap()).toList());
      final r = await _graphPut(_tasksUrl, body);
      return r != null && r.statusCode >= 200 && r.statusCode < 300;
    } catch (e) {
      debugPrint('uploadTasks error: $e');
      return false;
    }
  }

  Future<List<DayTask>?> downloadTasks() async {
    if (!isSignedIn) return null;
    try {
      final r = await _graphGet(_tasksUrl);
      if (r == null) return null;
      if (r.statusCode == 404) return [];
      if (r.statusCode != 200) return null;
      final List<dynamic> data = jsonDecode(r.body);
      return data.map((row) => DayTask.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('downloadTasks error: $e');
      return null;
    }
  }

  Future<String?> getUserName() async {
    if (!isSignedIn) return null;
    try {
      final r = await _graphGet('https://graph.microsoft.com/v1.0/me?select=displayName');
      if (r?.statusCode == 200) return (jsonDecode(r!.body))['displayName'] as String?;
      return null;
    } catch (e) {
      return null;
    }
  }
}
