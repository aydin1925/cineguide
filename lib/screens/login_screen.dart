import 'package:cineguide/screens/register_screen.dart';
import 'package:cineguide/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // Başarılı olursa buraya gideceğiz

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  

  bool _isLoading = false;



  Future<void> _login() async {
    setState(() {
      _isLoading = true; // yükleme buttonu dönmesi için
    });

    try {
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if(mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    }
    on AuthException catch (e) {
      // 4. Supabase'den özel bir hata geldiyse (Yanlış şifre vb.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 5. Beklenmedik başka bir hata (İnternet yok vb.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Beklenmedik bir hata oluştu."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Her şey bitince (Başarılı veya Hatalı) Yükleniyor modunu kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LOGO KISMI ---
              const Icon(Icons.movie_filter_outlined, size: 100, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                "CineGuide",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Beyaz Yazı
                ),
              ),
              const SizedBox(height: 40),

              // --- E-POSTA KUTUSU ---
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("E-posta", Icons.email),
              ),
              const SizedBox(height: 20),

              // --- ŞİFRE KUTUSU ---
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Şifre", Icons.lock),
              ),
              const SizedBox(height: 30),

              // --- GİRİŞ BUTONU ---
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("GİRİŞ YAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 20),
              
              // --- KAYIT OL LİNKİ ---
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text("Hesabın yok mu? Kayıt Ol", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kod tekrarını önlemek için Tasarım Fonksiyonu
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.amber),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    );
  }
}