/// Utility to convert imperial measurements (feet, inches) from Perenual API into metric format (Meter, Centimeter).
class BotanicalUnitConverter {
  BotanicalUnitConverter._();

  /// Converts a dimension string such as "8.0 - 10.0 feet", "6 feet", or "24 inches" to metric string.
  /// E.g. "8.0 - 10.0 feet" -> "2,4 - 3,0 Meter"
  /// "12 inches" -> "30 cm"
  static String convertToMetric(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Tinggi 1 - 2 Meter';
    }

    final trimmed = raw.trim();

    // Already in metric format
    if (trimmed.toLowerCase().contains('meter') ||
        trimmed.toLowerCase().contains('cm')) {
      return trimmed;
    }

    // Match patterns like "8.0 - 10.0 feet", "8-10 feet", "8 to 10 feet"
    final rangeRegex = RegExp(
      r'([\d\.]+)\s*(?:-|to)\s*([\d\.]+)\s*(feet|foot|ft|inches|inch|in)?',
      caseSensitive: false,
    );
    final singleRegex = RegExp(
      r'([\d\.]+)\s*(feet|foot|ft|inches|inch|in)?',
      caseSensitive: false,
    );

    final isInch = trimmed.toLowerCase().contains('inch') ||
        trimmed.toLowerCase().contains('in');

    final rangeMatch = rangeRegex.firstMatch(trimmed);
    if (rangeMatch != null) {
      final minVal = double.tryParse(rangeMatch.group(1) ?? '') ?? 1.0;
      final maxVal = double.tryParse(rangeMatch.group(2) ?? '') ?? 2.0;

      if (isInch) {
        final minCm = (minVal * 2.54).round();
        final maxCm = (maxVal * 2.54).round();
        return 'Tinggi $minCm - $maxCm cm';
      } else {
        final minM = (minVal * 0.3048);
        final maxM = (maxVal * 0.3048);
        return 'Tinggi ${_formatDouble(minM)} - ${_formatDouble(maxM)} Meter';
      }
    }

    final singleMatch = singleRegex.firstMatch(trimmed);
    if (singleMatch != null) {
      final val = double.tryParse(singleMatch.group(1) ?? '') ?? 1.0;
      if (isInch) {
        final cm = (val * 2.54).round();
        return 'Tinggi $cm cm';
      } else {
        final m = (val * 0.3048);
        return 'Tinggi ${_formatDouble(m)} Meter';
      }
    }

    return trimmed;
  }

  static String _formatDouble(double val) {
    final fixed = val.toStringAsFixed(1);
    if (fixed.endsWith('.0')) {
      return fixed.substring(0, fixed.length - 2);
    }
    return fixed.replaceAll('.', ',');
  }
}
