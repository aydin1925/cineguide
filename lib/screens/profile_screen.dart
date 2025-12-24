import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _username;
  List<int> _favoriteGenreIds = []; 
  final user = Supabase.instance.client.auth.currentUser;

  final Map<int, String> _genresMap = {
    28: 'Aksiyon',
    12: 'Macera',
    16: 'Animasyon',
    35: 'Komedi',
    80: 'Suç',
    99: 'Belgesel',
    18: 'Dram',
    10751: 'Aile',
    14: 'Fantezi',
    36: 'Tarih',
    27: 'Korku',
    10402: 'Müzik',
    9648: 'Gizem',
    10749: 'Romantik',
    878: 'Bilim Kurgu',
    10770: 'TV Filmi',
    53: 'Gerilim',
    10752: 'Savaş',
    37: 'Vahşi Batı',
  };

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      final userId = user!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('username, favorite_genres')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _username = data['username'] as String?;
          _favoriteGenreIds = List<int>.from(data['favorite_genres'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // tür düzenleme fonksiyonu
  void _showGenreEditor() {
    List<int> tempSelectedGenres = List.from(_favoriteGenreIds);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.movie_filter_rounded, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Favori Türlerini Seç",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: _genresMap.entries.map((entry) {
                            final isSelected = tempSelectedGenres.contains(entry.key);
                            return FilterChip(
                              label: Text(entry.value),
                              selected: isSelected,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 14,
                              ),
                              backgroundColor: const Color(0xFF2C2C2C),
                              selectedColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? Colors.amber : Colors.white12,
                                  width: 1.5,
                                ),
                              ),
                              onSelected: (bool selected) {
                                setDialogState(() {
                                  if (selected) {
                                    tempSelectedGenres.add(entry.key);
                                  } else {
                                    tempSelectedGenres.remove(entry.key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Şu an seçili: ${tempSelectedGenres.length} (En az 3 gerekli)",
                        style: TextStyle(
                          color: tempSelectedGenres.length < 3 ? Colors.redAccent : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Vazgeç", style: TextStyle(color: Colors.white54, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (tempSelectedGenres.length < 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("⚠️ Lütfen en az 3 tür seçin!"),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              await _updateGenresInDb(tempSelectedGenres);
                              setState(() {
                                _favoriteGenreIds = tempSelectedGenres;
                              });
                              if (mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // güncellenen türleri veritabanına kaydeden fonksiyon
  Future<void> _updateGenresInDb(List<int> newGenres) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'favorite_genres': newGenres})
          .eq('id', user!.id);
          
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Favori türlerin güncellendi!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // çıkış fonksiyonu
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // yakında geliyor yazan fonksiyon
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$feature Özelliği",
                    style: const TextStyle(
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    "Çok yakında burada olacak! 🛠️",
                    style: TextStyle(
                      color: Colors.black87, 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.person, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _username ?? "Kullanıcı",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? "",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    
                    // kaç tür seçildi 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "${_favoriteGenreIds.length} Favori Tür",
                        style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 30),

                    _buildSectionHeader("Hesap & Ayarlar"),
                    
                    // tür düzenleme buttonu
                    _buildMenuTile(
                      icon: Icons.category_rounded,
                      title: "Favori Türleri Düzenle",
                      onTap: _showGenreEditor,
                    ),

                    _buildMenuTile(
                      icon: Icons.notifications_active_rounded,
                      title: "Bildirim Ayarları",
                      trailing: Switch(value: true, onChanged: (val) {}, activeColor: Colors.amber),
                      onTap: () {},
                    ),

                    _buildMenuTile(
                      icon: Icons.language,
                      title: "Uygulama Dili",
                      trailing: const Text("Türkçe 🇹🇷", style: TextStyle(color: Colors.grey)),
                      onTap: () => _showComingSoon("Dil Değiştirme"),
                    ),

                    _buildMenuTile(
                      icon: Icons.privacy_tip_rounded,
                      title: "Gizlilik ve Hakkında",
                      onTap: () => _showComingSoon("Gizlilik Sayfası"),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildSectionHeader("Güvenlik"),

                    _buildMenuTile(
                      icon: Icons.lock_reset,
                      title: "Şifremi Değiştir",
                      onTap: () => _showComingSoon("Şifre Sıfırlama"),
                    ),

                    _buildMenuTile(
                      icon: Icons.delete_forever,
                      title: "Hesabımı Sil",
                      textColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: () => _showComingSoon("Hesap Silme"),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout, color: Colors.black),
                        label: const Text("Oturumu Kapat", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color textColor = Colors.white,
    Color iconColor = Colors.white70,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}