import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/core/use_cases/base_use_case.dart';

abstract class PaginationUseCase<T extends BaseEntity, S> extends BaseUseCase<Page<T>> {
  final PaginationQuery<S> queryInput;
  PaginationUseCase({required this.queryInput});

  UseCaseResult<Page<T>> successResult(List<T> items) {
    return UseCaseResult.success(
      Page(items: items, offset: queryInput.offset, loadCount: queryInput.loadCount),
    );
  }
}
