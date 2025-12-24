import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase eklendi
import '../services/tmdb_services.dart';
import '../models/movie.dart';
import 'login_screen.dart';
import 'detail_screen.dart';
import 'dart:async';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  // Göstereceğim listelerim
  List<Movie> _recommendedMovies = []; 
  List<Movie> _popularMovies = [];
  bool _isLoading = true;

  // Arama işlemi için gerekenler
  Timer? timer;
  List<Movie> searchResults = [];
  bool _isSearching = false;
  final _searchText = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); 
  }

  @override
  void dispose() {
    // Sayfa kapanırken timer ve controller'ı temizliyoruz
    timer?.cancel();
    _searchText.dispose();
    super.dispose();
  }

  // Seçilen türlere göre filmleri getiren fonksiyonum
  Future<void> _loadData() async {
    TmdbService service = TmdbService();
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      final data = await Supabase.instance.client
          .from('profiles')
          .select('favorite_genres')
          .eq('id', userId)
          .single();

      final List<dynamic> rawGenres = data['favorite_genres'] ?? [];
      final List<int> genreIds = List<int>.from(rawGenres);

      final results = await Future.wait([
        genreIds.isEmpty 
            ? service.getTrendingMovies() 
            : service.getMoviesByGenres(genreIds),
        service.getPopularMovies(),
      ]);

      if (mounted) {
        setState(() {
          _recommendedMovies = results[0];
          _popularMovies = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Arama Mantığı (Yeni Eklendi)
  void _onSearchChanged(String query) {
    // Eğer önceki sayaç çalışıyorsa iptal et
    if (timer?.isActive ?? false) timer!.cancel();

    // Yeni sayaç başlat (500ms bekle)
    timer = Timer(const Duration(milliseconds: 500), () async {
      // Eğer kutu boşsa arama modundan çık
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          searchResults = [];
        });
        return;
      }

      // Arama yükleniyor efekti
      setState(() => _isLoading = true);

      try {
        TmdbService service = TmdbService();
        final results = await service.searchMovies(query); // Servisteki fonksiyonu çağır
        
        if (mounted) {
          setState(() {
            searchResults = results;
            _isSearching = true; // Arama modunu aç
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Arama hatası: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  // Çıkış fonksiyonum
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("CineGuide", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _signOut, 
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Çıkış Yap",
          ),
        ],
      ),
      // Body yapısı değişti: Column içinde Arama Barı + İçerik
      body: Column(
        children: [
          
          // --- 1. ARAMA ÇUBUĞU ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchText,
              onChanged: _onSearchChanged, // Yazdıkça yukarıdaki fonksiyon çalışacak
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Film ara",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                suffixIcon: _searchText.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchText.clear();
                          _onSearchChanged('');
                        },
                      ) 
                    : null,
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _isSearching
                    ? searchResults.isEmpty 
                        ? const Center(child: Text("Sonuç bulunamadı.", style: TextStyle(color: Colors.white)))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final movie = searchResults[index];
                              return ListTile(
                                leading: movie.posterPath.isNotEmpty 
                                    ? Image.network(movie.fullPosterUrl, width: 50, fit: BoxFit.cover)
                                    : const Icon(Icons.movie, color: Colors.grey),
                                title: Text(movie.title, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  movie.releaseDate.isEmpty ? "-" : movie.releaseDate.split('-')[0], 
                                  style: const TextStyle(color: Colors.grey)
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
                                  );
                                },
                              );
                            },
                          )
                    
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            // kullanıcıya önerilen filmler
                            _buildSectionTitle("Sana Özel Öneriler ✨"),
                            SizedBox(
                              height: 280, 
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recommendedMovies.length,
                                itemBuilder: (context, index) {
                                  return _buildBigMovieCard(_recommendedMovies[index]);
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                             // kullanıcının kendi listesi
                            _buildSectionTitle("İzleme Listen 🔖"),
                            StreamBuilder(
                              stream: Supabase.instance.client.from('watchlists').stream(primaryKey: ['id']).order('created_at'), 
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                   return const SizedBox(
                                     height: 200, 
                                     child: Center(child: CircularProgressIndicator(color: Colors.amber))
                                   );
                                }
                                
                                if (snapshot.hasError) {
                                  return const Text("Bir hata oluştu.", style: TextStyle(color: Colors.white));
                                }

                                final watchlist = snapshot.data!;

                                // Liste boşsa
                                if (watchlist.isEmpty) {
                                  return Container(
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: const Text("Henüz listen boş. Bir şeyler ekle!", style: TextStyle(color: Colors.white54)),
                                  );
                                }

                                // Veri varsa ekrana yaz
                                return SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: watchlist.length,
                                    itemBuilder: (context, index) {
                                       final item = watchlist[index];
                                       
                                       // veriyi Movie Objesine çevir
                                       final movie = Movie(
                                         id: item['movie_id'],
                                         title: item['movie_title'],
                                         posterPath: item['poster_path'],
                                         overview: "", 
                                         releaseDate: "", 
                                         avgRating: 0.0,
                                       );

                                       return _buildSmallMovieCard(movie);
                                    },
                                  ),
                                );
                              }, 
                            ),
                            const SizedBox(height: 20),

                            // 3. SATIR: GENEL POPÜLER
                            _buildSectionTitle("Herkes Bunları İzliyor 🌍"),
                             SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _popularMovies.length,
                                itemBuilder: (context, index) {
                                   return _buildSmallMovieCard(_popularMovies[index]);
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBigMovieCard(Movie movie) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder:(context) => DetailScreen(movie: movie)),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(movie.fullPosterUrl), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14))
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMovieCard(Movie movie) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: NetworkImage(movie.fullPosterUrl), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))
          ],
        ),
      ),
    );
  }
}