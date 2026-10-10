import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

class CustomLocalizations extends BlocXLocalizations {
  @override
  String get somethingWentWrong => 'Custom something went wrong';

  @override
  String get areYouSure => 'Are you sure';

  @override
  String get areYouSureYouWantToDeleteThisItem => 'Are you sure to delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get copyDetails => 'Copy details';

  @override
  String dateRangeError(DateTime minDate, DateTime maxDate) =>
      'Date range error';

  @override
  String get delete => 'Delete';

  @override
  String get deleteItem => 'Delete item';

  @override
  String get details => 'Details';

  @override
  String get emptyListText => 'Empty';

  @override
  String errorCodeMessage(BlocXErrorCode errorCode) => 'Error code';

  @override
  String get errorDetailsCopied => 'Copied';

  @override
  String exactLengthFieldError(int length) => 'Exact length';

  @override
  String fileSizeMustBeSmallerThan(String format) => 'File size';

  @override
  String greaterThanFieldError(int otherValue) => 'Greater than';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get invalidPhoneNumber => 'Invalid phone';

  @override
  String get invalidUrl => 'Invalid url';

  @override
  String lengthRangeError(minLength, maxLength) => 'Length range';

  @override
  String lessThanFieldError(int otherValue) => 'Less than';

  @override
  String get loadingText => 'Loading';

  @override
  String maxDateError(DateTime maxDate) => 'Max date';

  @override
  String maxLengthError(maxLength) => 'Max length';

  @override
  String maxNumberOfItemsCanBeSelected(int max) => 'Max items';

  @override
  String maxValueError(num maxValue) => 'Max value';

  @override
  String minDateError(DateTime minDate) => 'Min date';

  @override
  String minLengthError(maxLength) => 'Min length';

  @override
  String minNumberOfItemsMustBeSelected(int min) => 'Min items';

  @override
  String minValueError(num minValue) => 'Min value';

  @override
  String mustBeAfterDateField(String otherFieldName) => 'Must be after';

  @override
  String mustBeBeforeDateField(String otherFieldName) => 'Must be before';

  @override
  String numberRangeError(num minValue, num maxValue) => 'Number range';

  @override
  String get onlyAlphanumericAllowed => 'Alphanumeric only';

  @override
  String get onlyNumbersAllowed => 'Numbers only';

  @override
  String get report => 'Report';

  @override
  String get selectedItemsMustBeUnique => 'Unique';

  @override
  String get thisFieldIsRequired => 'Required';

  @override
  String get tryAgain => 'Try again';

  @override
  String get valuesDoNotMatch => 'Do not match';
}

class CustomTranslator extends BlocxErrorTranslator {
  final String prefix;
  CustomTranslator(this.prefix);

  @override
  ReadableError makeErrorReadable(Object error, {StackTrace? stackTrace}) {
    return ReadableError(message: '$prefix: $error');
  }
}

class TestBaseBloc extends BlocxBaseBloc<BlocxBaseEvent, BlocxBaseState> {
  TestBaseBloc({super.errorTranslator, super.localizations})
    : super(const _TestInitialState());
}

class _TestInitialState extends BlocxBaseState {
  const _TestInitialState() : super(shouldRebuild: false, shouldListen: false);
}

class TestEntity extends BlocxBaseEntity {
  final String id;
  const TestEntity({required this.id});

  @override
  String get identifier => id;
}

class TestCollectionBloc extends BlocxCollectionBloc<TestEntity, void> {
  TestCollectionBloc({super.errorTranslator, super.localizations});

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput<dynamic>, TestEntity>?
  get paginationTask => null;
}

enum TestFormField { name }

class TestFormEntity
    extends BlocxBaseFormEntity<TestFormEntity, TestFormField> {
  final String name;
  const TestFormEntity({this.name = ''});

  @override
  String get identifier => name;

  TestFormEntity copyWith({String? name}) =>
      TestFormEntity(name: name ?? this.name);

  @override
  TestFormEntity updateByKey(TestFormField key, dynamic value) =>
      copyWith(name: value as String?);

  @override
  dynamic getValueByKey(TestFormField key) => name;
}

class TestFormBloc extends BlocxFormBloc<TestFormEntity, void, TestFormField> {
  TestFormBloc({super.errorTranslator, super.localizations})
    : super(const TestFormEntity());

  @override
  BlocxUseCaseTask get submitUseCaseTask => throw UnimplementedError();
}

void main() {
  group('Injectable config', () {
    test('falls back to static defaults when none injected', () {
      final bloc = TestBaseBloc();
      expect(bloc.errorTranslator, isNull);
      expect(bloc.localizations, equals(BlocXLocalizations.localizations));
      expect(bloc.defaultError.message, equals('Something went wrong'));
      bloc.close();
    });

    test('BlocxErrorTranslator exposes static instance alias', () {
      expect(
        BlocxErrorTranslator.instance,
        equals(BlocxErrorTranslator.errorTranslator),
      );
    });

    test(
      'BlocxBaseBloc accepts injected errorTranslator and localizations',
      () {
        final translator = CustomTranslator('CUSTOM');
        final loc = CustomLocalizations();
        final bloc = TestBaseBloc(
          errorTranslator: translator,
          localizations: loc,
        );

        expect(bloc.errorTranslator, equals(translator));
        expect(bloc.localizations, equals(loc));
        expect(bloc.loc, equals(loc));
        expect(
          bloc.defaultError.message,
          equals('Custom something went wrong'),
        );

        final readable = bloc.readableErrorOf(Exception('boom'));
        expect(readable.message, equals('CUSTOM: Exception: boom'));
        bloc.close();
      },
    );

    test(
      'BlocxCollectionBloc accepts injected config and forwards to base',
      () {
        final translator = CustomTranslator('COLL');
        final loc = CustomLocalizations();
        final bloc = TestCollectionBloc(
          errorTranslator: translator,
          localizations: loc,
        );

        expect(bloc.errorTranslator, equals(translator));
        expect(bloc.localizations, equals(loc));
        expect(
          bloc.defaultError.message,
          equals('Custom something went wrong'),
        );
        bloc.close();
      },
    );

    test('BlocxFormBloc accepts injected config and forwards to base', () {
      final translator = CustomTranslator('FORM');
      final loc = CustomLocalizations();
      final bloc = TestFormBloc(
        errorTranslator: translator,
        localizations: loc,
      );

      expect(bloc.errorTranslator, equals(translator));
      expect(bloc.localizations, equals(loc));
      expect(bloc.defaultError.message, equals('Custom something went wrong'));
      bloc.close();
    });
  });
}
