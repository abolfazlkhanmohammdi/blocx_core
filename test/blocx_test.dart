import 'collection/collection_bloc_test.dart' as collection_bloc_test;
import 'core/use_case_test.dart' as use_case_test;
import 'form/form_bloc_test.dart' as form_bloc_test;
import 'screen_manager/screen_manager_cubit_test.dart' as screen_manager_cubit_test;

void main() {
  use_case_test.main();
  form_bloc_test.main();
  collection_bloc_test.main();
  screen_manager_cubit_test.main();
}
