/// Localized mapper and translator for Perenual botanical terms into Indonesian.
class BotanicalTranslator {
  BotanicalTranslator._();

  /// Translates cycle terms (Perennial, Biennial, Annual, etc.)
  static String translateCycle(String? cycle) {
    if (cycle == null || cycle.trim().isEmpty) return 'Perenial (Abadi)';
    final lower = cycle.trim().toLowerCase();

    if (lower.contains('perennial')) return 'Perenial (Abadi)';
    if (lower.contains('annual')) return 'Semusim (Annual)';
    if (lower.contains('biennial')) return 'Dua Musim (Biennial)';
    return cycle;
  }

  /// Translates growth rate terms (High, Medium, Low, Fast, Moderate, Slow)
  static String translateGrowthRate(String? rate) {
    if (rate == null || rate.trim().isEmpty) return 'Sedang';
    final lower = rate.trim().toLowerCase();

    if (lower.contains('high') || lower.contains('fast') || lower.contains('cepat')) {
      return 'Cepat';
    }
    if (lower.contains('medium') || lower.contains('moderate') || lower.contains('sedang')) {
      return 'Sedang';
    }
    if (lower.contains('low') || lower.contains('slow') || lower.contains('lambat')) {
      return 'Lambat';
    }
    return rate;
  }

  /// Translates flowering season / blooming periods
  static String translateFloweringSeason(String? season, {String? commonName}) {
    if (season == null || season.trim().isEmpty) {
      final name = (commonName ?? '').toLowerCase();
      if (name.contains('peace lily') || name.contains('lily')) {
        return 'Musim Semi & Panas';
      }
      return 'Jarang di Dalam Ruangan';
    }

    final lower = season.trim().toLowerCase();
    if (lower.contains('never') || lower.contains('rare') || lower.contains('none')) {
      return 'Jarang di Dalam Ruangan';
    }

    var result = season;
    result = result.replaceAll(RegExp(r'Spring', caseSensitive: false), 'Musim Semi');
    result = result.replaceAll(RegExp(r'Summer', caseSensitive: false), 'Musim Panas');
    result = result.replaceAll(RegExp(r'Fall|Autumn', caseSensitive: false), 'Musim Gugur');
    result = result.replaceAll(RegExp(r'Winter', caseSensitive: false), 'Musim Dingin');
    return result;
  }

  /// Translates pruning month / season
  static String translatePruningMonth(dynamic pruning) {
    if (pruning == null) return 'Musim Semi, Panas';
    if (pruning is List) {
      if (pruning.isEmpty) return 'Musim Semi, Panas';
      final months = pruning.map((m) => _translateMonth(m.toString())).join(', ');
      return months;
    }
    final str = pruning.toString().trim();
    if (str.isEmpty || str == '[]' || str == 'null') return 'Musim Semi, Panas';
    return _translateMonth(str);
  }

  static String _translateMonth(String m) {
    final lower = m.toLowerCase();
    if (lower.contains('march') || lower.contains('april') || lower.contains('may')) {
      return 'Maret - Mei (Musim Semi)';
    }
    if (lower.contains('june') || lower.contains('july') || lower.contains('august')) {
      return 'Juni - Agustus (Musim Panas)';
    }
    if (lower.contains('spring')) return 'Musim Semi';
    if (lower.contains('summer')) return 'Musim Panas';
    return m;
  }

  /// Translates care levels (Easy, Medium, Hard, etc.)
  static String translateCareLevel(String? careLevel) {
    if (careLevel == null || careLevel.trim().isEmpty) return 'EASY CARE';
    final lower = careLevel.trim().toLowerCase();

    if (lower.contains('easy') || lower.contains('low') || lower.contains('pemula')) {
      return 'EASY CARE';
    }
    if (lower.contains('medium') || lower.contains('moderate') || lower.contains('sedang')) {
      return 'INTERMEDIATE';
    }
    if (lower.contains('hard') || lower.contains('high') || lower.contains('advance')) {
      return 'ADVANCED';
    }
    return careLevel.toUpperCase();
  }

  /// Translates sunlight levels
  static String translateSunlight(dynamic sunlight) {
    if (sunlight == null) return 'Sinar Tidak Langsung Terang';
    if (sunlight is List) {
      if (sunlight.isEmpty) return 'Sinar Tidak Langsung Terang';
      return sunlight.map((s) => _translateSunlightTerm(s.toString())).join(' / ');
    }
    return _translateSunlightTerm(sunlight.toString());
  }

  static String _translateSunlightTerm(String term) {
    final lower = term.toLowerCase();
    if (lower.contains('full sun') && lower.contains('part shade')) {
      return 'Matahari Penuh / Teduh Sebagian';
    }
    if (lower.contains('full shade')) return 'Pencahayaan Rendah / Teduh Penuh';
    if (lower.contains('part shade') || lower.contains('filtered')) {
      return 'Sinar Tidak Langsung Terang';
    }
    if (lower.contains('full sun')) return 'Matahari Penuh (Direct Sun)';
    return term;
  }

  /// Generates or refines botanical description in Indonesian
  static String translateOrGenerateDescription({
    String? rawDescription,
    required String commonName,
    String? scientificName,
    String? family,
    String? careLevel,
    int? defaultWateringInterval,
  }) {
    if (rawDescription != null &&
        rawDescription.trim().isNotEmpty &&
        !rawDescription.toLowerCase().contains('no description')) {
      // Clean HTML tags if any
      final cleaned = rawDescription.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
      if (cleaned.isNotEmpty && (cleaned.contains(' adalah ') || cleaned.contains(' merupakan '))) {
        return cleaned;
      }
    }

    final name = commonName.toLowerCase();
    final sci = (scientificName ?? '').toLowerCase();

    if (name.contains('monstera') || sci.contains('monstera')) {
      return 'Monstera Deliciosa adalah tanaman hias tropis ikonik dari famili Araceae yang terkenal dengan daun lebar berlubang alami (fenestrasi). Sangat populer untuk mempercantik sudut ruangan dengan pencahayaan tidak langsung.';
    }
    if (name.contains('snake') || name.contains('sansevieria') || sci.contains('dracaena')) {
      return 'Snake Plant (Sansevieria) adalah tanaman hias pemurni udara tangguh yang ideal bagi pemula. Tahan terhadap kondisi cahaya rendah dan penyiraman minimal berkat daun tebalnya yang mampu menyimpan air.';
    }
    if (name.contains('pothos') || name.contains('sirih') || sci.contains('epipremnum')) {
      return 'Golden Pothos (Sirih Gading) adalah tanaman merambat populer dengan daun bercorak cerah berbentuk hati. Sangat adaptif dan mampu tumbuh subur di berbagai kondisi pencahayaan dalam ruangan.';
    }
    if (name.contains('calathea') || sci.contains('calathea')) {
      return 'Calathea Orbifolia memiliki corak daun lebar bergaris perak yang memukau. Dikenal dengan sebutan "Prayer Plant" karena daunnya bergerak menutup di malam hari, serta aman bagi hewan peliharaan.';
    }
    if (name.contains('peace lily') || sci.contains('spathiphyllum')) {
      return 'Peace Lily adalah tanaman hias tropis yang anggun dengan bunga putih elegan. Efektif menyaring polutan udara dan memberikan sinyal visual ketika membutuhkan penyiraman.';
    }
    if (name.contains('zz') || sci.contains('zamioculcas')) {
      return 'ZZ Plant memiliki daun hijau mengkilap yang sangat kokoh. Memiliki umbi rimpang penyimpan air sehingga dapat bertahan berminggu-minggu tanpa disiram.';
    }

    final famStr = family != null && family.isNotEmpty ? ' dari famili $family' : '';
    final careStr = careLevel != null ? careLevel.toLowerCase() : 'mudah';
    final interval = defaultWateringInterval ?? 4;

    return '$commonName (${scientificName ?? 'Tanaman Hias'})$famStr adalah tanaman hias yang memikat dan cocok untuk interior ruangan. Memiliki tingkat perawatan $careStr dan membutuhkan penyiraman berkala setiap $interval hari sekali.';
  }
}
