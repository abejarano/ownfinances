import 'package:flutter_test/flutter_test.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Transaction', () {
    test(
      'should parse correctly from valid JSON including recurringRuleId',
      () {
        final json = {
          'id': 'tx-123',
          'type': 'expense',
          'amount': 100.50,
          'currency': 'BRL',
          'date': '2023-10-27T10:00:00.000Z',
          'categoryId': 'cat-1',
          'fromAccountId': 'acc-1',
          'note': 'Test note',
          'tags': ['food', 'lunch'],
          'recurringRuleId': 'rule-abc',
          'status': 'pending',
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.id, 'tx-123');
        expect(transaction.recurringRuleId, 'rule-abc');
        expect(transaction.amount, 100.50);
        expect(transaction.tags, ['food', 'lunch']);
      },
    );

    test('should parse correctly without optional fields', () {
      final json = {
        'id': 'tx-456',
        'type': 'income',
        'amount': 2000.00,
        'currency': 'BRL',
        'date': '2023-10-28T10:00:00.000Z',
        'toAccountId': 'acc-2',
        'status': 'cleared',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 'tx-456');
      expect(transaction.recurringRuleId, null);
      expect(transaction.note, null);
      expect(transaction.tags, isEmpty);
    });
  });
}
