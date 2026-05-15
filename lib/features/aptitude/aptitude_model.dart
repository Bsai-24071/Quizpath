import 'package:flutter/material.dart';

class AptitudeResult {
  final String category;
  final double accuracy;
  final int questionsAttempted;
  final double averageTime;
  final List<String> recommendedFields;

  AptitudeResult({
    required this.category,
    required this.accuracy,
    required this.questionsAttempted,
    required this.averageTime,
    required this.recommendedFields,
  });

  factory AptitudeResult.fromMap(Map<String, dynamic> map) {
    return AptitudeResult(
      category: map['category'] ?? '',
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      questionsAttempted: map['questionsAttempted'] ?? 0,
      averageTime: (map['averageTime'] ?? 0.0).toDouble(),
      recommendedFields: List<String>.from(map['recommendedFields'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'accuracy': accuracy,
      'questionsAttempted': questionsAttempted,
      'averageTime': averageTime,
      'recommendedFields': recommendedFields,
    };
  }

  String get performanceLevel {
    if (accuracy >= 80) return 'Excellent';
    if (accuracy >= 60) return 'Good';
    if (accuracy >= 40) return 'Average';
    return 'Needs Improvement';
  }

  static Color getPerformanceColor(double accuracy) {
    if (accuracy >= 80) return const Color(0xFF4CAF50);
    if (accuracy >= 60) return const Color(0xFF2196F3);
    if (accuracy >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

