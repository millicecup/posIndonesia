// lib/data/models/trigger_rule.dart
// Aturan trigger per POI (radius & sekali per sesi).

import '../../core/utils/json_utils.dart';

class TriggerRule {
  const TriggerRule({
    required this.triggerRadiusMeters,
    required this.approachRadiusMeters,
    required this.triggerOncePerSession,
    this.radiusNeedsConfirmation = true,
  });

  /// Masuk radius ini -> status triggered.
  final double triggerRadiusMeters;

  /// Masuk radius ini -> status approaching.
  final double approachRadiusMeters;

  /// true: hanya sekali per sesi aplikasi.
  /// false: boleh terpicu lagi setelah keluar lalu masuk kembali.
  final bool triggerOncePerSession;

  /// Penanda radius 5 m vs 10 m belum dikonfirmasi.
  final bool radiusNeedsConfirmation;

  factory TriggerRule.fromJson(Map<String, dynamic> json) {
    final radius = readDouble(json, 'triggerRadiusMeters', context: 'triggerRule');
    final approach = readNullableDouble(json, 'approachRadiusMeters') ?? radius + 5;
    return TriggerRule(
      triggerRadiusMeters: radius,
      approachRadiusMeters: approach,
      triggerOncePerSession: (json['triggerOncePerSession'] as bool?) ?? true,
      radiusNeedsConfirmation: (json['radiusNeedsConfirmation'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'triggerRadiusMeters': triggerRadiusMeters,
        'approachRadiusMeters': approachRadiusMeters,
        'triggerOncePerSession': triggerOncePerSession,
        'radiusNeedsConfirmation': radiusNeedsConfirmation,
      };

  TriggerRule copyWith({
    double? triggerRadiusMeters,
    double? approachRadiusMeters,
    bool? triggerOncePerSession,
    bool? radiusNeedsConfirmation,
  }) =>
      TriggerRule(
        triggerRadiusMeters: triggerRadiusMeters ?? this.triggerRadiusMeters,
        approachRadiusMeters: approachRadiusMeters ?? this.approachRadiusMeters,
        triggerOncePerSession:
            triggerOncePerSession ?? this.triggerOncePerSession,
        radiusNeedsConfirmation:
            radiusNeedsConfirmation ?? this.radiusNeedsConfirmation,
      );

  @override
  bool operator ==(Object other) =>
      other is TriggerRule &&
      other.triggerRadiusMeters == triggerRadiusMeters &&
      other.approachRadiusMeters == approachRadiusMeters &&
      other.triggerOncePerSession == triggerOncePerSession &&
      other.radiusNeedsConfirmation == radiusNeedsConfirmation;

  @override
  int get hashCode => Object.hash(triggerRadiusMeters, approachRadiusMeters,
      triggerOncePerSession, radiusNeedsConfirmation);
}
