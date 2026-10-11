import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

enum TestField { email, password }

class TestFormEntity extends BlocxBaseFormEntity<TestFormEntity, TestField> {
  final String email;
  final String password;

  const TestFormEntity({this.email = '', this.password = ''});

  @override
  String get identifier => 'test_stepped_form';

  @override
  TestFormEntity updateByKey(TestField key, dynamic value) {
    return switch (key) {
      TestField.email => TestFormEntity(
        email: value as String? ?? '',
        password: password,
      ),
      TestField.password => TestFormEntity(
        email: email,
        password: value as String? ?? '',
      ),
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

class _DummySubmitUseCase extends BlocxBaseUseCase<Object?, Object?> {
  @override
  Future<BlocxUseCaseResult<Object?>> perform(Object? input) async =>
      success(null);
}

class SteppedTestFormBloc extends BlocxFormBloc<TestFormEntity, void, TestField>
    with BlocxFormSteppedMixin<TestFormEntity, void, TestField> {
  final int max;

  SteppedTestFormBloc({this.max = 2}) : super(const TestFormEntity());

  @override
  int get maxStep => max;

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask => BlocxUseCaseTask(
    useCase: _DummySubmitUseCase(),
    inputBuilder: () => null,
  );
}

class _DummyEmitter<S> implements Emitter<S> {
  @override
  void call(S state) {}

  @override
  Future<void> forEach<T>(
    Stream<T> stream, {
    required S Function(T data) onData,
    S Function(Object error, StackTrace stackTrace)? onError,
  }) async {}

  @override
  bool get isDone => false;

  @override
  Future<void> onEach<T>(
    Stream<T> stream, {
    required void Function(T data) onData,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {}
}

void main() {
  group('C-D: Stepped form mixin boundary guards', () {
    test(
      'valid nextStep, previousStep, and goToStep emit correct step and direction',
      () async {
        final bloc = SteppedTestFormBloc(max: 2);
        expect(bloc.stepIndex, equals(0));

        bloc.add(BlocxFormEventNextStep());
        await pumpEventQueue();

        expect(bloc.stepIndex, equals(1));
        expect(bloc.state.step, equals(1));
        expect(bloc.state.comesFromPreviousStep, isTrue);

        bloc.add(BlocxFormEventPreviousStep());
        await pumpEventQueue();

        expect(bloc.stepIndex, equals(0));
        expect(bloc.state.step, equals(0));
        expect(bloc.state.comesFromPreviousStep, isFalse);

        bloc.add(BlocxFormEventGoToStep(2));
        await pumpEventQueue();

        expect(bloc.stepIndex, equals(2));
        expect(bloc.state.step, equals(2));
        expect(bloc.state.comesFromPreviousStep, isTrue);

        await bloc.close();
      },
    );

    blocTest<SteppedTestFormBloc, BlocxFormState<TestFormEntity, TestField>>(
      'previousStep at step 0 is ignored without throwing',
      build: () => SteppedTestFormBloc(max: 2),
      act: (bloc) => bloc.add(BlocxFormEventPreviousStep()),
      expect: () => <BlocxFormState<TestFormEntity, TestField>>[],
      verify: (bloc) => expect(bloc.stepIndex, equals(0)),
      errors: () => isEmpty,
    );

    blocTest<SteppedTestFormBloc, BlocxFormState<TestFormEntity, TestField>>(
      'nextStep at maxStep is ignored without throwing',
      build: () => SteppedTestFormBloc(max: 1),
      seed: () => BlocxFormStateLoaded<TestFormEntity, TestField>(
        formData: const TestFormEntity(),
        step: 1,
        errors: const {},
        fieldsFetchingInfo: const {},
        checkingUniqueFields: const {},
        comesFromPreviousStep: true,
        isFormValid: true,
      ),
      act: (bloc) {
        bloc.setStepIndex(1);
        bloc.add(BlocxFormEventNextStep());
      },
      expect: () => <BlocxFormState<TestFormEntity, TestField>>[],
      verify: (bloc) => expect(bloc.stepIndex, equals(1)),
      errors: () => isEmpty,
    );

    test(
      'goToStep out of range triggers AssertionError when asserts enabled or is ignored',
      () async {
        final bloc = SteppedTestFormBloc(max: 2);
        final dummyEmitter =
            _DummyEmitter<BlocxFormState<TestFormEntity, TestField>>();

        var assertsEnabled = false;
        assert(() {
          assertsEnabled = true;
          return true;
        }());

        if (assertsEnabled) {
          // In checked mode, calling goToStep throws AssertionError
          expect(
            () => bloc.goToStep(BlocxFormEventGoToStep(5), dummyEmitter),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => bloc.goToStep(BlocxFormEventGoToStep(-1), dummyEmitter),
            throwsA(isA<AssertionError>()),
          );
        } else {
          bloc.add(BlocxFormEventGoToStep(5));
          await pumpEventQueue();
          expect(bloc.stepIndex, equals(0));
        }

        await bloc.close();
      },
    );
  });
}
