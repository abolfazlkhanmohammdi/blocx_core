import 'package:blocx_core/blocx_core.dart';

abstract class BlocxPaginationUseCase<T extends BaseEntity> extends BlocxBaseUseCase<Page<T>> {
  final int loadCount;
  final int offset;
  BlocxPaginationUseCase({required this.loadCount, required this.offset});

  UseCaseResult<Page<T>> successResult(List<T> items) {
    return UseCaseResult.success(Page(items: items, offset: offset, loadCount: loadCount));
  }
}
