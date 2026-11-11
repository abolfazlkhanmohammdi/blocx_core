import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

enum ReadinessField { name, username, country }

class ReadinessFormEntity
    extends BlocxBaseFormEntity<ReadinessFormEntity, ReadinessField> {
  final String id;
  final String name;
  final String username;
  final String country;

  const ReadinessFormEntity({
    this.id = 'draft',
    this.name = '',
    this.username = '',
    this.country = '',
  });

  @override
  String get identifier => id;

  ReadinessFormEntity copyWith({
    String? id,
    String? name,
    String? username,
    String? country,
  }) {
    return ReadinessFormEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      country: country ?? this.country,
    );
  }

  @override
  ReadinessFormEntity updateByKey(ReadinessField key, dynamic value) =>
      switch (key) {
        ReadinessField.name => copyWith(name: value as String? ?? ''),
        ReadinessField.username => copyWith(username: value as String? ?? ''),
        ReadinessField.country => copyWith(country: value as String? ?? ''),
      };

  @override
  dynamic getValueByKey(ReadinessField key) => switch (key) {
    ReadinessField.name => name,
    ReadinessField.username => username,
    ReadinessField.country => country,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadinessFormEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          country == other.country;

  @override
  int get hashCode => Object.hash(id, name, username, country);
}

class _ReadinessValidator
    extends BlocxFormValidator<ReadinessFormEntity, ReadinessField> {
  @override
  List<ReadinessField> formKeys() => ReadinessField.values;

  @override
  List<BlocxFieldValidator<ReadinessFormEntity, ReadinessField, dynamic>>
  getValidatorsByKey(ReadinessFormEntity formData, ReadinessField key) {
    return switch (key) {
      ReadinessField.name => [BlocxStringRequiredValidator()],
      ReadinessField.username => [BlocxStringRequiredValidator()],
      ReadinessField.country => const [],
    };
  }
}

class _ControlledBoolUseCase extends BlocxBaseUseCase<String, bool> {
  Completer<void>? completer;
  bool resultValue = true;

  @override
  Future<BlocxUseCaseResult<bool>> perform(String input) async {
    if (completer != null) {
      await completer!.future;
    }
    return success(resultValue);
  }
}

class _ControlledPrefetchUseCase extends BlocxBaseUseCase<void, List<String>> {
  Completer<void>? completer;
  List<String> items = const ['US', 'CA'];

  @override
  Future<BlocxUseCaseResult<List<String>>> perform(void input) async {
    if (completer != null) {
      await completer!.future;
    }
    return success(items);
  }
}

class _ControlledSubmitUseCase extends BlocxBaseUseCase<void, String> {
  Completer<void>? completer;

  @override
  Future<BlocxUseCaseResult<String>> perform(void input) async {
    if (completer != null) {
      await completer!.future;
    }
    return success('ok');
  }
}

class _ReadinessFormBloc
    extends
        BlocxFormBloc<ReadinessFormEntity, ReadinessFormEntity, ReadinessField>
    with
        BlocxFormValidationMixin<
          ReadinessFormEntity,
          ReadinessFormEntity,
          ReadinessField
        >,
        BlocxUniqueFieldValidatorMixin<
          ReadinessFormEntity,
          ReadinessFormEntity,
          ReadinessField
        >,
        BlocxFormPrefetchMixin<
          ReadinessFormEntity,
          ReadinessFormEntity,
          ReadinessField
        > {
  final _ControlledSubmitUseCase submitUseCase;
  final _ControlledBoolUseCase uniqueUseCase;
  final _ControlledPrefetchUseCase prefetchUseCase;
  final bool enablePrefetch;
  final bool applyDefaultCountryOnPrefetch;

  _ReadinessFormBloc({
    required this.submitUseCase,
    required this.uniqueUseCase,
    required this.prefetchUseCase,
    this.enablePrefetch = false,
    this.applyDefaultCountryOnPrefetch = false,
  }) : super(const ReadinessFormEntity());

  @override
  BlocxFormValidator<ReadinessFormEntity, ReadinessField> get validator =>
      _ReadinessValidator();

  @override
  List<ReadinessField> get formKeysList => ReadinessField.values;

  @override
  FormValidationMode get formValidationMode =>
      FormValidationMode.onUserInteraction;

  @override
  List<ReadinessField> get uniqueFieldKeys => const [ReadinessField.username];

  @override
  FutureOr<ReadinessFormEntity> applyPayloadToFormData(
    ReadinessFormEntity payload,
  ) => payload;

  @override
  Map<ReadinessField, BlocxUseCaseTask<Object?, Object?>>
  get requiredInitialInfoTasks => enablePrefetch
      ? {
          ReadinessField.country: BlocxUseCaseTask<void, List<String>>(
            useCase: prefetchUseCase,
            inputBuilder: () {},
          ),
        }
      : const {};

  @override
  FutureOr<void> onInfoFetched(
    ReadinessField key,
    dynamic data,
    Emitter<BlocxFormState<ReadinessFormEntity, ReadinessField>> emit,
  ) {
    if (applyDefaultCountryOnPrefetch &&
        key == ReadinessField.country &&
        data is List<String> &&
        data.isNotEmpty) {
      formData = formData.copyWith(country: data.first);
    }
  }

  @override
  BlocxUseCaseTask<dynamic, bool>? useCaseIsUniqueValueAvailable(
    ReadinessFormEntity formData,
    ReadinessField key,
    dynamic value,
  ) {
    if (key == ReadinessField.username) {
      return BlocxUseCaseTask<String, bool>(
        useCase: uniqueUseCase,
        inputBuilder: () => value as String,
      );
    }
    return null;
  }

  @override
  Map<ReadinessField, String> get unavailableFieldMessages => const {
    ReadinessField.username: 'Username taken',
  };

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask =>
      BlocxUseCaseTask<void, String>(
        useCase: submitUseCase,
        inputBuilder: () {},
      );
}

void main() {
  group('Form readiness, dirty tracking & reset', () {
    late _ControlledSubmitUseCase submitUseCase;
    late _ControlledBoolUseCase uniqueUseCase;
    late _ControlledPrefetchUseCase prefetchUseCase;

    setUp(() {
      submitUseCase = _ControlledSubmitUseCase();
      uniqueUseCase = _ControlledBoolUseCase();
      prefetchUseCase = _ControlledPrefetchUseCase();
    });

    test(
      'tracks initialData, isDirty, canSubmit across create edits and reverting back to initial',
      () async {
        final bloc = _ReadinessFormBloc(
          submitUseCase: submitUseCase,
          uniqueUseCase: uniqueUseCase,
          prefetchUseCase: prefetchUseCase,
        );

        expect(bloc.state.initialData, equals(const ReadinessFormEntity()));
        expect(bloc.state.isDirty, isFalse);

        // Init with null payload (create mode)
        bloc.add(BlocxFormEventInit<ReadinessFormEntity>(payload: null));
        await pumpEventQueue();

        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.isFormValid, isFalse);
        expect(bloc.state.canSubmit, isFalse);

        // Fill only one required field -> dirty, still invalid
        bloc.add(
          BlocxFormEventUpdateData(key: ReadinessField.name, data: 'Alice'),
        );
        await pumpEventQueue();
        expect(bloc.state.isDirty, isTrue);
        expect(bloc.state.isFormValid, isFalse);
        expect(bloc.state.canSubmit, isFalse);

        // Fill second required field (and unique passes) -> dirty & canSubmit
        bloc.add(
          BlocxFormEventUpdateData(
            key: ReadinessField.username,
            data: 'alice_dev',
          ),
        );
        await pumpEventQueue();
        expect(bloc.state.isDirty, isTrue);
        expect(bloc.state.isFormValid, isTrue);
        expect(bloc.state.hasPendingUniqueChecks, isFalse);
        expect(bloc.state.canSubmit, isTrue);

        // Reverting back to initial values resets isDirty to false
        bloc.add(BlocxFormEventUpdateData(key: ReadinessField.name, data: ''));
        bloc.add(
          BlocxFormEventUpdateData(key: ReadinessField.username, data: ''),
        );
        await pumpEventQueue();
        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.canSubmit, isFalse);

        await bloc.close();
      },
    );

    test(
      'blocks canSubmit during pending unique check and on unavailable username error',
      () async {
        final uniqueCompleter = Completer<void>();
        uniqueUseCase.completer = uniqueCompleter;
        uniqueUseCase.resultValue = false;

        final bloc = _ReadinessFormBloc(
          submitUseCase: submitUseCase,
          uniqueUseCase: uniqueUseCase,
          prefetchUseCase: prefetchUseCase,
        );

        bloc.add(BlocxFormEventInit<ReadinessFormEntity>(payload: null));
        bloc.add(
          BlocxFormEventUpdateData(key: ReadinessField.name, data: 'Bob'),
        );
        bloc.add(
          BlocxFormEventUpdateData(
            key: ReadinessField.username,
            data: 'taken_user',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.hasPendingUniqueChecks, isTrue);
        expect(bloc.state.canSubmit, isFalse);

        // Complete unique check -> returns false -> error recorded -> canSubmit stays false
        uniqueCompleter.complete();
        await pumpEventQueue();

        expect(bloc.state.hasPendingUniqueChecks, isFalse);
        expect(
          bloc.state.errorByKey(ReadinessField.username),
          equals('Username taken'),
        );
        expect(bloc.state.isFormValid, isTrue);
        expect(bloc.state.canSubmit, isFalse);

        // Change to available username -> canSubmit becomes true
        uniqueUseCase.completer = null;
        uniqueUseCase.resultValue = true;
        bloc.add(
          BlocxFormEventUpdateData(
            key: ReadinessField.username,
            data: 'free_user',
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.errors, isEmpty);
        expect(bloc.state.canSubmit, isTrue);

        await bloc.close();
      },
    );

    test(
      'edit mode hydration & prefetch baseline block submit while prefetching and preserve clean state',
      () async {
        final prefetchCompleter = Completer<void>();
        prefetchUseCase.completer = prefetchCompleter;

        final bloc = _ReadinessFormBloc(
          submitUseCase: submitUseCase,
          uniqueUseCase: uniqueUseCase,
          prefetchUseCase: prefetchUseCase,
          enablePrefetch: true,
          applyDefaultCountryOnPrefetch: true,
        );

        const existing = ReadinessFormEntity(
          id: 'u1',
          name: 'Charlie',
          username: 'charlie',
        );
        bloc.add(BlocxFormEventInit<ReadinessFormEntity>(payload: existing));
        await pumpEventQueue();

        expect(bloc.state.isPrefetching, isTrue);
        expect(bloc.state.canSubmit, isFalse);

        // Complete prefetch; onInfoFetched applies country='US' on untouched form
        prefetchCompleter.complete();
        await pumpEventQueue();

        expect(bloc.state.isPrefetching, isFalse);
        expect(bloc.state.formData.country, equals('US'));
        expect(bloc.state.initialData?.country, equals('US'));
        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.canSubmit, isTrue);

        await bloc.close();
      },
    );

    test(
      'isSubmittingForm is true while submit is in-flight and canSubmit is false',
      () async {
        final submitCompleter = Completer<void>();
        submitUseCase.completer = submitCompleter;

        final bloc = _ReadinessFormBloc(
          submitUseCase: submitUseCase,
          uniqueUseCase: uniqueUseCase,
          prefetchUseCase: prefetchUseCase,
        );

        const validPayload = ReadinessFormEntity(
          id: 'u2',
          name: 'Dana',
          username: 'dana_ok',
        );
        bloc.add(
          BlocxFormEventInit<ReadinessFormEntity>(payload: validPayload),
        );
        await pumpEventQueue();
        expect(bloc.state.canSubmit, isTrue);

        final states = <BlocxFormState<ReadinessFormEntity, ReadinessField>>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(BlocxFormEventSubmit());
        await pumpEventQueue();

        expect(bloc.state.isSubmittingForm, isTrue);
        expect(bloc.state.canSubmit, isFalse);

        submitCompleter.complete();
        await pumpEventQueue();

        expect(bloc.state.isSubmittingForm, isFalse);
        expect(states.whereType<BlocxFormStateSubmittingForm>(), hasLength(1));
        expect(states.whereType<BlocxFormStateFormSubmitted>(), hasLength(1));

        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'BlocxFormEventReset restores initialData, clears errors/timers/in-flight unique checks and emits controller sync',
      () async {
        final uniqueCompleter = Completer<void>();
        uniqueUseCase.completer = uniqueCompleter;
        uniqueUseCase.resultValue = false;

        final bloc = _ReadinessFormBloc(
          submitUseCase: submitUseCase,
          uniqueUseCase: uniqueUseCase,
          prefetchUseCase: prefetchUseCase,
        );

        const initial = ReadinessFormEntity(
          id: 'u3',
          name: 'Eva',
          username: 'eva_orig',
        );
        bloc.add(BlocxFormEventInit<ReadinessFormEntity>(payload: initial));
        await pumpEventQueue();

        final states = <BlocxFormState<ReadinessFormEntity, ReadinessField>>[];
        final sub = bloc.stream.listen(states.add);

        // Dirty edits + timed error + in-flight unique check
        bloc.add(BlocxFormEventUpdateData(key: ReadinessField.name, data: ''));
        bloc.add(
          BlocxFormEventUpdateData(
            key: ReadinessField.username,
            data: 'eva_new',
          ),
        );
        bloc.add(
          BlocxFormEventSetTimedErrorToField<ReadinessField>(
            key: ReadinessField.country,
            message: 'Temporary warning',
            duration: const Duration(milliseconds: 50),
          ),
        );
        await pumpEventQueue();

        expect(bloc.state.isDirty, isTrue);
        expect(bloc.state.errors, isNotEmpty);
        expect(bloc.state.hasPendingUniqueChecks, isTrue);

        // Reset form
        states.clear();
        bloc.add(const BlocxFormEventReset());
        await pumpEventQueue();

        // Now resolve the stale unique check after reset -> must be ignored!
        uniqueCompleter.complete();
        await pumpEventQueue();

        expect(bloc.formData, equals(initial));
        expect(bloc.state.formData, equals(initial));
        expect(bloc.state.initialData, equals(initial));
        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.errors, isEmpty);
        expect(bloc.state.hasPendingUniqueChecks, isFalse);
        expect(bloc.state.canSubmit, isTrue);
        expect(
          states.whereType<BlocxFormStateApplyInitialDataToForm>(),
          hasLength(1),
        );

        await sub.cancel();
        await bloc.close();
      },
    );
  });
}
