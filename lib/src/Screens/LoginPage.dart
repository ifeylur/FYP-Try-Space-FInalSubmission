import 'package:flutter/material.dart';
import 'package:try_space/Utilities/Auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Auth _auth = Auth();
  bool _showPassword = false;

  final List<List<Color>> vibrantGradients = [
    [Color(0xFFFF5F6D), Color(0xFFFFC371)], // Red to orange
    [Color(0xFF36D1DC), Color(0xFF5B86E5)], // Turquoise to blue
    [
      Color.fromARGB(255, 2, 64, 45),
      Color.fromARGB(255, 23, 237, 173),
    ], // Green to Black
  ];
  int _gradientIndex = 0;

  @override
  void initState() {
    super.initState();
    _startGradientAnimation();
  }

  void _startGradientAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _gradientIndex = (_gradientIndex + 1) % vibrantGradients.length;
      });
      _startGradientAnimation();
    });
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset functionality goes here')),
    );
  }
  Future<void> handleGoogleSignIn(BuildContext context) async {
  _showLoadingDialog("Signing you in...");
  final user = await _auth.signInWithGoogle();
  if (user != null) {
    // Important: Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushReplacementNamed(context,'/navbar'
    );
  } else {
    // Handle sign-in failure
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in failed. Please try again.')),
    );
  }
}

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      _showLoadingDialog("Signing you in $email..");

      try {
        final user = await _auth.signInWithEmailAndPassword(email, password);

        // Close loading dialog
        Navigator.of(context).pop();

        if (user != null) {
          // Navigate to home page after successful login
          Navigator.pushReplacementNamed(context, '/navbar');
        } else {
          // Invalid credentials
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid email or password')));
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: vibrantGradients[_gradientIndex],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Try-Space',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  // Hanger icon
                  Icon(Icons.checkroom, size: 80, color: Colors.white),

                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.email, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || !value.contains('@')
                                ? 'Enter valid email'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.length < 6
                                ? 'Minimum 6 characters'
                                : null,
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "or continue with",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await handleGoogleSignIn(context);
                        },
                        child: _socialButton('assets/google.png'),
                      ),
                      SizedBox(width: 10),
                    ],
                  ),

                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String assetPath) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Flexible(child: Text(message)),
                ],
              ),
            ),
          ),
    );
  }
  
}
