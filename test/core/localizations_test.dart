import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:test/test.dart';

import '../helpers/helpers.dart';

void main() {
  group('BlocXLocalizations', () {
    test('default localizations provides searchingText and searchHint', () {
      final loc = BlocXLocalizations.localizations;
      expect(loc.searchingText, equals('Searching data, please wait'));
      expect(loc.searchHint, equals('Search...'));
      expect(loc.itemDeleted, equals('Item deleted'));
      expect(loc.itemDeleteFailed, equals('Failed to delete item'));
    });

    test('custom localizations can override itemDeleted and itemDeleteFailed', () {
      final loc = _CustomSearchLocalizations();
      expect(loc.searchingText, equals('Searching...'));
      expect(loc.searchHint, equals('Find items...'));
      expect(loc.itemDeleted, equals('Element supprimé'));
      expect(loc.itemDeleteFailed, equals('Échec de suppression'));
    });

    test('injected custom localizations are used by onItemDeleted snackbars', () async {
      final customLoc = _CustomSearchLocalizations();
      final bloc = _TestDeletableCollectionBloc(localizations: customLoc);
      final emittedStates = <ScreenManagerCubitState>[];
      final sub = bloc.screenManagerCubit.stream.listen(emittedStates.add);

      // Trigger successful delete hook
      bloc.onItemDeleted(const TestItem(id: '1', title: 'Item 1'), true);
      await Future<void>.delayed(Duration.zero);
      expect(emittedStates.any((s) =>
          s is ScreenManagerCubitStateDisplaySnackbar &&
          s.message == 'Element supprimé'), isTrue);

      // Trigger failed delete hook
      bloc.onItemDeleted(const TestItem(id: '1', title: 'Item 1'), false);
      await Future<void>.delayed(Duration.zero);
      expect(emittedStates.any((s) =>
          s is ScreenManagerCubitStateDisplaySnackbar &&
          s.message == 'Échec de suppression'), isTrue);

      await sub.cancel();
      await bloc.close();
    });
  });
}

class _CustomSearchLocalizations extends BlocXLocalizations {
  @override
  String get itemDeleted => 'Element supprimé';

  @override
  String get itemDeleteFailed => 'Échec de suppression';

  @override
  String get searchingText => 'Searching...';

  @override
  String get searchHint => 'Find items...';

  @override
  String get areYouSure => '';

  @override
  String get areYouSureYouWantToDeleteThisItem => '';

  @override
  String get cancel => '';

  @override
  String get close => '';

  @override
  String get copyDetails => '';

  @override
  String dateRangeError(DateTime minDate, DateTime maxDate) => '';

  @override
  String get delete => '';

  @override
  String get deleteItem => '';

  @override
  String get details => '';

  @override
  String get emptyListText => '';

  @override
  String errorCodeMessage(BlocXErrorCode errorCode) => '';

  @override
  String get errorDetailsCopied => '';

  @override
  String exactLengthFieldError(int length) => '';

  @override
  String fileSizeMustBeSmallerThan(String format) => '';

  @override
  String greaterThanFieldError(int otherValue) => '';

  @override
  String get invalidEmail => '';

  @override
  String get invalidPhoneNumber => '';

  @override
  String get invalidUrl => '';

  @override
  String lengthRangeError(minLength, maxLength) => '';

  @override
  String lessThanFieldError(int otherValue) => '';

  @override
  String get loadingText => '';

  @override
  String maxDateError(DateTime maxDate) => '';

  @override
  String maxLengthError(maxLength) => '';

  @override
  String maxNumberOfItemsCanBeSelected(int max) => '';

  @override
  String maxValueError(num maxValue) => '';

  @override
  String minDateError(DateTime minDate) => '';

  @override
  String minLengthError(maxLength) => '';

  @override
  String minNumberOfItemsMustBeSelected(int min) => '';

  @override
  String minValueError(num minValue) => '';

  @override
  String mustBeAfterDateField(String otherFieldName) => '';

  @override
  String mustBeBeforeDateField(String otherFieldName) => '';

  @override
  String numberRangeError(num minValue, num maxValue) => '';

  @override
  String get onlyAlphanumericAllowed => '';

  @override
  String get onlyNumbersAllowed => '';

  @override
  String get report => '';

  @override
  String get selectedItemsMustBeUnique => '';

  @override
  String get somethingWentWrong => '';

  @override
  String get thisFieldIsRequired => '';

  @override
  String get tryAgain => '';

  @override
  String get valuesDoNotMatch => '';
}

class _TestDeletableCollectionBloc
    extends BlocxCollectionBloc<TestItem, void>
    with BlocxCollectionDeletableMixin<TestItem, void> {
  _TestDeletableCollectionBloc({super.localizations});

  @override
  bool get displayDeletedSnackbar => true;
}
