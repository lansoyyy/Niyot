import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

GoogleSignIn createGoogleSignIn() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return GoogleSignIn(
      clientId: DefaultFirebaseOptions.ios.iosClientId,
    );
  }
  return GoogleSignIn();
}
