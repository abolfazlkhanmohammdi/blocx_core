import 'package:blocx_core/blocx_core.dart';

abstract class SearchUseCase<T extends BaseEntity> extends BlocxPaginationUseCase<T> {
  final String searchText;
  SearchUseCase({required this.searchText, required super.loadCount, required super.offset});

  UseCaseResult<Page<T>> successResult(List<T> items) {
    return UseCaseResult<Page<T>>.success(Page<T>(items: items, offset: offset, loadCount: loadCount));
  }
}
