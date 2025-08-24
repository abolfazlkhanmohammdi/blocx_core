import 'package:blocx/src/blocs/list/models/page.dart';

class SearchQuery<P> extends PaginationQuery<P> {
  final String searchText;
  final P? parameter;
  SearchQuery({
    required this.searchText,
    this.parameter,
    required super.payload,
    required super.loadCount,
    required super.offset,
  });
}
