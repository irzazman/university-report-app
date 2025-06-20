import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'user_service.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;

  const RegisterPage({Key? key, required this.showLoginPage}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  UserRole selectedRole = UserRole.student;
  bool isLoading = false;
  String selectedCountryCode = '+60';
  String selectedCountryDialCode = 'MY';

  // Validation states
  String? emailError;
  String? passwordError;
  String? phoneError;
  String? registrationError;
  bool emailValid = false;
  bool passwordValid = false;
  bool phoneValid = false;
  bool showEmailError = false;
  bool showPasswordError = false;
  bool showPhoneError = false;

  @override
  void initState() {
    super.initState();
  }

  // Validation methods
  void _validateEmail() {
    final email = emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        emailValid = false;
        showEmailError = false;
        emailError = null;
      } else if (_isValidEmail(email)) {
        emailValid = true;
        showEmailError = false;
        emailError = null;
      } else {
        emailValid = false;
        showEmailError = true;
        emailError = 'Please enter a valid email address';
      }
    });
  }

  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      if (password.isEmpty) {
        passwordValid = false;
        showPasswordError = false;
        passwordError = null;
      } else if (password.length >= 6) {
        passwordValid = true;
        showPasswordError = false;
        passwordError = null;
      } else {
        passwordValid = false;
        showPasswordError = true;
        passwordError = 'Password must be at least 6 characters';
      }
    });
  }

  void _validatePhone() {
    final phone = phoneController.text.trim();
    setState(() {
      if (phone.isEmpty) {
        phoneValid = false;
        showPhoneError = false;
        phoneError = null;
      } else if (phone.length >= 7 && RegExp(r'^[0-9]+$').hasMatch(phone)) {
        phoneValid = true;
        showPhoneError = false;
        phoneError = null;
      } else {
        phoneValid = false;
        showPhoneError = true;
        phoneError = 'Phone number must be at least 7 digits';
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<bool> _isPhoneNumberUnique(
    String phoneNumber,
    String countryCode,
  ) async {
    try {
      final fullPhoneNumber = '$countryCode$phoneNumber';
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phoneNumber', isEqualTo: fullPhoneNumber)
              .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("Error checking phone number uniqueness: $e");
      return false;
    }
  }

  Future<void> register() async {
    setState(() {
      registrationError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() {
        registrationError = 'Please fill in all fields';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        showEmailError = true;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        showPasswordError = true;
      });
      return;
    }

    if (phone.length < 7 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() {
        showPhoneError = true;
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final isPhoneUnique = await _isPhoneNumberUnique(
        phone,
        selectedCountryCode,
      );
      if (!isPhoneUnique) {
        setState(() {
          registrationError = 'This phone number is already registered';
        });
        return;
      }
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await UserService.setUserRoleWithPhone(
        selectedRole,
        phone,
        selectedCountryCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.showLoginPage();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'weak-password':
            registrationError = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            registrationError = 'An account already exists for that email.';
            break;
          case 'invalid-email':
            registrationError = 'The email address is not valid.';
            break;
          default:
            registrationError = 'Registration failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        registrationError = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Clean Header section
              Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0070F0), Color(0xFF62BDD9)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0070F0).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Join UTeM Reporter',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to start reporting campus issues',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Clean Form container
              Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message display
                    if (registrationError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                registrationError!,
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
                      const SizedBox(height: 24),
                    ],

                    // Email field
                    Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              showEmailError
                                  ? Colors.red.shade300
                                  : emailValid
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                        color: Color(0xFFFAFBFC),
                      ),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => _validateEmail(),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.email_rounded,
                              color:
                                  showEmailError
                                      ? Colors.red.shade400
                                      : emailValid
                                      ? Colors.green.shade400
                                      : Color(0xFF0070F0),
                              size: 22,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 50,
                            maxWidth: 50,
                          ),
                          suffixIcon:
                              emailController.text.isNotEmpty
                                  ? Container(
                                    width: 24,
                                    height: 24,
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          emailValid
                                              ? Colors.green.shade400
                                              : showEmailError
                                              ? Colors.red.shade400
                                              : Colors.transparent,
                                    ),
                                    child: Icon(
                                      emailValid
                                          ? Icons.check
                                          : showEmailError
                                          ? Icons.close
                                          : null,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  )
                                  : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showEmailError && emailError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              emailError!,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Password field
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              showPasswordError
                                  ? Colors.red.shade300
                                  : passwordValid
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                        color: Color(0xFFFAFBFC),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        onChanged: (_) => _validatePassword(),
                        decoration: InputDecoration(
                          hintText: 'Enter password (minimum 6 characters)',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.lock_rounded,
                              color:
                                  showPasswordError
                                      ? Colors.red.shade400
                                      : passwordValid
                                      ? Colors.green.shade400
                                      : Color(0xFF0070F0),
                              size: 22,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 50,
                            maxWidth: 50,
                          ),
                          suffixIcon:
                              passwordController.text.isNotEmpty
                                  ? Container(
                                    width: 24,
                                    height: 24,
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          passwordValid
                                              ? Colors.green.shade400
                                              : showPasswordError
                                              ? Colors.red.shade400
                                              : Colors.transparent,
                                    ),
                                    child: Icon(
                                      passwordValid
                                          ? Icons.check
                                          : showPasswordError
                                          ? Icons.close
                                          : null,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  )
                                  : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showPasswordError && passwordError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              passwordError!,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Phone number field
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              showPhoneError
                                  ? Colors.red.shade300
                                  : phoneValid
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                        color: Color(0xFFFAFBFC),
                      ),
                      child: Row(
                        children: [
                          // Country code picker
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: CountryCodePicker(
                              onChanged: (country) {
                                setState(() {
                                  selectedCountryCode =
                                      country.dialCode ?? '+60';
                                  selectedCountryDialCode =
                                      country.code ?? 'MY';
                                });
                              },
                              initialSelection: selectedCountryDialCode,
                              favorite: const [
                                '+60',
                                'MY',
                                '+65',
                                'SG',
                                '+1',
                                'US',
                              ],
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                              flagWidth: 22,
                              boxDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              builder: (country) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.asset(
                                          country!.flagUri!,
                                          package: 'country_code_picker',
                                          width: 22,
                                          height: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        country.dialCode!,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFF0070F0),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Phone number input
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                onChanged: (_) => _validatePhone(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your phone number',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                  suffixIcon:
                                      phoneController.text.isNotEmpty
                                          ? Container(
                                            width: 24,
                                            height: 24,
                                            margin: EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  phoneValid
                                                      ? Colors.green.shade400
                                                      : showPhoneError
                                                      ? Colors.red.shade400
                                                      : Colors.transparent,
                                            ),
                                            child: Icon(
                                              phoneValid
                                                  ? Icons.check
                                                  : showPhoneError
                                                  ? Icons.close
                                                  : null,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          )
                                          : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showPhoneError && phoneError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phoneError!,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Role selection
                    Text(
                      'User Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserRole>(
                          isExpanded: true,
                          value: selectedRole,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF0070F0),
                            size: 24,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: UserRole.student,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        0xFF0070F0,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: Color(0xFF0070F0),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Student',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        'Report campus issues',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: UserRole.staff,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        0xFF62BDD9,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.work_rounded,
                                      color: Color(0xFF62BDD9),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Staff',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        'Manage issues',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (role) {
                            if (role != null) {
                              setState(() => selectedRole = role);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Account button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors:
                              isLoading
                                  ? [Colors.grey.shade300, Colors.grey.shade400]
                                  : [Color(0xFF0070F0), Color(0xFF0052CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow:
                            isLoading
                                ? []
                                : [
                                  BoxShadow(
                                    color: Color(
                                      0xFF0070F0,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                      ),
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.transparent,
                        ),
                        child:
                            isLoading
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Creating Account...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  TextButton(
                    onPressed: widget.showLoginPage,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF0070F0),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
