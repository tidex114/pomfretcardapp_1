import 'package:flutter/material.dart';
import 'package:pomfretcardapp/theme.dart';

class WelcomeBackPageWidget extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const WelcomeBackPageWidget({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  State<WelcomeBackPageWidget> createState() => _WelcomeBackPageWidgetState();
}

class _WelcomeBackPageWidgetState extends State<WelcomeBackPageWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _welcomeController;
  late AnimationController _nameController;
  late AnimationController _logoController;

  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<Offset> _nameSlideAnimation;

  late Animation<double> _welcomeFadeAnimation;
  late Animation<double> _nameFadeAnimation;

  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeInOutQuint,
      ),
    );

    _welcomeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeInOutQuint,
      ),
    );

    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _nameSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _nameController,
        curve: Curves.easeInOutQuint,
      ),
    );

    _nameFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _nameController,
        curve: Curves.easeInOutQuint,
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOutQuint,
      ),
    );

    Future.delayed(const Duration(milliseconds: 50), () {
      Future.wait([
        _welcomeController.forward(),
        _nameController.forward(),
        _logoController.forward(),
      ]).then((_) async {
        await Future.delayed(const Duration(milliseconds: 600));

        Navigator.pushReplacementNamed(
          context,
          '/mainPage',
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final logoAsset = isDarkMode ? 'assets/images/pomcard_icon_dark.png' : 'assets/images/pomcard_icon_light.png';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SlideTransition(
                          position: _welcomeSlideAnimation,
                          child: FadeTransition(
                            opacity: _welcomeFadeAnimation,
                            child: Text(
                              'Welcome back,',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Aeonik',
                                color: theme.colorScheme.onSurface,
                                fontSize: 31,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SlideTransition(
                          position: _nameSlideAnimation,
                          child: FadeTransition(
                            opacity: _nameFadeAnimation,
                            child: Text(
                              'Ilia!',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Aeonik',
                                color: theme.colorScheme.primary,
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
                Expanded(
                  child: Align(
                    alignment: const AlignmentDirectional(0, -1),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: 0.1,
                          child: Align(
                            alignment: const AlignmentDirectional(0, 0),
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: Image.asset(
                                  logoAsset,
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