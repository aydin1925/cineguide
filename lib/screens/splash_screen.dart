import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'movies_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        _navigateTo(const LoginScreen());
        return; 
      }

      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // veri çeken kısım
      final data = await Supabase.instance.client
          .from('profiles')
          .select('favorite_genres')
          .eq('id', userId)
          .single();


      final List genres = data['favorite_genres'] ?? [];


      if (genres.isEmpty) {
        _navigateTo(const HomeScreen());
      } else {
        _navigateTo(const MoviesScreen());
      }

    } catch (e) {
      print("❌ DEDEKTİF HATASI: Bir şeyler ters gitti!");
      print("HATA DETAYI: $e");
      _navigateTo(const LoginScreen());
    }
  }

  // Yönlendirme yapan yardımcı fonksiyon
  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  // --- GÖRÜNTÜ KISMI ---
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_rounded, size: 100, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              "CineGuide",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                letterSpacing: 2
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.amber),
          ],
        ),
      ),
    );
  }
}