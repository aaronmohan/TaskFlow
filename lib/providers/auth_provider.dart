import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService? _storageService;

  AuthProvider(this._authService, [this._storageService]) {
    restoreSession();
  }

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get token => _currentUser?.token ?? '';

  void restoreSession() {
    if (_storageService != null) {
      _currentUser = _storageService.getUser();
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      _currentUser = user;
      await _storageService?.saveUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _currentUser = user;
      await _storageService?.saveUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _storageService?.clearUser();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('SocketException') || str.contains('Failed host lookup')) {
      return 'Please check your internet connection.';
    }
    if (str.contains('FormatException')) {
      return str.replaceAll('FormatException: ', '');
    }
    if (str.contains('Exception: ')) {
      return str.replaceAll('Exception: ', '');
    }
    return 'Something went wrong. Try again.';
  }
}
