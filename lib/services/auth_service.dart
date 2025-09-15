import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Register Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Register Error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Update email verification status in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': user.emailVerified,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Login Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('SignOut Error: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Send Verification Email Error: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        // Update email verification status in Firestore
        if (user.emailVerified) {
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });
        }
      }
    } catch (e) {
      print('Reload User Error: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
