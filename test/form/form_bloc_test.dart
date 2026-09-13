import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

enum TestField { email, password }

class TestFormEntity extends BlocxBaseFormEntity<TestFormEntity, TestField> {
  final String email;
  final String password;

  const TestFormEntity({
    this.email = '',
    this.password = '',
  });

  @override
  String get identifier => 'test_form';

  @override
  TestFormEntity updateByKey(TestField key, dynamic value) {
    return switch (key) {
      TestField.email => TestFormEntity(email: value as String? ?? '', password: password),
      TestField.password => TestFormEntity(email: email, password: value as String? ?? ''),
    };
  }

  @override
  dynamic getValueByKey(TestField key) {
    return switch (key) {
      TestField.email => email,
      TestField.password => password,
    };
  }
}

class EmailValidator extends BlocxFieldValidator<TestFormEntity, TestField, Object?> {
  const EmailValidator();

  @override
  String? validate(TestFormEntity form, TestField key, Object? value) {
    final str = value as String? ?? '';
    return str.isEmpty ? 'Email required' : null;
  }
}

class PasswordValidator extends BlocxFieldValidator<TestFormEntity, TestField, Object?> {
  const PasswordValidator();

  @override
  String? validate(TestFormEntity form, TestField key, Object? value) {
    final str = value as String? ?? '';
    return str.length < 6 ? 'Password too short' : null;
  }
}

class TestFormValidator extends BlocxFormValidator<TestFormEntity, TestField> {
  @override
  List<TestField> formKeys() => TestField.values;

  @override
  List<BlocxFieldValidator<TestFormEntity, TestField, dynamic>> getValidatorsByKey(
    TestFormEntity formData,
    TestField key,
  ) {
    return switch (key) {
      TestField.email => [const EmailValidator()],
      TestField.password => [const PasswordValidator()],
    };
  }
}

class TestSubmitUseCase extends BlocxBaseUseCase<void, String> {
  @override
  Future<BlocxUseCaseResult<String>> perform(void input) async {
    return success('Submitted successfully');
  }
}

class TestFormBloc extends BlocxFormBloc<TestFormEntity, void, TestField>
    with BlocxFormValidationMixin<TestFormEntity, void, TestField> {
  final TestSubmitUseCase _submitUseCase = TestSubmitUseCase();

  TestFormBloc() : super(const TestFormEntity());

  @override
  BlocxFormValidator<TestFormEntity, TestField> get validator => TestFormValidator();

  @override
  FormValidationMode get formValidationMode => FormValidationMode.onUserInteraction;

  @override
  List<TestField> get formKeysList => TestField.values;

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask => BlocxUseCaseTask<void, String>(
        useCase: _submitUseCase,
        inputBuilder: () {},
      );
}

void main() {
  group('BlocxBaseFormEntity', () {
    test('updateByKeySafe updates entity correctly and passes assertion', () {
      const entity = TestFormEntity();
      final updated = entity.updateByKeySafe(TestField.email, 'test@example.com');

      expect(updated.email, equals('test@example.com'));
      expect(updated.getValueByKey(TestField.email), equals('test@example.com'));
    });
  });

  group('BlocxFormBloc & Validation', () {
    late TestFormBloc bloc;

    setUp(() {
      bloc = TestFormBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('updates field and triggers field validation', () async {
      expect(bloc.formData.email, isEmpty);

      bloc.add(BlocxFormEventUpdateData(key: TestField.email, data: 'user@domain.com'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.formData.email, equals('user@domain.com'));
      expect(bloc.hasError(TestField.email), isFalse);
    });

    test('validates invalid field and records error', () async {
      bloc.add(BlocxFormEventUpdateData(key: TestField.password, data: '123'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.hasError(TestField.password), isTrue);
      expect(bloc.errors[TestField.password], contains('Password too short'));
    });

    test('blocks submit when form is invalid and submits when valid', () async {
      // Initially invalid
      bloc.add(BlocxFormEventSubmit());
      await Future.delayed(const Duration(milliseconds: 50));

      // Update valid values
      bloc.add(BlocxFormEventUpdateData(key: TestField.email, data: 'test@example.com'));
      bloc.add(BlocxFormEventUpdateData(key: TestField.password, data: '123456'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.isFormSubmittable, isTrue);

      bloc.add(BlocxFormEventSubmit());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<BlocxFormStateLoaded<TestFormEntity, TestField>>());
    });
  });
}
