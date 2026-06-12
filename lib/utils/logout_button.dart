import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:wsfm/services/ai/ai_user_session.dart';
import 'package:wsfm/utils/app_navigator_key.dart';

/// A polished user-session chip shown in the AppBar.
/// Tapping it opens a bottom sheet with account info and a logout action.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _LogoutSheet.show(context);
    if (confirmed != true) return;

    AiUserSession.clear();
    await FirebaseAuth.instance.signOut();
    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final initials = _initials(email);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _SessionChip(
        initials: initials,
        email: email,
        onTap: () => _logout(context),
      ),
    );
  }

  static String _initials(String email) {
    if (email.isEmpty) return '?';
    final name = email.split('@').first;
    final parts = name.split(RegExp(r'[._\-]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _SessionChip extends StatelessWidget {
  final String initials;
  final String email;
  final VoidCallback onTap;

  const _SessionChip({
    required this.initials,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B7A75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primary.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LogoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown account';
    const primary = Color(0xFF0B7A75);
    const danger = Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    LogoutButton._initials(email),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Signed in as',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sign out of your account?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll need to sign back in to access your dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Stay signed in',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}