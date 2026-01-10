import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/recurring/presentation/modals/catchup_preview_modal.dart';
import 'package:intl/intl.dart';

class CatchupBanner extends StatefulWidget {
  const CatchupBanner({super.key});

  @override
  State<CatchupBanner> createState() => _CatchupBannerState();
}

class _CatchupBannerState extends State<CatchupBanner> {
  List<Map<String, dynamic>> _catchupMonths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatchup();
  }

  Future<void> _loadCatchup() async {
    try {
      final result = await context.read<RecurringController>().getCatchupSummary();
      setState(() {
        _catchupMonths = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy', 'pt_BR').format(date);
    } catch (e) {
      return monthStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _catchupMonths.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalPending = _catchupMonths.fold<int>(
      0,
      (sum, month) => sum + (month['count'] as int? ?? 0),
    );

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    "Você tem meses passados sem gerar!",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "${_catchupMonths.length} ${_catchupMonths.length == 1 ? 'mês' : 'meses'} pendente${_catchupMonths.length == 1 ? '' : 's'} com $totalPending lançamento${totalPending == 1 ? '' : 's'}",
              style: TextStyle(color: Colors.orange.shade800),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<RecurringController>(),
                          child: CatchupPreviewModal(months: _catchupMonths),
                        ),
                      ).then((_) {
                        // Reload after modal closes
                        _loadCatchup();
                      });
                    },
                    icon: const Icon(Icons.update),
                    label: const Text("Gerar agora"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    // Dismiss for now (could add "don't show again" logic)
                    setState(() {
                      _catchupMonths = [];
                    });
                  },
                  child: const Text("Depois"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
