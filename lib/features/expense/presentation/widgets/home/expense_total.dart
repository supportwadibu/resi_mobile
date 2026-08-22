import 'package:flutter/material.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

class ExpenseTotal extends StatelessWidget {
  final double total;

  const ExpenseTotal({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text(
            "Total Dépenses",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Spacer(),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
