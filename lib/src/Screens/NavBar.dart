import 'package:flutter/material.dart';
// Import your page screens
import 'package:try_space/src/Screens/HomePage.dart';
import 'package:try_space/src/Screens/ComparisonScreen.dart';
import 'package:try_space/src/Screens/Profile.dart';

class NavBar extends StatefulWidget {
  final int initialIndex;

  const NavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static final List<Widget> _pages = <Widget>[
    HomePage(),
    ComparisonScreen(),
    Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 56, // Adjust height as needed
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.compare_arrows),
                label: 'Compare',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xFFFFC371), // Orange from gradient
            unselectedItemColor: Color(0xFFFF5F6D), // Red-pink from gradient
            backgroundColor: Colors.white, // White navbar background
            elevation: 0,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
