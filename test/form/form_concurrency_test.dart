import 'dart:async';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

enum ConcurrencyField { fieldA, fieldB }

class ConcurrencyFormEntity
    extends BlocxBaseFormEntity<ConcurrencyFormEntity, ConcurrencyField> {
  final String valA;
  final String valB;

  const ConcurrencyFormEntity({this.valA = '', this.valB = ''});

  @override
  String get identifier => 'concurrency_form';

  @override
  ConcurrencyFormEntity updateByKey(ConcurrencyField key, dynamic value) {
    return switch (key) {
      ConcurrencyField.fieldA => ConcurrencyFormEntity(
        valA: value as String? ?? '',
        valB: valB,
      ),
      ConcurrencyField.fieldB => ConcurrencyFormEntity(
        valA: valA,
        valB: value as String? ?? '',
      ),
    };
  }

  @override
  dynamic getValueByKey(ConcurrencyField key) {
    return switch (key) {
      ConcurrencyField.fieldA => valA,
      ConcurrencyField.fieldB => valB,
    };
  }
}

class ControlledSubmitUseCase extends BlocxBaseUseCase<void, String> {
  int executeCount = 0;
  Completer<void>? completer;

  @override
  Future<BlocxUseCaseResult<String>> perform(void input) async {
    executeCount++;
    if (completer != null) {
      await completer!.future;
    }
    return success('done');
  }
}

class _DummyValidator
    extends BlocxFormValidator<ConcurrencyFormEntity, ConcurrencyField> {
  _DummyValidator();

  @override
  List<ConcurrencyField> formKeys() => ConcurrencyField.values;

  @override
  List<BlocxFieldValidator<ConcurrencyFormEntity, ConcurrencyField, dynamic>>
  getValidatorsByKey(ConcurrencyFormEntity formData, ConcurrencyField key) =>
      const [];
}

class ConcurrencyFormBloc
    extends BlocxFormBloc<ConcurrencyFormEntity, String, ConcurrencyField>
    with
        BlocxFormValidationMixin<
          ConcurrencyFormEntity,
          String,
          ConcurrencyField
        > {
  final ControlledSubmitUseCase submitUseCase;
  Completer<void>? slowPayloadCompleter;

  ConcurrencyFormBloc({required this.submitUseCase})
    : super(const ConcurrencyFormEntity());

  @override
  BlocxFormValidator<ConcurrencyFormEntity, ConcurrencyField> get validator =>
      _DummyValidator();

  @override
  List<ConcurrencyField> get formKeysList => ConcurrencyField.values;

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask =>
      BlocxUseCaseTask<void, String>(
        useCase: submitUseCase,
        inputBuilder: () {},
      );

  @override
  FutureOr<ConcurrencyFormEntity> applyPayloadToFormData(String payload) async {
    if (payload == 'slow') {
      if (slowPayloadCompleter != null) {
        await slowPayloadCompleter!.future;
      }
      return const ConcurrencyFormEntity(valA: 'slow_val');
    } else if (payload == 'fast') {
      return const ConcurrencyFormEntity(valA: 'fast_val');
    }
    return formData;
  }
}

void main() {
  group('K4: Form event concurrency', () {
    test(
      'two UpdateData events for different keys back-to-back both apply sequentially',
      () async {
        final submitUseCase = ControlledSubmitUseCase();
        final bloc = ConcurrencyFormBloc(submitUseCase: submitUseCase);

        bloc.add(
          BlocxFormEventUpdateData<ConcurrencyField>(
            key: ConcurrencyField.fieldA,
            data: 'alpha',
          ),
        );
        bloc.add(
          BlocxFormEventUpdateData<ConcurrencyField>(
            key: ConcurrencyField.fieldB,
            data: 'beta',
          ),
        );

        await bloc.stream.firstWhere(
          (s) => s.formData.valA == 'alpha' && s.formData.valB == 'beta',
        );

        expect(bloc.formData.valA, equals('alpha'));
        expect(bloc.formData.valB, equals('beta'));

        await bloc.close();
      },
    );

    test(
      'two Submit events while first is running drops the second (droppable)',
      () async {
        final submitUseCase = ControlledSubmitUseCase();
        final submitCompleter = Completer<void>();
        submitUseCase.completer = submitCompleter;

        final bloc = ConcurrencyFormBloc(submitUseCase: submitUseCase);

        // Dispatch two submit events back-to-back
        bloc.add(BlocxFormEventSubmit());
        await Future<void>.delayed(Duration.zero);
        expect(submitUseCase.executeCount, equals(1));

        bloc.add(BlocxFormEventSubmit());
        await Future<void>.delayed(Duration.zero);

        // Complete the in-flight submit
        submitCompleter.complete();
        await pumpEventQueue();

        // Submit use case was executed once, NOT twice!
        expect(
          submitUseCase.executeCount,
          equals(1),
          reason:
              'Second submit while first was running should have been dropped',
        );

        // After completion, a new Submit CAN run
        submitUseCase.completer = null;
        bloc.add(BlocxFormEventSubmit());
        await pumpEventQueue();
        expect(submitUseCase.executeCount, equals(2));

        await bloc.close();
      },
    );

    test(
      'Init restarted with different payload cancels first and takes second (restartable)',
      () async {
        final submitUseCase = ControlledSubmitUseCase();
        final bloc = ConcurrencyFormBloc(submitUseCase: submitUseCase);
        final slowCompleter = Completer<void>();
        bloc.slowPayloadCompleter = slowCompleter;

        bloc.add(BlocxFormEventInit<String>(payload: 'slow'));
        await pumpEventQueue();

        bloc.add(BlocxFormEventInit<String>(payload: 'fast'));
        await bloc.stream.firstWhere((s) => s.formData.valA == 'fast_val');

        // Complete the canceled slow task; its result should be ignored by restartable
        slowCompleter.complete();
        await pumpEventQueue();

        expect(
          bloc.formData.valA,
          equals('fast_val'),
          reason: 'Init restarted with second payload must result in fast_val',
        );

        await bloc.close();
      },
    );
  });
}
