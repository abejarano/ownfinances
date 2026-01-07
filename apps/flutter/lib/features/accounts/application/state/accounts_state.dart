import "package:ownfinances/features/accounts/domain/entities/account.dart";

class AccountsState {
  final bool isLoading;
  final List<Account> items;
  final String? error;

  const AccountsState({
    required this.isLoading,
    required this.items,
    this.error,
  });

  AccountsState copyWith({
    bool? isLoading,
    List<Account>? items,
    String? error,
  }) {
    return AccountsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }

  static const initial = AccountsState(isLoading: false, items: []);
}
