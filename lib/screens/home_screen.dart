import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/tmdb_services.dart';
import '../models/movie.dart';
import 'movies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final Map<int, String> _genres = {
    28: "Aksiyon",
    12: "Macera",
    16: "Animasyon",
    35: "Komedi",
    80: "Suç",
    99: "Belgesel",
    18: "Dram",
    10751: "Aile",
    14: "Fantastik",
    36: "Tarih",
    27: "Korku",
    878: "Bilim Kurgu",
    53: "Gerilim",
  };

  // kullanıcının seçtiği türler
  final List<int> _selectedGenreIds = [];

  // yüklenme döngüsü (görüntü olan) görünsün mü
  bool _isLoading = false;

  // Seçim yapma mantığı
  void _toggleGenre(int id) {
    setState(() {
      if(_selectedGenreIds.contains(id)) {
        _selectedGenreIds.remove(id);
      } else {
        _selectedGenreIds.add(id);
      }
    });
  }

  // veritabanına kaydetme mantığı
  Future<void> _saveGenres() async {
    if(_selectedGenreIds.length < 3) {
      _showCustomSnackBar("En az 3 tür seçmelisiniz.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('profiles').update({
        'favorite_genres': _selectedGenreIds,
      }).eq('id', userId);

      if(mounted) {
        // Başarılı mesajı ver
        _showCustomSnackBar("Harika! Sinema dünyasına giriş yapılıyor... 🎬");
        
        // Kullanıcının mesajı okuması için 1 saniye bekle
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // --- KRİTİK EKLEME 2: YÖNLENDİRME KOMUTU ---
          // pushReplacement: Geri dönülemeyecek şekilde sayfayı değiştirir.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MoviesScreen()),
          );
        }
      }
    }
    catch (e) {
      if(mounted) {
        _showCustomSnackBar("Hata oluştu: $e", isError: true);
      }
    }
    finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // BİLDİRİM FONKSİYONU
  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        title: const Text("En az 3 tane tür seçin", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Bilgilendirme için yazı
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Size uygun film önerileri sunabilmemiz için lütfen en az 3 tane favori tür seçin.",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          // Türlerin olduğu Izgara
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),

              // yan yana 2 tane tür gelsin
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                // sıradaki türün bilgilerini al
                final int id = _genres.keys.elementAt(index);
                final String name = _genres.values.elementAt(index);
                final bool isSelected = _selectedGenreIds.contains(id);

                // Tıklanabilir kutu oluşturma
                return InkWell(
                  onTap: () => _toggleGenre(id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // tür seçildiyse sarı, seçilmediyse koyu gri olacak
                      color: isSelected ? Colors.amber : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),

          // Kaydetme buttonu
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveGenres,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.black,) : const Text("BAŞLA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}