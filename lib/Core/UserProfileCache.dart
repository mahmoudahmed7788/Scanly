import 'package:shared_preferences/shared_preferences.dart';

class UserProfileCache {
  static const String _uidKey = 'cached_user_uid';
  static const String _nameKey = 'cached_user_name';
  static const String _firstNameKey = 'cached_first_name';
  static const String _lastNameKey = 'cached_last_name';
  static const String _emailKey = 'cached_user_email';
  static const String _onboardingCompletedKey =
      'cached_onboarding_completed';

  static Future<void> saveUser({
    required String uid,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_uidKey, uid);

    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_nameKey, name.trim());
    }

    if (firstName != null && firstName.trim().isNotEmpty) {
      await prefs.setString(_firstNameKey, firstName.trim());
    }

    if (lastName != null && lastName.trim().isNotEmpty) {
      await prefs.setString(_lastNameKey, lastName.trim());
    }

    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString(_emailKey, email.trim());
    }
  }

  static Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'uid': prefs.getString(_uidKey),
      'name': prefs.getString(_nameKey),
      'firstName': prefs.getString(_firstNameKey),
      'lastName': prefs.getString(_lastNameKey),
      'email': prefs.getString(_emailKey),
    };
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firstNameKey);
  }

  static Future<String?> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNameKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_uidKey);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  static Future<void> setOnboardingCompleted(
    bool completed,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _onboardingCompletedKey,
      completed,
    );
  }

  static Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return;
    }

    await prefs.setString(
      _nameKey,
      cleanName,
    );

    final parts = cleanName
        .split(' ')
        .where(
          (part) => part.trim().isNotEmpty,
        )
        .toList();

    if (parts.isNotEmpty) {
      await prefs.setString(
        _firstNameKey,
        parts.first,
      );
    }

    if (parts.length > 1) {
      await prefs.setString(
        _lastNameKey,
        parts.sublist(1).join(' ').trim(),
      );
    } else {
      await prefs.remove(_lastNameKey);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_uidKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_onboardingCompletedKey);
  }
}