import 'package:blocx/src/core/models/base_entity.dart';
import 'package:blocx/src/core/models/page.dart';
import 'package:blocx/src/core/use_cases/base_use_case.dart';

abstract class PaginationUseCase<T extends BaseEntity, S> extends BaseUseCase<Page<T>, PaginationQuery<S>> {}
