import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';

class ExpenseHeader extends StatelessWidget {
  const ExpenseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => AutoRouter.of(context).maybePop(),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const Spacer(),
        const Text(
          "Historique des dépenses",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          // Le rechargement de la liste au retour est pris en charge par
          // l'écran, via `didPopNext`.
          onTap: () => AutoRouter.of(context).push(AddExpenseRoute()),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black,
            child: Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}
