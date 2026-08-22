import '../data/models/finance/finance_overview_model.dart';

sealed class FinanceState {
  const FinanceState();
}

final class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

final class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

final class FinanceLoaded extends FinanceState {
  const FinanceLoaded(this.overview);
  final FinanceOverviewModel overview;
}

final class FinanceError extends FinanceState {
  const FinanceError(this.message);
  final String message;
}
