class Movie {
  final int id;
  final String title;
  final double avgRating;
  final String posterPath;
  final String overview;
  final String releaseDate;


  Movie({
    required this.id,
    required this.title,
    required this.avgRating,
    required this.posterPath,
    required this.overview,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0, // (Çökmemesi için önlem)
      title: json['title'] ?? 'İsimsiz Film',
      avgRating: (json['vote_average'] ?? 0).toDouble(),
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? 'Özet bulunamadı.',
      releaseDate: json['release_date'] ?? 'Tarih Yok',
    );
  }

  String get fullPosterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';

}