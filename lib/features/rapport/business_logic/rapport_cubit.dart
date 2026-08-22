import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/rapport_repository.dart';
import 'rapport_state.dart';

class RapportCubit extends Cubit<RapportState> {
  RapportCubit(this._repository) : super(const RapportInitial());
  final RapportRepository _repository;

  Future<void> load() async {
    emit(const RapportLoading());
    try {
      final items = await _repository.getRapportList();
      if (!isClosed) emit(RapportLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(RapportError(f.userMessage));
    }
  }
}
