class AppValidators {
  static String? validateUsername(String? userName) {
    if (userName == null || userName.trim().isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Not a valid email';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Password is required';
    } else if (password.length < 6) {
      return 'Password must contain 6 or more characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }
}
