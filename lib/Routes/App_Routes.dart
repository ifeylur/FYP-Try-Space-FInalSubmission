import 'package:flutter/material.dart';
import 'package:try_space/src/Screens/Profile.dart';
import 'package:try_space/src/Screens/EditProfile.dart';
import 'package:try_space/src/Screens/RegisterPage.dart';
import 'package:try_space/src/Screens/ComparisonScreen.dart';
// import 'package:try_space/src/Screens/ResultScreen.dart';
// import 'package:try_space/src/Screens/TryOnScreen.dart';
import 'package:try_space/src/Screens/SignUpPage.dart';
import 'package:try_space/src/Screens/HomePage.dart';
import 'package:try_space/src/Screens/LoginPage.dart';
import 'package:try_space/src/Screens/NavBar.dart';


class AppRoutes {
  static const String signup = '/signup';
  static const String comparison = '/comparison';
  static const String tryon = '/tryon';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String result = '/result';
  static const String profile = '/profile';
  static const String editprofile = '/editprofile';
  static const String navbar = '/navbar';


  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginPage(),
    register: (context) => RegisterPage(),
    home: (context) => HomePage(),
    signup: (context) => SignUpPage(),
    comparison: (context) => ComparisonScreen(),
    profile: (context) => Profile(),
    editprofile: (context) => EditProfile(),
    navbar: (context) => NavBar(),
  };
}
