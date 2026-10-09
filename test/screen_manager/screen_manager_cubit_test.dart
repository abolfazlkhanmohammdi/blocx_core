import 'package:blocx_core/blocx_core.dart';
import 'package:test/test.dart';

void main() {
  group('ScreenManagerCubit', () {
    late ScreenManagerCubit cubit;

    setUp(() {
      cubit = ScreenManagerCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('pop emits ScreenManagerCubitStatePop', () async {
      expectLater(
        cubit.stream,
        emits(isA<ScreenManagerCubitStatePop>()),
      );

      cubit.pop();
    });

    test('displaySnackbar emits snackbar state then restores previous state',
        () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ScreenManagerCubitStateDisplaySnackbar>(),
          isA<ScreenManagerCubitStateInitial>(),
        ]),
      );

      cubit.displaySnackbar('Operation successful', BlocXSnackbarType.info);
    });

    test('displayErrorWidget emits display error page state', () async {
      final error = ReadableError(message: 'Something broke');

      expectLater(
        cubit.stream,
        emits(isA<ScreenManagerCubitStateDisplayErrorPage>()),
      );

      cubit.displayErrorWidget(error);
    });

    test(
        'clearError emits ScreenManagerCubitStateInitial with shouldRebuild == true',
        () async {
      final error = ReadableError(message: 'Something broke');
      cubit.displayErrorWidget(error);

      expectLater(
        cubit.stream,
        emits(predicate<ScreenManagerCubitState>((s) =>
            s is ScreenManagerCubitStateInitial && s.shouldRebuild == true)),
      );

      cubit.clearError();
      expect(cubit.state, isA<ScreenManagerCubitStateInitial>());
      expect(cubit.state.shouldRebuild, isTrue);
    });

    test(
        'snackbar emitted after clearError restores initial state, not error page',
        () async {
      final error = ReadableError(message: 'Fatal page crash');
      cubit.displayErrorWidget(error);
      cubit.clearError();

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ScreenManagerCubitStateDisplaySnackbar>(),
          predicate<ScreenManagerCubitState>((s) =>
              s is ScreenManagerCubitStateInitial && s.shouldRebuild == true),
        ]),
      );

      cubit.displaySnackbar('Info notification', BlocXSnackbarType.info);
      expect(cubit.state, isA<ScreenManagerCubitStateInitial>());
    });
  });
}
