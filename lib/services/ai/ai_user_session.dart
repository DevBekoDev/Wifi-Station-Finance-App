class AiUserSession {
  static String? role;
  static String? centerId;

  static void setUser({
    required String userRole,
    String? userCenterId,
  }) {
    role = userRole;
    centerId = userCenterId;
  }

  static void clear() {
    role = null;
    centerId = null;
  }

  static bool get isManager => role == 'manager';
  static bool get isAdmin => role == 'admin';
}