import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:smart_gebere/Loading/loading.dart';
import 'package:smart_gebere/auth/login/login.dart';

class UserModel {
  final String uid;
  final String? email;

  UserModel({required this.uid, this.email});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase User to UserModel
  UserModel? _userFromFirebaseUser(User? user) {
    return user != null ? UserModel(uid: user.uid, email: user.email) : null;
  }

  // Auth Stream to listen for changes
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }
}

class StreamProviderClass extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      value: AuthService().user,
      initialData: null,
      child: Wrapper(),
    );
  }
}

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool showLoading = true; // Initially show the loading page

  @override
  void initState() {
    super.initState();

    // Simulate a delay before checking the user state
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showLoading = false; // Stop showing the loading page
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (showLoading) {
      return LoadingPage(); // Show loading for a few seconds
    }

    // After the delay, decide where to redirect
    return user == null ? LoginPage() : const Home_Screen();
  }
}
