class ValidationService {
  /// Validates the signup form fields
  /// Returns a ValidationResult object containing validation status and error message if any
  static ValidationResult validateSignupForm({
    required String name,
    required String email,
    required String password,
    required String retypePassword,
  }) {
    // Check if any field is empty
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        retypePassword.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Missing Information",
        errorMessage: "Please fill in all fields to continue.",
      );
    }

    // Validate name length
    if (name.trim().length <= 2) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Invalid Name",
        errorMessage: "Your name should be longer than 2 characters.",
      );
    }

    // Check for spaces in email
    if (email.contains(' ')) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Invalid Email",
        errorMessage: "Email address cannot contain spaces.",
      );
    }

    // Validate email format
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Invalid Email",
        errorMessage: "Please enter a valid email address.",
      );
    }

    // Check for spaces in password
    if (password.contains(' ')) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Invalid Password",
        errorMessage: "Password cannot contain spaces.",
      );
    }

    // Check password length
    if (password.length < 6) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Weak Password",
        errorMessage: "Password must be at least 6 characters long.",
      );
    }

    // Check if passwords match
    if (password != retypePassword) {
      return ValidationResult(
        isValid: false,
        errorTitle: "Passwords Don't Match",
        errorMessage: "Your passwords don't match. Please try again.",
      );
    }

    // All validations passed
    return ValidationResult(isValid: true);
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorTitle;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorTitle, this.errorMessage});
}
