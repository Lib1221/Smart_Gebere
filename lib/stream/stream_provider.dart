import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/splash/splash_screen.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;

  UserModel({required this.uid, this.email, this.displayName});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase User to UserModel
  UserModel? _userFromFirebaseUser(User? user) {
    return user != null
        ? UserModel(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          )
        : null;
  }

  // Auth Stream to listen for changes
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }
}

class StreamProviderClass extends StatelessWidget {
  const StreamProviderClass({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      value: AuthService().user,
      initialData: null,
      child: const SplashScreen(),
    );
  }
}

