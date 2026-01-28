import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetSmartAddModal extends StatefulWidget {
  final List<Category> categories;
  final String primaryCurrency;
  final Future<void> Function(
    String categoryId,
    double amount,
    String? description,
  )
  onSubmit;

  const BudgetSmartAddModal({
    super.key,
    required this.categories,
    required this.primaryCurrency,
    required this.onSubmit,
  });

  @override
  State<BudgetSmartAddModal> createState() => _BudgetSmartAddModalState();
}

class _BudgetSmartAddModalState extends State<BudgetSmartAddModal> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = "expense";
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleTypeChange(String type) {
    setState(() {
      _selectedType = type;
      _selectedCategoryId = null; // Reset category when type changes
    });
  }

  Future<void> _handleSubmit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(",", "")) ?? 0.0;
    if (_selectedCategoryId == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSubmit(
        _selectedCategoryId!,
        amount,
        _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredCategories =
        widget.categories.where((c) => c.kind == _selectedType).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final isValid = _selectedCategoryId != null && amount > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.budgetsModalTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Type Toggle
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: "expense",
                label: Text(l10n.budgetsPlanTypeExpense),
                icon: const Icon(Icons.arrow_downward, size: 16),
              ),
              ButtonSegment(
                value: "income",
                label: Text(l10n.budgetsPlanTypeIncome),
                icon: const Icon(Icons.arrow_upward, size: 16),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<String> newSelection) {
              _handleTypeChange(newSelection.first);
            },
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Category Selector
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l10n.budgetsPlanCategoryLabel,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            value: _selectedCategoryId,
            items: filteredCategories.map((c) {
              return DropdownMenuItem(value: c.id, child: Text(c.name));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Amount and Description
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        "${l10n.budgetsPlanAmountLabel} (${widget.primaryCurrency})",
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.budgetsPlanDescriptionLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.budgetsModalButtonAdd,
            onPressed: isValid && !_isLoading ? _handleSubmit : null,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
