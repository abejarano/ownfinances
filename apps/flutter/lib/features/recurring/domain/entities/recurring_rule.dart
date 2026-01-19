class RecurringRule {
  final String id;
  final String userId;
  final String frequency;
  final int interval;
  final DateTime startDate;
  final DateTime? endDate;
  final RecurringTemplate template;
  final bool active;
  final DateTime? lastRunAt;

  RecurringRule({
    required this.id,
    required this.userId,
    required this.frequency,
    required this.interval,
    required this.startDate,
    this.endDate,
    required this.template,
    required this.active,
    this.lastRunAt,
  });

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      id: json['recurringRuleId'] ?? json['ruleId'],
      userId: json['userId'],
      frequency: json['frequency'],
      interval: json['interval'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      template: RecurringTemplate.fromJson(json['template']),
      active: json['isActive'] ?? json['active'],
      lastRunAt: json['lastRunAt'] != null
          ? DateTime.parse(json['lastRunAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'frequency': frequency,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'template': template.toJson(),
      'active': active,
      'lastRunAt': lastRunAt?.toIso8601String(),
    };
  }
}

class RecurringTemplate {
  final double amount;
  final String type; // 'income', 'expense', 'transfer'
  final String currency;
  final String? categoryId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? note;
  final List<String>? tags;

  RecurringTemplate({
    required this.amount,
    required this.type,
    required this.currency,
    this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    this.note,
    this.tags,
  });

  factory RecurringTemplate.fromJson(Map<String, dynamic> json) {
    return RecurringTemplate(
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      currency: json['currency'],
      categoryId: json['categoryId'],
      fromAccountId: json['fromAccountId'],
      toAccountId: json['toAccountId'],
      note: json['note'],
      tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'currency': currency,
      'categoryId': categoryId,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'note': note,
      'tags': tags,
    };
  }
}

class RecurringPreviewItem {
  final String recurringRuleId;
  final DateTime date;
  final RecurringTemplate template;
  final String status; // 'new' | 'already_generated'

  RecurringPreviewItem({
    required this.recurringRuleId,
    required this.date,
    required this.template,
    required this.status,
  });

  factory RecurringPreviewItem.fromJson(Map<String, dynamic> json) {
    return RecurringPreviewItem(
      recurringRuleId: json['recurringRuleId'],
      date: DateTime.parse(json['date']),
      template: RecurringTemplate.fromJson(json['template']),
      status: json['status'],
    );
  }
}
