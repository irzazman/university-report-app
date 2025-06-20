import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'student_home_page.dart';
import 'staff_home_page.dart' as staff;
import 'biometric_service.dart';
import 'auth_token_service.dart';
import 'session_manager.dart' as session;
import 'activity_detector.dart' as activity;

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;

  const LoginPage({super.key, required this.showRegisterPage});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isBiometricAvailable = false;
  bool rememberMe = false;

  // Validation states
  String? emailError;
  String? passwordError;
  String? loginError;
  bool emailValid = false;
  bool passwordValid = false;
  bool showEmailError = false;
  bool showPasswordError = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _tryBiometricLogin();

    // Add listeners for real-time validation
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Start animation
    _animationController.forward();
  }

  Future<void> _checkBiometrics() async {
    final isAvailable = await BiometricService.isBiometricsAvailable();
    final biometricEnabled = await BiometricService.isBiometricEnabled();

    setState(() {
      isBiometricAvailable = isAvailable && biometricEnabled;
    });
  }

  Future<void> _tryBiometricLogin() async {
    if (await BiometricService.isBiometricEnabled()) {
      final email = await BiometricService.getSavedEmail();
      if (email != null) {
        final authenticated = await BiometricService.authenticate();
        if (authenticated) {
          _biometricSignIn(email);
        }
      }
    }
  }

  Future<void> _biometricSignIn(String email) async {
    setState(() => isLoading = true);
    try {
      // Authenticate with stored token
      final success = await AuthTokenService.signInWithToken();
      if (!success) {
        throw Exception("Token authentication failed");
      }

      // Get user role
      final userRole = await UserService.getCurrentUserRole();

      // Start user session
      session.SessionManager().startSession(context);

      // Navigate based on role
      if (mounted) {
        _navigateBasedOnRole(userRole);
      }
    } catch (e) {
      print("Error during biometric sign-in: $e");
      if (mounted) {
        setState(() {
          loginError =
              'Biometric login failed. Please sign in with your email and password.';
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> login() async {
    // Clear any previous errors
    setState(() {
      loginError = null;
    });

    // Validate inputs before proceeding
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) {
          emailError = 'Email is required';
          showEmailError = true;
        }
        if (password.isEmpty) {
          passwordError = 'Password is required';
          showPasswordError = true;
        }
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        emailError = 'Please enter a valid email address';
        showEmailError = true;
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      // First authenticate with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save auth credentials for biometric login if needed
      if (rememberMe && await BiometricService.isBiometricsAvailable()) {
        await BiometricService.setBiometricEnabled(true, email);
        await AuthTokenService.saveAuthToken();
        await AuthTokenService.savePassword(password);
      }

      // Get user's role from Firestore
      final userRole = await UserService.getCurrentUserRole();
      print(
        "Login: Navigating based on role: ${UserService.roleToString(userRole)}",
      );

      // Start user session
      session.SessionManager().startSession(context);

      // Navigate based on user role
      if (mounted) {
        _navigateBasedOnRole(userRole);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            loginError =
                'No account found with this email address. Please check your email or sign up for a new account.';
            break;
          case 'wrong-password':
            loginError =
                'Incorrect password. Please check your password and try again.';
            break;
          case 'invalid-email':
            emailError = 'Please enter a valid email address';
            showEmailError = true;
            loginError = null;
            break;
          case 'invalid-credential':
            loginError =
                'The email or password you entered is incorrect. Please check your credentials and try again.';
            break;
          case 'user-disabled':
            loginError =
                'This account has been disabled. Please contact support for assistance.';
            break;
          case 'too-many-requests':
            loginError =
                'Too many failed login attempts. Please wait a few minutes before trying again.';
            break;
          case 'network-request-failed':
            loginError =
                'Network error. Please check your internet connection and try again.';
            break;
          case 'email-already-in-use':
            loginError =
                'An account with this email already exists. Please sign in or use a different email.';
            break;
          case 'weak-password':
            passwordError =
                'Password is too weak. Please choose a stronger password.';
            showPasswordError = true;
            loginError = null;
            break;
          case 'operation-not-allowed':
            loginError =
                'Email/password accounts are not enabled. Please contact support.';
            break;
          case 'requires-recent-login':
            loginError = 'Please sign out and sign in again to continue.';
            break;
          default:
            // Handle generic "invalid-credential" or other auth errors with user-friendly messages
            if (e.message?.toLowerCase().contains('credential') == true ||
                e.message?.toLowerCase().contains('malformed') == true ||
                e.message?.toLowerCase().contains('expired') == true) {
              loginError =
                  'The email or password you entered is incorrect. Please check your credentials and try again.';
            } else if (e.message?.toLowerCase().contains('email') == true) {
              emailError = 'Please enter a valid email address';
              showEmailError = true;
              loginError = null;
            } else if (e.message?.toLowerCase().contains('password') == true) {
              loginError =
                  'Incorrect password. Please check your password and try again.';
            } else {
              loginError =
                  'Login failed. Please check your email and password and try again.';
            }
        }
      });
    } catch (e) {
      setState(() {
        loginError = 'An unexpected error occurred. Please try again';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Navigation method
  void _navigateBasedOnRole(UserRole role) {
    print(
      "Navigation method called with role: ${UserService.roleToString(role)}",
    );

    if (role == UserRole.staff) {
      print("Navigating to StaffHomePage");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) =>
                  const activity.ActivityDetector(child: staff.StaffHomePage()),
        ),
      );
    } else {
      print("Navigating to StudentHomePage");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) =>
                  const activity.ActivityDetector(child: StudentHomePage()),
        ),
      );
    }
  }

  // Validation methods
  void _validateEmail() {
    final email = emailController.text.trim();
    setState(() {
      // Clear login error when user starts typing
      if (loginError != null) {
        loginError = null;
      }

      if (email.isEmpty) {
        emailError = null;
        emailValid = false;
        showEmailError = false;
      } else if (!_isValidEmail(email)) {
        emailError = 'Please enter a valid email address';
        emailValid = false;
        showEmailError = true;
      } else {
        emailError = null;
        emailValid = true;
        showEmailError = false;
      }
    });
  }

  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      // Clear login error when user starts typing
      if (loginError != null) {
        loginError = null;
      }

      if (password.isEmpty) {
        passwordError = null;
        passwordValid = false;
        showPasswordError = false;
      } else if (password.length < 6) {
        passwordError = 'Password must be at least 6 characters';
        passwordValid = false;
        showPasswordError = true;
      } else {
        passwordError = null;
        passwordValid = true;
        showPasswordError = false;
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Animated Header section
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFF0070F0,
                                        ).withValues(alpha: 0.1),
                                        const Color(
                                          0xFF62BDD9,
                                        ).withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.login_rounded,
                                    size: 40,
                                    color: Color(0xFF0070F0),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue reporting campus issues',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Animated Form card
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      // Error message display
                                      if (loginError != null) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            border: Border.all(
                                              color: Colors.red.shade200,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red.shade600,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  loginError!,
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // Email field with enhanced validation
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            onChanged: (_) => _validateEmail(),
                                            decoration: InputDecoration(
                                              labelText: 'Email Address',
                                              prefixIcon: Icon(
                                                Icons.email_rounded,
                                                color:
                                                    showEmailError
                                                        ? Colors.red.shade400
                                                        : emailValid
                                                        ? Colors.green.shade400
                                                        : const Color(
                                                          0xFF0070F0,
                                                        ),
                                              ),
                                              suffixIcon:
                                                  emailController
                                                          .text
                                                          .isNotEmpty
                                                      ? Icon(
                                                        emailValid
                                                            ? Icons.check_circle
                                                            : showEmailError
                                                            ? Icons.error
                                                            : null,
                                                        color:
                                                            emailValid
                                                                ? Colors
                                                                    .green
                                                                    .shade400
                                                                : Colors
                                                                    .red
                                                                    .shade400,
                                                        size: 20,
                                                      )
                                                      : null,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      showEmailError
                                                          ? Colors.red.shade400
                                                          : emailValid
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : Colors
                                                              .grey
                                                              .shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      showEmailError
                                                          ? Colors.red.shade400
                                                          : emailValid
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : const Color(
                                                            0xFF0070F0,
                                                          ),
                                                  width: 2,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      showEmailError
                                                          ? Colors.red.shade400
                                                          : emailValid
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : Colors
                                                              .grey
                                                              .shade300,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (showEmailError &&
                                              emailError != null) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red.shade400,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    emailError!,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade600,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Password field with enhanced validation
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: passwordController,
                                            obscureText: true,
                                            onChanged:
                                                (_) => _validatePassword(),
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              prefixIcon: Icon(
                                                Icons.lock_rounded,
                                                color:
                                                    showPasswordError
                                                        ? Colors.red.shade400
                                                        : passwordValid
                                                        ? Colors.green.shade400
                                                        : const Color(
                                                          0xFF0070F0,
                                                        ),
                                              ),
                                              suffixIcon:
                                                  passwordController
                                                          .text
                                                          .isNotEmpty
                                                      ? Icon(
                                                        passwordValid
                                                            ? Icons.check_circle
                                                            : showPasswordError
                                                            ? Icons.error
                                                            : null,
                                                        color:
                                                            passwordValid
                                                                ? Colors
                                                                    .green
                                                                    .shade400
                                                                : Colors
                                                                    .red
                                                                    .shade400,
                                                        size: 20,
                                                      )
                                                      : null,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      showPasswordError
                                                          ? Colors.red.shade400
                                                          : passwordValid
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : Colors
                                                              .grey
                                                              .shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      showPasswordError
                                                          ? Colors.red.shade400
                                                          : passwordValid
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : const Color(
                                                            0xFF0070F0,
                                                          ),
                                                  width: 2,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      showPasswordError
                                                          ? Colors.red.shade400
                                                          : passwordValid
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : Colors
                                                              .grey
                                                              .shade300,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (showPasswordError &&
                                              passwordError != null) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red.shade400,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    passwordError!,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade600,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Animated checkbox
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 400),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: rememberMe,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    rememberMe = value ?? false;
                                                  });
                                                },
                                                activeColor: const Color(
                                                  0xFF0070F0,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Remember me and enable biometric login',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 32,
                                      ), // Enhanced login button with better feedback
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0070F0,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: isLoading ? 0 : 3,
                                            shadowColor: const Color(
                                              0xFF0070F0,
                                            ).withValues(alpha: 0.3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            disabledBackgroundColor:
                                                Colors.grey.shade300,
                                          ),
                                          child:
                                              isLoading
                                                  ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                        ),
                                      ),

                                      // Animated biometric login button
                                      if (isBiometricAvailable) ...[
                                        const SizedBox(height: 16),
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          width: double.infinity,
                                          height: 56,
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.fingerprint_rounded,
                                              size: 24,
                                            ),
                                            label: const Text(
                                              'Sign In with Biometric',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF0070F0,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFF0070F0),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            onPressed: _tryBiometricLogin,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Animated register link
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: widget.showRegisterPage,
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Color(0xFF0070F0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.removeListener(_validateEmail);
    passwordController.removeListener(_validatePassword);
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
