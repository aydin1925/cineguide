import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

  bool _isAddedToList = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();

    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final movieId = widget.movie.id;

      final data = await Supabase.instance.client.from('watchlists').select().eq('user_id', userId).eq('movie_id', movieId).maybeSingle();

      if (mounted) {
        setState(() {
          _isAddedToList = data != null; 
          _isLoading = false;
        });
      }
    }
    catch(e) {
      print("Hata: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isAddedToList = !_isAddedToList;
    });

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final movieId = widget.movie.id;

    try {
      if (_isAddedToList == true) {
        await Supabase.instance.client.from('watchlists').insert({
          'user_id': userId,
          'movie_id': movieId,
          'movie_title': widget.movie.title,
          'poster_path': widget.movie.posterPath,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await Supabase.instance.client
            .from('watchlists')
            .delete()
            .eq('user_id', userId)
            .eq('movie_id', movieId);
      }
    } catch(e) {
      print("İşlem Hatası: $e");
      if (mounted) {
        setState(() {
          _isAddedToList = !_isAddedToList;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bir hata oluştu!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.movie.fullPosterUrl),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_ios_new),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.movie.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.white),),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.movie.avgRating.toStringAsFixed(1)} / 10",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(width: 20),

                      const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        widget.movie.releaseDate.split('-')[0],
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      // Hemen izle buttonu
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.play_arrow_rounded),
                          label: Text("Hemen İzle", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Listeye ekleme buttonu
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF252525),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _isAddedToList ? Colors.amber : Colors.transparent)
                        ),
                        child: IconButton(
                          onPressed: () {
                            _isLoading ? null : _toggleBookmark();
                          },
                          icon: _isAddedToList ? Icon(Icons.bookmark) : Icon(Icons.bookmark_border),
                          color: _isAddedToList ? Colors.amber : Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "Özet",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.movie.overview.isEmpty ? "Özet bulunamadı." : widget.movie.overview,
                    style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}