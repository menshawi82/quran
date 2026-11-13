class Moshaf {
  const Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.surahList,
  });

  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final List<int> surahList;

  factory Moshaf.fromJson(Map<String, dynamic> json) => Moshaf(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        server: json['server'] as String? ?? '',
        surahTotal: json['surah_total'] as int? ?? 0,
        surahList: ((json['surah_list'] as String?) ?? '')
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map(int.parse)
            .toList(),
      );

  bool hasSurah(int number) => surahList.contains(number);
}

class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshafs,
  });

  final int id;
  final String name;
  final String letter;
  final List<Moshaf> moshafs;

  factory Reciter.fromJson(Map<String, dynamic> json) => Reciter(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        letter: json['letter'] as String? ?? '',
        moshafs: ((json['moshaf'] as List?) ?? [])
            .map((e) => Moshaf.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.url,
  });

  final int id;
  final String name;
  final String url;

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}
