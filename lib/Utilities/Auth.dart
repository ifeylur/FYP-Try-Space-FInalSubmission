import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:try_space/Models/UserModel.dart';
import 'package:try_space/Providers/UserProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      return userCredential.user;
    } catch (error) {
      print("Error signing in: $error");
      return null;
    }
  }

  // Register with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();
        print("Verification email sent!");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // ✅ Do NOT sign out immediately
        return user;
      } else {
        return null;
      }
    } catch (error) {
      print("Error registering user: $error");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user canceled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    User? firebaseUser = userCredential.user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    final UserModel newUser = UserModel(
      uid: firebaseUser!.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      profileImageUrl: '',
    );

    await UserProvider().addUserToFirestore(newUser);

    return firebaseUser;
  } catch (error) {
    print("Google Sign-In error: $error");
    return null;
  }
}
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
 bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
  // Get the current user
  User? getCurrentUser() {
  try {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
}
String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
