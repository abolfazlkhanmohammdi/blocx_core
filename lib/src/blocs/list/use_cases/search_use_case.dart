import 'package:blocx_core/blocx_core.dart';

abstract class SearchUseCase<T extends BaseEntity> extends BaseUseCase<Page<T>> {
  final String searchText;
  final int loadCount;
  final int offset;
  SearchUseCase({required this.searchText, required this.loadCount, required this.offset});

  UseCaseResult<Page<T>> successResult(List<T> items) {
    return UseCaseResult<Page<T>>.success(Page<T>(items: items, offset: offset, loadCount: loadCount));
  }
}
