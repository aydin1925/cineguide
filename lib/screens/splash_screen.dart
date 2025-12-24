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
    // Ekran açılır açılmaz polisi göreve çağırıyoruz
    _checkUserSession();
  }

  // --- TRAFİK POLİSİ FONKSİYONU ---
  Future<void> _checkUserSession() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        print("🕵️ DEDEKTİF: Oturum yok. Login'e gidiliyor.");
        _navigateTo(const LoginScreen());
        return; 
      }

      final userId = Supabase.instance.client.auth.currentUser!.id;
      print("🕵️ DEDEKTİF: Kullanıcı ID'si bulundu: $userId");
      
      // Veriyi çekmeye çalışıyoruz
      print("🕵️ DEDEKTİF: Veritabanına soruluyor...");
      final data = await Supabase.instance.client
          .from('profiles')
          .select('favorite_genres')
          .eq('id', userId)
          .single();

      print("🕵️ DEDEKTİF: Supabase'den gelen HAM VERİ: $data");

      final List genres = data['favorite_genres'] ?? [];
      print("🕵️ DEDEKTİF: İşlenmiş Liste Uzunluğu: ${genres.length}");

      if (genres.isEmpty) {
        print("🕵️ DEDEKTİF: Liste BOŞ görünüyor. Home (Tür Seçme)'ye gidiliyor.");
        _navigateTo(const HomeScreen());
      } else {
        print("🕵️ DEDEKTİF: Liste DOLU görünüyor. Movies (Film)'e gidiliyor.");
        _navigateTo(const MoviesScreen());
      }

    } catch (e) {
      print("❌ DEDEKTİF HATASI: Bir şeyler ters gitti!");
      print("HATA DETAYI: $e");
      // Hata olsa bile kullanıcı takılı kalmasın diye Login'e atıyoruz
      _navigateTo(const LoginScreen());
    }
  }

  // Yönlendirme yapan yardımcı fonksiyon (Kod tekrarını önlemek için)
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
      backgroundColor: Color(0xFF121212), // Koyu arka plan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo niyetine büyük bir ikon
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
            // Dönen yükleme halkası
            CircularProgressIndicator(color: Colors.amber),
          ],
        ),
      ),
    );
  }
}