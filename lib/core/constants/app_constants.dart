abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String map = '/map';
  static const String trips = '/trips';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String tripDetail = '/trip';
  static const String createRide = '/create-ride';
  static const String notifications = '/notifications';
  static const String search = '/search';
}

abstract class AppStrings {
  static const String appName = 'RideLeaf';
  static const String tagline = 'The Ecological Concierge';
  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle = 'Please enter your details to sign in.';
  static const String createAccount = 'Create Account';
  static const String startJourney = 'Start your ecological journey today.';
  static const String emailLabel = 'EMAIL ADDRESS';
  static const String passwordLabel = 'PASSWORD';
  static const String fullNameLabel = 'FULL NAME';
  static const String phoneLabel = 'PHONE NUMBER';
  static const String forgotPassword = 'Forgot Password?';
  static const String loginButton = 'Login';
  static const String createAccountButton = 'Create Account';
  static const String orContinueWith = 'OR CONTINUE WITH';
  static const String noAccount = "Don't have an account?";
  static const String signUp = 'Sign up';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String rememberMe = 'Stay signed in for 30 days';
  static const String terms =
      'I agree to the Terms and Conditions and Privacy Policy.';
  static const String resetPassword = 'Reset Password';
  static const String resetPasswordSubtitle =
      "Enter your email and we'll send you a reset link.";
  static const String sendResetLink = 'Send Reset Link';
  static const String checkYourEmail = 'Check your email';
  static const String resetEmailSent =
      'A password reset link has been sent to your email.';
  static const String emailRequired = 'Email is required.';
  static const String emailInvalid = 'Enter a valid email address.';
  static const String passwordRequired = 'Password is required.';
  static const String passwordTooShort =
      'Password must be at least 6 characters.';
  static const String nameRequired = 'Full name is required.';
  static const String phoneRequired = 'Phone number is required.';
  static const String termsRequired =
      'You must accept the Terms and Conditions.';
  static const String certifiedCarbon = 'CERTIFIED CARBON\nNEUTRAL';
  static const String securePlatform = 'SECURE\nPLATFORM';
  static const String version = 'VERSION 1.0.0  •  ECO-CERTIFIED';
}
