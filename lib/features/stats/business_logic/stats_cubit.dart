import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/stats_repository.dart';
import 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._repository) : super(const StatsInitial());
  final StatsRepository _repository;

  Future<void> load() async {
    emit(const StatsLoading());
    try {
      final items = await _repository.getStatsList();
      if (!isClosed) emit(StatsLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(StatsError(f.userMessage));
    }
  }
}
