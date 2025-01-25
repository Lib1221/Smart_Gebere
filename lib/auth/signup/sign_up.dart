import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:smart_gebere/auth/login/login.dart'; // Import the LoginPage for navigation

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<String> _countries = [];
  String? _selectedCountry;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    const url = 'https://restcountries.com/v3.1/all';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _countries = (data as List)
              .map((country) => country['name']['common'] as String)
              .toList()
            ..sort();
        });
      } else {
        throw Exception("Failed to load countries");
      }
    } catch (e) {
      _showErrorDialog("Failed to load countries: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Welcome Text and Login Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Welcome to Smart Gebere",
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Empowering Farmers with Smart Solutions",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 210, 207, 207),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Text(
                      "Create Account",
                      style: GoogleFonts.lobster(
                        textStyle: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _firstNameController,
                              label: "First Name",
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _lastNameController,
                              label: "Last Name",
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildCountryDropdown(),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: "Phone Number",
                              icon: Icons.phone,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label: "Email",
                              icon: Icons.email,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock,
                              isPassword: true,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: "Confirm Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _handleSignup();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 8,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.black45,
                              ).copyWith(
                                foregroundColor: MaterialStateProperty.all(Colors.white),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade400, Colors.green.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 50,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        )
                                      : Text(
                                          "Sign Up",
                                          style: GoogleFonts.poppins(
                                            textStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Login Redirect
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => LoginPage()),
                                    );
                                  },
                                  child: Text(
                                    "Login",
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (isPassword && controller == _confirmPasswordController) {
          if (controller.text != _passwordController.text) {
            return 'Passwords do not match';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      items: _countries.map((country) {
        return DropdownMenuItem(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
        });
      },
      decoration: InputDecoration(
        labelText: "Country",
        prefixIcon: Icon(Icons.public, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a country';
        }
        return null;
      },
    );
  }

 Future<void> _handleSignup() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Create user with email and password using Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Get the UID of the created user
    String userId = userCredential.user!.uid;

    // Get user data from form fields
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String email = _emailController.text;
    String phone = _phoneController.text;
    String country = _selectedCountry ?? 'Not selected';

    // Save user data to Firestore under a collection called 'user_data'
    await FirebaseFirestore.instance.collection('user_data').doc(userId).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'country': country,
      'uid': userId,
      'createdAt': Timestamp.now(), // Store the creation timestamp
    });

    // Navigate to the Home Screen after successful signup
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home_Screen()),
    );
  } on FirebaseAuthException catch (e) {
    // Show error message if signup fails
    _showErrorDialog(e.message ?? 'An error occurred. Please try again.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signup Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    var secondControlPoint = Offset(3 * size.width / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
