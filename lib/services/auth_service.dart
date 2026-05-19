import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  Session? _session;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Session? get session => _session;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null;
  String? get error => _error;
  String? get userId => _user?.id;
  String? get accessToken => _session?.accessToken;

  AuthService() {
    _session = _supabase.auth.currentSession;
    _user = _supabase.auth.currentUser;

    _supabase.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? title,
    String? organization,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'title': title,
          'organization': organization,
        },
      );

      if (response.user != null) {
        // Create profile record
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'title': title,
          'organization': organization,
        });

        _user = response.user;
        _session = response.session;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Signup failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = response.user;
      _session = response.session;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    _session = null;
    notifyListeners();
  }

  Future<bool> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      _session = response.session;
      _user = response.user;
      notifyListeners();
      return _session != null;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (_user == null) return null;
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? title,
    String? organization,
  }) async {
    if (_user == null) return false;
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (title != null) data['title'] = title;
      if (organization != null) data['organization'] = organization;

      await _supabase
          .from('profiles')
          .update(data)
          .eq('id', _user!.id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
