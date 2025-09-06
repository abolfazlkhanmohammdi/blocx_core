import 'package:blocx_core/blocx_core.dart';

abstract class PaginationUseCase<T extends BaseEntity, S> extends BaseUseCase<Page<T>> {
  final int loadCount;
  final int offset;
  PaginationUseCase({required this.loadCount, required this.offset});

  UseCaseResult<Page<T>> successResult(List<T> items) {
    return UseCaseResult.success(Page(items: items, offset: offset, loadCount: loadCount));
  }
}
