import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/error/failures.dart';
import '../data/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());
  final HomeRepository _repository;

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final items = await _repository.getHomeList();
      if (!isClosed) emit(HomeLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(HomeError(f.userMessage));
    }
  }
}
