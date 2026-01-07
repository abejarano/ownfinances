class GoalProjection {
  final double progress;
  final double remaining;
  final double targetAmount;
  final double? monthlyContributionSuggested;
  final DateTime? targetDateEstimated;

  const GoalProjection({
    required this.progress,
    required this.remaining,
    required this.targetAmount,
    required this.monthlyContributionSuggested,
    required this.targetDateEstimated,
  });

  factory GoalProjection.fromJson(Map<String, dynamic> json) {
    return GoalProjection(
      progress: (json["progress"] as num?)?.toDouble() ?? 0,
      remaining: (json["remaining"] as num?)?.toDouble() ?? 0,
      targetAmount: (json["targetAmount"] as num?)?.toDouble() ?? 0,
      monthlyContributionSuggested:
          (json["monthlyContributionSuggested"] as num?)?.toDouble(),
      targetDateEstimated: json["targetDateEstimated"] != null
          ? DateTime.parse(json["targetDateEstimated"] as String)
          : null,
    );
  }
}
