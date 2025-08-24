import 'package:blocx/blocx.dart';
import 'package:blocx/src/blocs/list/models/search_query.dart';

abstract class SearchUseCase<T extends BaseEntity, P> extends BaseUseCase<Page<T>> {
  final SearchQuery<P> searchQuery;
  SearchUseCase({required this.searchQuery});

  UseCaseResult<Page<T>> successResult(List<T> items) {
    return UseCaseResult<Page<T>>.success(
      Page<T>(items: items, offset: searchQuery.offset, loadCount: searchQuery.loadCount),
    );
  }
}
