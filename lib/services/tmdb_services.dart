import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  final String _apiKey = 'de0d409faa1512efb11e4ff3e7dfd59c';
  final String _baseUrl = 'https://api.themoviedb.org/3';
  
  Future<List<Movie>> getPopularMovies() async {

    // url oluşturma
    final url = Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&language=tr-TR');

    // istek gönderme
    final response = await http.get(url);

    if(response.statusCode == 200) {
      // gelen cevabın gövdesini çöz
      final Map<String, dynamic> data = json.decode(response.body);

      // JSON içindeki results listesini al
      final List<dynamic> results = data['results'];

      return results.map((json) => Movie.fromJson(json)).toList();
    }
    else {
      throw Exception('Filmler alınamadı: ${response.statusCode}');
    }
  }
}