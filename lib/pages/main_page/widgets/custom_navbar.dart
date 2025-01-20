import 'package:flutter/material.dart';
import 'package:pomfretcardapp/theme.dart';
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;

  const CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final appBarColor = isDarkMode ? darkTheme.colorScheme.surface : lightTheme.colorScheme.surface;
    final selectedItemColor = isDarkMode ? darkTheme.colorScheme.primary : lightTheme.colorScheme.primary;
    final unselectedItemColor = isDarkMode
        ? darkTheme.colorScheme.onSurface.withOpacity(0.7)
        : lightTheme.colorScheme.onSurface.withOpacity(0.7);

    return Stack(
      children: [
        // Background for custom shape
        CustomPaint(
          size: Size(double.infinity, 80),
          painter: CurvedNavigationBarPainter(appBarColor),
        ),
        // Navigation items
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.credit_card,
                label: 'Card',
                isSelected: currentIndex == 0,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history,
                label: 'Transactions',
                isSelected: currentIndex == 1,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person,
                label: 'Profile',
                isSelected: currentIndex == 2,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color selectedItemColor,
    required Color unselectedItemColor,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: isSelected ? 6 : 0, // Highlight the selected item
            width: isSelected ? 36 : 0,
            decoration: BoxDecoration(
              color: selectedItemColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Icon(
            icon,
            color: isSelected ? selectedItemColor : unselectedItemColor,
            size: isSelected ? 28 : 24, // Slightly enlarge selected icon
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Aeonik',
              fontWeight: FontWeight.bold,
              fontSize: isSelected ? 14 : 12, // Dynamic font size
              color: isSelected ? selectedItemColor : unselectedItemColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for curved background
class CurvedNavigationBarPainter extends CustomPainter {
  final Color color;

  CurvedNavigationBarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(size.width / 2, -30, size.width, 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black12, 5.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
