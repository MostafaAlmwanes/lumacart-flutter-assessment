class Validators {
  const Validators._();

  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? username(String? value) {
    final String? requiredError = required(value, 'Username');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 3) {
      return 'Username must contain at least 3 characters.';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value.trim())) {
      return 'Use letters, numbers, dots, underscores, or hyphens only.';
    }
    return null;
  }

  static String? email(String? value) {
    final String? requiredError = required(value, 'Email');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final String? requiredError = required(value, 'Password');
    if (requiredError != null) return requiredError;
    if (value!.length < 8) return 'Password must contain at least 8 characters.';
    if (!RegExp('[A-Za-z]').hasMatch(value) ||
        !RegExp('[0-9]').hasMatch(value)) {
      return 'Password must include a letter and a number.';
    }
    return null;
  }

  static String? phone(String? value) {
    final String? requiredError = required(value, 'Phone');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[+0-9 ()-]{7,20}$').hasMatch(value!.trim())) {
      return 'Enter a valid phone number.';
    }
    return null;
  }
}
