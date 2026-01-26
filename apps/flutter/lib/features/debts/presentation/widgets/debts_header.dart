import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class DebtsHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const DebtsHeader({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.debtsActiveLiabilities,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
