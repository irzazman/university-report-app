import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { student, staff }

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert enum to string
  static String roleToString(UserRole role) {
    return role.toString().split('.').last;
  }

  // Convert string to enum
  static UserRole stringToRole(String? roleStr) {
    if (roleStr == null) return UserRole.student;

    switch (roleStr.trim().toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  // Get current user role
  static Future<UserRole> getCurrentUserRole() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print("getCurrentUserRole: No user logged in");
        throw Exception('No user logged in');
      }

      print(
        "getCurrentUserRole: Getting role for user ${user.email} (${user.uid})",
      );

      // Query Firestore for user document
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server)); // Force server read

      // If user doesn't exist in database, create with default role
      if (!userDoc.exists) {
        print(
          "getCurrentUserRole: User document doesn't exist, creating with student role",
        );
        await setUserRole(UserRole.student);
        return UserRole.student;
      }

      // Extract role from document
      final data = userDoc.data() as Map<String, dynamic>;
      final roleStr = data['role'] as String?;

      print("getCurrentUserRole: Found role string: $roleStr");
      print("Document data: ${userDoc.data()}");
      print("Role as stored: '${data['role']}'");

      final role = stringToRole(roleStr ?? 'student');
      print("getCurrentUserRole: Returning role: $role");
      return role;
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.student; // Default role
    }
  }

  // Set user role
  static Future<void> setUserRole(UserRole role) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': roleToString(role),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting user role: $e');
      throw e;
    }
  }

  // Set user role with phone number
  static Future<void> setUserRoleWithPhone(
    UserRole role,
    String phoneNumber,
    String countryCode,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      print(
          "Storing user with phone: $countryCode$phoneNumber (separate fields: countryCode=$countryCode, phoneNumber=$phoneNumber)");

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': roleToString(role),
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'fullPhoneNumber':
            '$countryCode$phoneNumber', // Store both for flexibility
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting user role with phone: $e');
      throw e;
    }
  }

  // Get current user phone number
  static Future<Map<String, String>?> getCurrentUserPhone() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print("getCurrentUserPhone: No user logged in");
        return null;
      }

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        print("getCurrentUserPhone: User document doesn't exist");
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final phoneNumber = data['phoneNumber'] as String?;
      final countryCode = data['countryCode'] as String?;

      if (phoneNumber != null && countryCode != null) {
        return {
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
          'fullNumber': '$countryCode$phoneNumber',
        };
      }

      return null;
    } catch (e) {
      print('Error getting user phone: $e');
      return null;
    }
  }
}
