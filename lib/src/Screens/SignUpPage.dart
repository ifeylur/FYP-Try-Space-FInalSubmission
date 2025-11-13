import 'package:flutter/material.dart';
import 'package:try_space/Utilities/Auth.dart';
import 'package:try_space/Providers/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:try_space/Models/UserModel.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final Auth _auth = Auth();
  String? _selectedGender;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final List<List<Color>> vibrantGradients = [
    [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    [Color(0xFF36D1DC), Color(0xFF5B86E5)],
    [Color.fromARGB(255,2,64,45), Color.fromARGB(255,23,237,173)], // Green to Black
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

Future<void> _register() async {
  if (_formKey.currentState!.validate()) {
    final name = "${_firstNameController.text} ${_lastNameController.text}";
    
    // Show loading dialog instead of snackbar
    _showLoadingDialog('Registering $name...');
    
    try {
      final user = await _auth.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Create UserModel without profileImageUrl for now (empty string or default)
        final newUser = UserModel(
          uid: user.uid,
          name: name,
          email: user.email ?? '',
          profileImageUrl: '',
        );

        // Save user data to Firestore using Provider
        await Provider.of<UserProvider>(context, listen: false).addUserToFirestore(newUser);

        // Close loading dialog before showing success dialog
        Navigator.of(context).pop();

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("Account created successfully!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog before showing error
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(padding: EdgeInsets.only(bottom: 60),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                    ),
                  ),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: _inputDecoration('Select Gender', Icons.wc),
                    dropdownColor: Colors.blue.shade100,
                    items:
                        ['Male', 'Female', 'Other']
                            .map(
                              (gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() {
                          _selectedGender = value;
                        }),
                    validator:
                        (value) =>
                            value == null ? 'Please select a gender' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    isConfirm: false,
                  ),
                  const SizedBox(height: 16),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    isConfirm: true,
                    validator:
                        (value) =>
                            value != _passwordController.text
                                ? 'Passwords do not match'
                                : null,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Register'),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
      validator:
          (value) => value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isConfirm,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isConfirm ? !_showConfirmPassword : !_showPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        prefixIcon: Icon(Icons.lock, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(
            (isConfirm ? _showConfirmPassword : _showPassword)
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                _showConfirmPassword = !_showConfirmPassword;
              } else {
                _showPassword = !_showPassword;
              }
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator:
          validator ??
          (value) =>
              value == null || value.length < 6 ? 'Minimum 6 characters' : null,
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
