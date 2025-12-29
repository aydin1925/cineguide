import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/tmdb_services.dart';
import '../models/movie.dart';
import 'detail_screen.dart';
import 'dart:async';
import 'profile_screen.dart';

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
    // timer'i sıfırlayan kod
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

  // arama fonksiyonu
  void _onSearchChanged(String query) {
    if (timer?.isActive ?? false) timer!.cancel();

    timer = Timer(const Duration(milliseconds: 500), () async {
      // arama barı boşsa arama modunu kapat
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          searchResults = [];
        });
        return;
      }

      // yükleniyor efekti
      setState(() => _isLoading = true);

      try {
        TmdbService service = TmdbService();
        final results = await service.searchMovies(query);
        
        if (mounted) {
          setState(() {
            searchResults = results;
            _isSearching = true; 
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Arama hatası: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    });
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
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );

                setState(() {
                  _isLoading = true;
                });
                _loadData();
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withOpacity(0.8), width: 1.5), // İnce sarı halka
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              tooltip: "Profilim",
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchText,
              onChanged: _onSearchChanged, // yazı yazıldıkça bu fonksiyonu tetikleyecek
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

                                      final simpleMovie = Movie(
                                        id: item['movie_id'],
                                        title: item['movie_title'],
                                        posterPath: item['poster_path'],
                                        overview: "",
                                        releaseDate: "",
                                        avgRating: 0.0,
                                       );

                                       return _buildWatchlistCard(simpleMovie); 
                                      },
                                  ),
                                );
                              }, 
                            ),
                            const SizedBox(height: 20),

                            // popüler filmleri göster
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

  Widget _buildWatchlistCard(Movie simpleMovie) {
    return InkWell(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        );

        try {
          TmdbService service = TmdbService();
          Movie fullMovie = await service.getMovieDetail(simpleMovie.id);

          if (mounted) Navigator.pop(context);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailScreen(movie: fullMovie)),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Film detayları alınamadı. İnternetini kontrol et.")),
            );
          }
        }
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
                  image: DecorationImage(
                    image: NetworkImage(simpleMovie.fullPosterUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              simpleMovie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}