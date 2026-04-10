import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const String _defaultFieldLocation = 'Kurnool, Andhra Pradesh';
const String _apName = 'Andhra Pradesh';

class FieldBlueprintException implements Exception {
  final String message;

  const FieldBlueprintException(this.message);

  @override
  String toString() => message;
}

class FieldBlueprintData {
  final String location;
  final double latitude;
  final double longitude;
  final double temperatureC;
  final int humidity;
  final double windSpeedKmh;
  final double nextSevenDayRainMm;
  final double maxTempC;
  final double minTempC;
  final int groundwaterStressScore;
  final String groundwaterRisk;
  final String rechargeOutlook;
  final List<String> blueprintActions;

  const FieldBlueprintData({
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.temperatureC,
    required this.humidity,
    required this.windSpeedKmh,
    required this.nextSevenDayRainMm,
    required this.maxTempC,
    required this.minTempC,
    required this.groundwaterStressScore,
    required this.groundwaterRisk,
    required this.rechargeOutlook,
    required this.blueprintActions,
  });
}

final fieldLocationProvider =
    StateProvider<String>((ref) => _defaultFieldLocation);

final fieldBlueprintProvider = FutureProvider<FieldBlueprintData>((ref) async {
  final location = ref.watch(fieldLocationProvider);
  return FieldBlueprintService.instance.fetchBlueprint(location: location);
});

class FieldBlueprintService {
  FieldBlueprintService._();

  static final FieldBlueprintService instance = FieldBlueprintService._();

  Future<FieldBlueprintData> fetchBlueprint({required String location}) async {
    final query =
        location.trim().isEmpty ? _defaultFieldLocation : location.trim();
    final place = await _resolveAndhraLocation(query);
    final latitude = (place['latitude'] as num).toDouble();
    final longitude = (place['longitude'] as num).toDouble();
    final displayLocation = _formatLocation(place);

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto&forecast_days=7',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw const FieldBlueprintException(
        'Live field blueprint is unavailable right now. Please try again.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final precipitation = (daily['precipitation_sum'] as List).cast<num>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();

    final rainTotal =
        precipitation.fold<double>(0, (sum, value) => sum + value.toDouble());
    final maxTemp = maxTemps.fold<double>(
        0, (sum, value) => value.toDouble() > sum ? value.toDouble() : sum);
    final minTemp = minTemps.isEmpty ? 0.0 : minTemps.first.toDouble();
    final currentTemp = (current['temperature_2m'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).round();
    final windSpeed = (current['wind_speed_10m'] as num).toDouble();

    final stressScore = _computeStressScore(
      currentTemp: currentTemp,
      humidity: humidity,
      windSpeed: windSpeed,
      rainTotal: rainTotal,
      maxTemp: maxTemp,
    );

    return FieldBlueprintData(
      location: displayLocation,
      latitude: latitude,
      longitude: longitude,
      temperatureC: currentTemp,
      humidity: humidity,
      windSpeedKmh: windSpeed,
      nextSevenDayRainMm: rainTotal,
      maxTempC: maxTemp,
      minTempC: minTemp,
      groundwaterStressScore: stressScore,
      groundwaterRisk: _riskLabel(stressScore),
      rechargeOutlook: _rechargeOutlook(rainTotal),
      blueprintActions: _blueprintActions(
        stressScore: stressScore,
        rainTotal: rainTotal,
        maxTemp: maxTemp,
      ),
    );
  }

  Future<Map<String, dynamic>> _resolveAndhraLocation(String query) async {
    final terms = _buildSearchTerms(query);
    for (final term in terms) {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(term)}&count=10&language=en&format=json',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) continue;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (json['results'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .where(_isAndhraResult)
          .toList();

      if (results != null && results.isNotEmpty) {
        return results.first;
      }
    }

    throw const FieldBlueprintException(
      'Enter a city or place from Andhra Pradesh to see the field blueprint.',
    );
  }

  List<String> _buildSearchTerms(String query) {
    final base = query.trim();
    final parts = base
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final values = <String>[
      base,
      if (parts.isNotEmpty) parts.first,
      if (parts.isNotEmpty) '${parts.first}, $_apName',
    ];

    final seen = <String>{};
    return values.where((value) => seen.add(value.toLowerCase())).toList();
  }

  bool _isAndhraResult(Map<String, dynamic> result) {
    final admin1 = (result['admin1'] as String?)?.toLowerCase() ?? '';
    final country = (result['country'] as String?)?.toLowerCase() ?? '';
    return admin1.contains(_apName.toLowerCase()) && country.contains('india');
  }

  String _formatLocation(Map<String, dynamic> place) {
    final name = (place['name'] as String?)?.trim() ?? _defaultFieldLocation;
    final admin1 = (place['admin1'] as String?)?.trim();
    final country = (place['country'] as String?)?.trim();
    return [
      name,
      if (admin1 != null && admin1.isNotEmpty && admin1 != name) admin1,
      if (country != null && country.isNotEmpty) country,
    ].join(', ');
  }

  int _computeStressScore({
    required double currentTemp,
    required int humidity,
    required double windSpeed,
    required double rainTotal,
    required double maxTemp,
  }) {
    var score = 50;
    if (rainTotal < 10) score += 25;
    if (rainTotal < 25) score += 10;
    if (maxTemp > 36) score += 15;
    if (currentTemp > 34) score += 10;
    if (humidity < 45) score += 10;
    if (windSpeed > 18) score += 8;
    if (rainTotal > 40) score -= 18;
    if (rainTotal > 70) score -= 12;
    return score.clamp(0, 100).toInt();
  }

  String _riskLabel(int score) {
    if (score >= 75) return 'High Stress';
    if (score >= 50) return 'Moderate Stress';
    return 'Lower Stress';
  }

  String _rechargeOutlook(double rainTotal) {
    if (rainTotal >= 70) return 'Strong recharge chance this week';
    if (rainTotal >= 30) return 'Partial recharge chance this week';
    return 'Weak recharge chance this week';
  }

  List<String> _blueprintActions({
    required int stressScore,
    required double rainTotal,
    required double maxTemp,
  }) {
    final actions = <String>[];

    if (stressScore >= 75) {
      actions.add(
          'Prioritize drip or alternate-furrow irrigation for water saving.');
      actions
          .add('Mulch exposed soil to cut evaporation during hot afternoons.');
      actions.add(
          'Delay non-essential water-intensive sowing until rainfall improves.');
    } else if (stressScore >= 50) {
      actions.add(
          'Use shorter irrigation cycles and monitor field moisture every 2-3 days.');
      actions.add(
          'Repair field channels and bunds before the next rainfall event.');
    } else {
      actions.add(
          'Current conditions are relatively safer, but continue moisture monitoring.');
      actions.add(
          'Capture runoff in farm ponds or recharge pits when rain arrives.');
    }

    if (rainTotal < 20) {
      actions.add(
          'Plan borewell usage carefully because recharge outlook is weak this week.');
    } else {
      actions.add(
          'Prepare recharge trenches or storage pits to hold the upcoming rainwater.');
    }

    if (maxTemp > 36) {
      actions.add(
          'Prefer early-morning irrigation to reduce heat-loss and crop stress.');
    }

    return actions;
  }
}
