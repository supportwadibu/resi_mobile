import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class AddExpenseHeader extends StatelessWidget {
  const AddExpenseHeader({super.key, this.title});

  /// Titre de l'écran. Par défaut celui de la création.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => AutoRouter.of(context).maybePop(),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xffF4F5FB),
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const Spacer(),
        Text(
          title ?? "Nouvelle dépense",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
      ],
    );
  }
}
