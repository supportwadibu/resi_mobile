// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i4;
import 'package:resi_africa/features/expense/data/models/expense_model.dart'
    as _i5;
import 'package:resi_africa/features/expense/presentation/screens/add_expense_screen.dart'
    as _i1;
import 'package:resi_africa/features/expense/presentation/screens/expense_screen.dart'
    as _i2;

/// generated route for
/// [_i1.AddExpenseScreen]
class AddExpenseRoute extends _i3.PageRouteInfo<AddExpenseRouteArgs> {
  AddExpenseRoute({
    _i4.Key? key,
    _i5.ExpenseModel? expense,
    List<_i3.PageRouteInfo>? children,
  }) : super(
         AddExpenseRoute.name,
         args: AddExpenseRouteArgs(key: key, expense: expense),
         initialChildren: children,
       );

  static const String name = 'AddExpenseRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddExpenseRouteArgs>(
        orElse: () => const AddExpenseRouteArgs(),
      );
      return _i1.AddExpenseScreen(key: args.key, expense: args.expense);
    },
  );
}

class AddExpenseRouteArgs {
  const AddExpenseRouteArgs({this.key, this.expense});

  final _i4.Key? key;

  final _i5.ExpenseModel? expense;

  @override
  String toString() {
    return 'AddExpenseRouteArgs{key: $key, expense: $expense}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddExpenseRouteArgs) return false;
    return key == other.key && expense == other.expense;
  }

  @override
  int get hashCode => key.hashCode ^ expense.hashCode;
}

/// generated route for
/// [_i2.ExpenseScreen]
class ExpenseRoute extends _i3.PageRouteInfo<void> {
  const ExpenseRoute({List<_i3.PageRouteInfo>? children})
    : super(ExpenseRoute.name, initialChildren: children);

  static const String name = 'ExpenseRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      return const _i2.ExpenseScreen();
    },
  );
}
