import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/firebase_constants.dart';
import '../models/user_model.dart';
import '../models/photographer_model.dart';
import '../models/service_package_model.dart';
import 'user_service.dart';
import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── Email / Password Sign-In ─────────────────────────────────────────────

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ─── Email / Password Register ────────────────────────────────────────────

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    File? profileImage,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    String? photoUrl;
    if (profileImage != null) {
      final ref = _storage.ref(FirebaseStoragePaths.profileImage(user.uid));
      await ref.putFile(
        profileImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrl = await ref.getDownloadURL();
    }

    await user.updateDisplayName(name.trim());
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    final userModel = UserModel(
      uid: user.uid,
      name: name.trim(),
      email: email.trim(),
      photoUrl: photoUrl,
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .set(userModel.toMap());

    // For photographers, create the discovery profile document
    if (role == 'photographer') {
      final photographerModel = PhotographerModel(
        uid: user.uid,
        name: name.trim(),
        photoUrl: photoUrl,
        bio: '',
        locationText: '',
        specialties: const [],
        primarySpecialty: '',
        rating: 0.0,
        reviewCount: 0,
        bookingCount: 0,
        profileViewCount: 0,
        photoCount: 0,
        isAvailable: true,
        isFeatured: false,
        isVerified: false,
        packages: _defaultPackages(),
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(FirebaseCollections.photographers)
          .doc(user.uid)
          .set(photographerModel.toMap());
    }

    // Seed user profile into cache and start FCM
    await UserService().fetchCurrentUser();
    await NotificationService().initFCM();
  }

  static List<ServicePackageModel> _defaultPackages() => [
        const ServicePackageModel(
          id: 'starter',
          name: 'Starter',
          duration: '2 hours',
          price: 150,
          features: ['30 edited photos', 'Online gallery', '1 location'],
        ),
        const ServicePackageModel(
          id: 'standard',
          name: 'Standard',
          duration: '4 hours',
          price: 300,
          features: [
            '80 edited photos',
            'Online gallery',
            '2 locations',
            'Prints included',
          ],
        ),
        const ServicePackageModel(
          id: 'premium',
          name: 'Premium',
          duration: 'Full day',
          price: 600,
          features: [
            '200+ edited photos',
            'Online gallery',
            'Unlimited locations',
            'Prints + album',
            'Rush delivery',
          ],
          isPopular: true,
        ),
      ];

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('google-sign-in-cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Only create Firestore document for brand-new Google users
    final doc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? googleUser.displayName ?? '',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL,
        role: 'client',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toMap());
    }

    await UserService().fetchCurrentUser();
    await NotificationService().initFCM();
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await NotificationService().removeFCMToken(uid);
    }
    UserService().clearCache();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Error Parser ─────────────────────────────────────────────────────────

  static String parseError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    if (error is Exception &&
        error.toString().contains('google-sign-in-cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
