class AiUserSession {
  static bool _isAdmin = false;
  static String? _centerId;

  static bool get isAdmin => _isAdmin;
  static String? get centerId => _centerId;

  static void setUser({
    required String? userRole,
    required String? userCenterId,
  }) {
    final role = (userRole ?? '').trim().toLowerCase();

    _isAdmin = role == 'admin';

    if (_isAdmin) {
      _centerId = null;
    } else {
      _centerId = userCenterId;
    }
  }

  static void clear() {
    _isAdmin = false;
    _centerId = null;
  }
}