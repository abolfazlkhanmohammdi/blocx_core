import 'package:blocx_core/blocx_core.dart';
import 'package:test/test.dart';

void main() {
  group('BlocXLocalizations', () {
    test('default localizations provides searchingText and searchHint', () {
      final loc = BlocXLocalizations.localizations;
      expect(loc.searchingText, equals('Searching data, please wait'));
      expect(loc.searchHint, equals('Search...'));
    });

    test('custom localizations can override searchingText and searchHint', () {
      final loc = _CustomSearchLocalizations();
      expect(loc.searchingText, equals('Searching...'));
      expect(loc.searchHint, equals('Find items...'));
    });
  });
}

class _CustomSearchLocalizations extends BlocXLocalizations {
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
