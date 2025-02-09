import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:smart_gebere/Loading/loading.dart';
import 'package:smart_gebere/auth/login/login.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Gebere',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthStreamProvider(),
    );
  }
}

class AuthStreamProvider extends StatelessWidget {
  const AuthStreamProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<bool>(
          stream: authService.isAuthenticated,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingPage(); // Show loading screen while checking auth
            } else if (snapshot.hasData && snapshot.data == true) {
              return const Home_Screen(); // Redirect to home if authenticated
            } else {
              return LoginPage(); // Redirect to login if not authenticated
            }
          },
        );
      },
    );
  }
}

class AuthService extends ChangeNotifier {
  // Simulating a stream for user authentication
  Stream<bool> get isAuthenticated => Stream.value(true); // Always authenticated
}
