import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart'; // Trafik Polisi burada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlatan kod (Senin anahtarların)
  await Supabase.initialize(
    url: 'https://hqvhminwxuwpbppomtfc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxdmhtaW53eHV3cGJwcG9tdGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyNzY2OTIsImV4cCI6MjA4MTg1MjY5Mn0.yjYlx2GjQTj_Ui-8fQ9xxtTh3uBaL6hIXPdTucaQBzs',
  );

  // DÜZELTME: Artık direkt LoginScreen değil, ayarların olduğu MyApp'i başlatıyoruz.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // O sağ üstteki kırmızı bant gitsin
      title: 'CineGuide',
      theme: ThemeData(
        // Uygulamanın genel rengini Amber (Sarı) yaptık, logolarınla uyumlu olsun
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      
      // İŞTE BURASI!
      // Uygulama açılınca Trafik Polisi (Splash) karşılayacak.
      home: const SplashScreen(),
    );
  }
}