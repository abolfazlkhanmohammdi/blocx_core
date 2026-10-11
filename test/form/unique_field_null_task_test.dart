import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

enum UniqueTestField { username, email }

class UniqueTestFormEntity
    extends BlocxBaseFormEntity<UniqueTestFormEntity, UniqueTestField> {
  final String username;
  final String email;

  const UniqueTestFormEntity({this.username = '', this.email = ''});

  @override
  String get identifier => 'unique_form';

  @override
  UniqueTestFormEntity updateByKey(UniqueTestField key, dynamic value) {
    return switch (key) {
      UniqueTestField.username => UniqueTestFormEntity(
        username: value as String? ?? '',
        email: email,
      ),
      UniqueTestField.email => UniqueTestFormEntity(
        username: username,
        email: value as String? ?? '',
      ),
    };
  }

  @override
  dynamic getValueByKey(UniqueTestField key) {
    return switch (key) {
      UniqueTestField.username => username,
      UniqueTestField.email => email,
    };
  }
}

class TestSubmitUseCase extends BlocxBaseUseCase<void, String> {
  @override
  Future<BlocxUseCaseResult<String>> perform(void input) async {
    return success('Submitted');
  }
}

class DummyFormValidator
    extends BlocxFormValidator<UniqueTestFormEntity, UniqueTestField> {
  @override
  List<UniqueTestField> formKeys() => UniqueTestField.values;

  @override
  List<BlocxFieldValidator<UniqueTestFormEntity, UniqueTestField, dynamic>>
  getValidatorsByKey(UniqueTestFormEntity formData, UniqueTestField key) => [];
}

class NullTaskUniqueFormBloc
    extends BlocxFormBloc<UniqueTestFormEntity, void, UniqueTestField>
    with
        BlocxFormValidationMixin<UniqueTestFormEntity, void, UniqueTestField>,
        BlocxUniqueFieldValidatorMixin<
          UniqueTestFormEntity,
          void,
          UniqueTestField
        > {
  final TestSubmitUseCase _submitUseCase = TestSubmitUseCase();

  NullTaskUniqueFormBloc() : super(const UniqueTestFormEntity());

  @override
  List<UniqueTestField> get uniqueFieldKeys => [UniqueTestField.username];

  @override
  List<UniqueTestField> get formKeysList => UniqueTestField.values;

  @override
  BlocxFormValidator<UniqueTestFormEntity, UniqueTestField> get validator =>
      DummyFormValidator();

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask =>
      BlocxUseCaseTask<void, String>(
        useCase: _submitUseCase,
        inputBuilder: () {},
      );

  @override
  BlocxUseCaseTask<dynamic, bool>? useCaseIsUniqueValueAvailable(
    UniqueTestFormEntity formData,
    UniqueTestField key,
    dynamic value,
  ) {
    // Returns null to simulate unconfigured or skipped unique validation task
    return null;
  }
}

void main() {
  group('C-F: Null task in unique field validator', () {
    late NullTaskUniqueFormBloc bloc;

    setUp(() {
      bloc = NullTaskUniqueFormBloc();
    });

    tearDown(() => bloc.close());

    test(
      'does not emit pending state or register in-flight token when task is null',
      () async {
        final emittedStates =
            <BlocxFormState<UniqueTestFormEntity, UniqueTestField>>[];
        final sub = bloc.stream.listen(emittedStates.add);

        bloc.add(
          BlocxFormEventCheckUniqueValue(
            key: UniqueTestField.username,
            data: 'test_user',
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(
          bloc.uniqueKeysBeingChecked,
          isEmpty,
          reason: 'uniqueKeysBeingChecked must be empty when task is null',
        );
        expect(
          emittedStates.where(
            (s) => s.checkingUniqueFields.contains(UniqueTestField.username),
          ),
          isEmpty,
          reason:
              'No state should have been emitted with username in checkingUniqueFields',
        );

        await sub.cancel();
      },
    );
  });
}
