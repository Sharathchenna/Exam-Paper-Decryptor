import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:decryptor/screens/home_screen.dart';
import 'package:decryptor/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for Windows
  await windowManager.ensureInitialized();

  // Configure window properties
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // Apply window options
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Try to initialize window effects if supported
  try {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: AppTheme.backgroundColor.withValues(alpha: .8),
    );
  } catch (e) {
    // Acrylic effect not supported, fallback to regular window
    print('Window effects not supported: $e');
  }

  runApp(const DecryptorApp());
}

class DecryptorApp extends StatefulWidget {
  const DecryptorApp({super.key});

  @override
  State<DecryptorApp> createState() => _DecryptorAppState();
}

class _DecryptorAppState extends State<DecryptorApp> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Decryptor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const DecryptorWindow(),
    );
  }

  // Window listener method for maximize button
  @override
  void onWindowMaximize() {
    setState(() {});
  }

  // Window listener method for restore button
  @override
  void onWindowUnmaximize() {
    setState(() {});
  }
}

class DecryptorWindow extends StatelessWidget implements PreferredSizeWidget {
  const DecryptorWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom window title bar
          WindowTitleBar(),
          // Main content
          const Expanded(child: HomeScreen()),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(38);
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: Container(
        height: 38,
        color: AppTheme.primaryColor,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.lock_open, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'PDF Decryptor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Window control buttons
            Row(
              children: [
                // Minimize button
                WindowButton(
                  icon: Icons.minimize,
                  onPressed: () {
                    windowManager.minimize();
                  },
                ),
                // Maximize/Restore button
                FutureBuilder<bool>(
                  future: windowManager.isMaximized(),
                  builder: (context, snapshot) {
                    final isMaximized = snapshot.data ?? false;
                    return WindowButton(
                      icon:
                          isMaximized
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                      onPressed: () {
                        if (isMaximized) {
                          windowManager.unmaximize();
                        } else {
                          windowManager.maximize();
                        }
                      },
                    );
                  },
                ),
                // Close button
                WindowButton(
                  icon: Icons.close,
                  onPressed: () {
                    windowManager.close();
                  },
                  hoverColor: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;

  const WindowButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.hoverColor,
  });

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 38,
          color:
              isHovering
                  ? widget.hoverColor ?? Colors.white.withValues(alpha: .1)
                  : Colors.transparent,
          child: Icon(widget.icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
