import 'package:flutter/material.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const MonthPickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialDate.year;
  }

  void _changeYear(int offset) {
    setState(() {
      _currentYear += offset;
      if (_currentYear < widget.firstDate.year)
        _currentYear = widget.firstDate.year;
      if (_currentYear > widget.lastDate.year)
        _currentYear = widget.lastDate.year;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentYear > widget.firstDate.year
                      ? () => _changeYear(-1)
                      : null,
                ),
                Text(
                  "$_currentYear",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentYear < widget.lastDate.year
                      ? () => _changeYear(1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final date = DateTime(_currentYear, month);
                final isSelected =
                    _currentYear == widget.initialDate.year &&
                    month == widget.initialDate.month;

                final now = DateTime.now();
                final isCurrentMonth =
                    _currentYear == now.year && month == now.month;

                return InkWell(
                  onTap: () => Navigator.of(context).pop(date),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : isCurrentMonth
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentMonth && !isSelected
                          ? Border.all(color: Theme.of(context).primaryColor)
                          : null,
                    ),
                    child: Text(
                      _getMonthName(month),
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected || isCurrentMonth
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez",
    ];
    return months[month - 1];
  }
}
