import 'package:flutter/material.dart';
// Import your actual main page here
import 'package:pomfretcardapp/pages/main_page/main_page.dart';
import 'package:pomfretcardapp/theme.dart';

/// A helper function to create a slide transition route.
/// Adjust the [duration], [beginOffset], or [curve] as desired.
Route createSlideRoute({
  required Widget page,
  Duration duration = const Duration(milliseconds: 1000),
  Offset beginOffset = const Offset(1.0, 0.0), // slide in from the right
  Curve curve = Curves.easeInOut, // or Curves.easeInOutQuint, etc.
}) {
  return PageRouteBuilder(
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: beginOffset, end: Offset.zero)
          .chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class WelcomeBackPageWidget extends StatefulWidget {
  const WelcomeBackPageWidget({Key? key}) : super(key: key);

  @override
  State<WelcomeBackPageWidget> createState() => _WelcomeBackPageWidgetState();
}

class _WelcomeBackPageWidgetState extends State<WelcomeBackPageWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  // AnimationControllers
  late AnimationController _welcomeController;
  late AnimationController _nameController;
  late AnimationController _logoController;

  // Slide animations
  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<Offset> _nameSlideAnimation;

  // **Fade** animations for text
  late Animation<double> _welcomeFadeAnimation;
  late Animation<double> _nameFadeAnimation;

  // Scale animation for logo
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animation: "Welcome back," from the LEFT
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Slide in from the left
    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeInOutQuint,
      ),
    );

    // Fade in (0 -> 1)
    _welcomeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeInOutQuint,
      ),
    );

    // 2. Animation: Name from the RIGHT
    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Slide in from the right
    _nameSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _nameController,
        curve: Curves.easeInOutQuint,
      ),
    );

    // Fade in (0 -> 1)
    _nameFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _nameController,
        curve: Curves.easeInOutQuint,
      ),
    );

    // 3. Animation: Logo scale from (0,0) to (1,1)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScaleAnimation = Tween<double>(
      begin: 0.0, // completely invisible (0x, 0x)
      end: 1.0,   // full size (1x, 1x)
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOutQuint,
      ),
    );

    // ---- 300 ms DELAY BEFORE starting animations ----
    Future.delayed(const Duration(milliseconds: 50), () {
      Future.wait([
        _welcomeController.forward(),
        _nameController.forward(),
        _logoController.forward(),
      ]).then((_) async {
        // ---- 300 ms DELAY AFTER animations complete ----
        await Future.delayed(const Duration(milliseconds: 300));

        // Then navigate to '/mainPage'
        Navigator.pushReplacement(
          context,
          createSlideRoute(
            page: MainPage(themeNotifier: themeNotifier),
            duration: const Duration(milliseconds: 1000),
            beginOffset: const Offset(1.0, 0.0),
            curve: Curves.easeInOut,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _nameController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Top row for "Welcome back," and "Ilia!"
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Slide + Fade: "Welcome back,"
                        SlideTransition(
                          position: _welcomeSlideAnimation,
                          child: FadeTransition(
                            opacity: _welcomeFadeAnimation,
                            child: const Text(
                              'Welcome back,',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Aeonik',
                                color: Colors.black,
                                fontSize: 31,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Slide + Fade: "Ilia!"
                        SlideTransition(
                          position: _nameSlideAnimation,
                          child: FadeTransition(
                            opacity: _nameFadeAnimation,
                            child: const Text(
                              'Ilia!',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Aeonik',
                                color: Colors.redAccent,
                                fontSize: 37,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Spacer + Logo
                Expanded(
                  child: Align(
                    alignment: const AlignmentDirectional(0, -1),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Scale in the logo
                        Opacity(
                          opacity: 0.1,
                          child: Align(
                            alignment: const AlignmentDirectional(0, 0),
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: Image.asset(
                                  'assets/images/pomcard_icon_light.png',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
