import 'package:blocx/src/core/models/base_entity.dart';
import 'package:blocx/src/list/models/page.dart';
import 'package:blocx/src/list/models/search_query.dart';
import 'package:blocx/src/core/use_cases/base_use_case.dart';

abstract class SearchUseCase<T extends BaseEntity, P> extends BaseUseCase<Page<T>, SearchQuery<P>> {}
