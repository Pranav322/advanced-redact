import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
// import 'auth/login_page.dart';
import 'main_screen.dart';
import 'themes.dart';
import 'welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap the clearTemporaryFiles call in a try-catch block
  try {
    await FilePicker.platform.clearTemporaryFiles();
  } catch (e) {
    print('Error clearing temporary files: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Redact',
      theme: AppTheme.darkTheme,
      home: WelcomeScreen(), // Show WelcomeScreen by default
    );
  }
}
