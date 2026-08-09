import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;
}

class AuthState {
  const AuthState({this.tokens, this.user, this.loading = false});

  final AuthTokens? tokens;
  final AuthUser? user;
  final bool loading;

  bool get isAuthenticated => tokens?.accessToken.isNotEmpty == true;

  AuthState copyWith({AuthTokens? tokens, AuthUser? user, bool? loading, bool clearUser = false, bool clearTokens = false}) {
    return AuthState(
      tokens: clearTokens ? null : (tokens ?? this.tokens),
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
    );
  }
}

class AuthSession extends StateNotifier<AuthState> {
  AuthSession(this._client) : super(const AuthState(loading: true)) {
    _restore();
  }

  static const _accessKey = 'rawaya_access_token';
  static const _refreshKey = 'rawaya_refresh_token';

  final ApiClient _client;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);
    if (access == null || access.isEmpty) {
      state = const AuthState();
      return;
    }
    state = AuthState(tokens: AuthTokens(accessToken: access, refreshToken: refresh ?? ''));
    await refreshProfile();
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      await _persistTokens(response.data);
      await refreshProfile();
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> register({required String email, required String password, required String displayName}) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'displayName': displayName.trim(),
        },
      );
      await _persistTokens(response.data);
      await refreshProfile();
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> refreshProfile() async {
    final access = state.tokens?.accessToken;
    if (access == null || access.isEmpty) {
      state = state.copyWith(clearUser: true, loading: false);
      return;
    }
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/users/me',
        accessToken: access,
      );
      final data = response.data ?? {};
      final profile = data['profile'] as Map?;
      state = state.copyWith(
        user: AuthUser(
          id: data['id']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          displayName: profile?['displayName']?.toString() ?? profile?['fullName']?.toString(),
        ),
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> logout() async {
    final refresh = state.tokens?.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _client.post<Map<String, dynamic>>('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    state = const AuthState();
  }

  Future<void> _persistTokens(Map<String, dynamic>? data) async {
    final access = data?['accessToken']?.toString() ?? '';
    final refresh = data?['refreshToken']?.toString() ?? '';
    if (access.isEmpty) {
      throw Exception('لم يُرجع الخادم رمز الدخول');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    state = state.copyWith(tokens: AuthTokens(accessToken: access, refreshToken: refresh));
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authSessionProvider = StateNotifierProvider<AuthSession, AuthState>((ref) {
  return AuthSession(ref.watch(apiClientProvider));
});
