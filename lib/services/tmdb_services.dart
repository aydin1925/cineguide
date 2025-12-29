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

  // Kullanıcının seçtiği türlere göre filmleri al
  Future<List<Movie>> getMoviesByGenres(List<int> genreIds) async {

    // Seçilen türlerin herhangi birine göre filmleri getir
    final genreString = genreIds.join('|');

    final url = Uri.parse('$_baseUrl/discover/movie?api_key=$_apiKey&language=tr-TR&sort_by=popularity.desc&with_genres=$genreString');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Önerilen filmler alınamadı');
    }
  }
  
  
  Future<List<Movie>> getTrendingMovies() async {
    final url = Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey&language=tr-TR');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Trendler alınamadı');
    }
  }

  
  Future<List<Movie>> getUpcomingMovies() async {
    final url = Uri.parse('$_baseUrl/movie/upcoming?api_key=$_apiKey&language=tr-TR');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception('Gelecek filmler alınamadı');
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&language=tr-TR&query=$query&include_adult=false');
    final response = await http.get(url);

    if(response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    }
    else {
      throw Exception('Arama Yapılamadı!');
    }
  }

  Future<Movie> getMovieDetail(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey&language=tr-TR');
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      return Movie.fromJson(data);
    } else {
      throw Exception('Film detayları getirilemedi: ${response.statusCode}');
    }
  }
}