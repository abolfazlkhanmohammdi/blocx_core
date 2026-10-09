import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/src/blocs/collection/models/blocx_page.dart';
import 'package:blocx_core/src/blocs/collection/use_cases/blocx_paginated_use_case.dart';

import 'test_entity.dart';

/// Fake paginated source with a mutable backing list.
class FakePaginatedSource {
  final List<TestItem> items;

  FakePaginatedSource([List<TestItem>? initialItems])
      : items = initialItems ??
            List.generate(
              50,
              (i) => TestItem(id: '$i', title: 'Item $i', order: i),
            );

  BlocxPage<TestItem> getPage({required int offset, required int limit}) {
    final clampedOffset = offset.clamp(0, items.length);
    final endIndex = (clampedOffset + limit).clamp(0, items.length);
    final pageItems = items.sublist(clampedOffset, endIndex);
    return BlocxPage<TestItem>(
      items: pageItems,
      offset: clampedOffset,
      limit: limit,
    );
  }
}

/// Fake paginated use case that supports success, failure, and delayed/completer responses.
class FakePaginatedUseCase
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, TestItem> {
  final FakePaginatedSource source;
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;
  Duration delay;
  final List<BlocxPaginatedInput> recordedInputs = [];

  FakePaginatedUseCase({
    FakePaginatedSource? source,
    this.shouldFail = false,
    this.failureError,
    this.completer,
    this.delay = Duration.zero,
    super.eventHub,
    super.commandType,
    super.commandTypes,
  }) : source = source ?? FakePaginatedSource();

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
      BlocxPaginatedInput input) async {
    recordedInputs.add(input);

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (completer != null) {
      await completer!.future;
    }

    if (shouldFail) {
      throw failureError ?? Exception('Paginated task failed');
    }

    final page = source.getPage(offset: input.offset, limit: input.limit);
    return success(page);
  }
}

/// Fake search use case.
class FakeSearchUseCase extends BlocxSearchUseCase<BlocxSearchInput, TestItem> {
  final FakePaginatedSource source;
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;

  FakeSearchUseCase({
    FakePaginatedSource? source,
    this.shouldFail = false,
    this.failureError,
    this.completer,
    super.eventHub,
  }) : source = source ?? FakePaginatedSource();

  @override
  Future<BlocxUseCaseResult<BlocxPage<TestItem>>> perform(
      BlocxSearchInput input) async {
    if (completer != null) {
      await completer!.future;
    }

    if (shouldFail) {
      throw failureError ?? Exception('Search task failed');
    }

    final query = input.searchText?.toLowerCase() ?? '';
    final matching = source.items
        .where((item) => item.title.toLowerCase().contains(query))
        .toList();

    final clampedOffset = input.offset.clamp(0, matching.length);
    final endIndex = (clampedOffset + input.limit).clamp(0, matching.length);
    final pageItems = matching.sublist(clampedOffset, endIndex);

    return success(BlocxPage<TestItem>(
      items: pageItems,
      offset: clampedOffset,
      limit: input.limit,
    ));
  }
}

/// General fake simple use case for testing execute & broadcast.
class FakeSimpleUseCase extends BlocxBaseUseCase<String, TestItem> {
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;
  final List<String> performedInputs = [];

  FakeSimpleUseCase({
    this.shouldFail = false,
    this.failureError,
    this.completer,
    super.eventHub,
    super.commandType,
    super.commandTypes,
  });

  @override
  Future<BlocxUseCaseResult<TestItem>> perform(String input) async {
    performedInputs.add(input);
    if (completer != null) await completer!.future;
    if (shouldFail) throw failureError ?? Exception('Simple UseCase failed');
    return success(TestItem(id: input, title: 'Item $input'));
  }
}
