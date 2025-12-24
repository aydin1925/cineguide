import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // Başarılı olursa buraya gideceğiz

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Kontrolcüler
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  // Şifreler gizli mi?
  bool _isPasswordHidden = true;

  // --- 2. KAYIT MANTIĞI ---
  Future<void> _register() async {
    
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      _showMessage("Lütfen tüm alanları doldurun.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Şifreler eşleşmiyor!");
      return;
    }

    if (password.length < 6) {
      _showMessage("Şifre en az 6 karakter olmalı.");
      return;
    }

    // B) Supabase İşlemleri
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Kullanıcıyı oluştur (Auth Tablosuna ekle)
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Eğer Auth kaydı başarılıysa, Profil Tablosuna ekle
      if (res.user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': res.user!.id, // Auth ID'si ile eşleştiriyoruz
          'username': username,
          'favorite_genres': [], // Henüz tür seçmedi, boş liste
        });

        // 3. Başarılı! İçeri al.
        if (mounted) {
          _showMessage("Kayıt Başarılı! Hoş geldin.", isError: false);
          
          // Ana sayfaya gönder ve geri dönemesin
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      // Supabase hatası (Örn: Bu mail zaten kayıtlı)
      _showMessage(e.message);
    } catch (e) {
      // Genel hata
      _showMessage("Beklenmedik bir hata oluştu: $e");
    } finally {
      // Yükleniyor animasyonunu kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Mesaj Gösterme Yardımcısı (SnackBar)
  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Kömür Siyahı Arka Plan
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LOGO ---
              const Icon(Icons.movie_filter_outlined, size: 80, color: Colors.amber),
              const SizedBox(height: 10),
              const Text(
                "CineGuide",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // --- INPUTLAR ---
              _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined),
              const SizedBox(height: 16),
              
              _buildTextField(
                  controller: _usernameController,
                  label: "Username",
                  icon: Icons.person_outline),
              const SizedBox(height: 16),
              
              _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true),
              const SizedBox(height: 16),
              
              _buildTextField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  icon: Icons.lock_outline,
                  isPassword: true),
              const SizedBox(height: 30),

              // --- KAYIT BUTONU ---
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text("SIGN UP",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // --- GİRİŞE DÖN ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ",
                      style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Login",
                        style: TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TASARIM YARDIMCISI ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isPasswordHidden : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.amber),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              )
            : null,
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
      ),
    );
  }
}