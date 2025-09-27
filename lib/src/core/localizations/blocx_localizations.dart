import 'package:blocx_core/blocx_core.dart';

abstract class BlocXLocalizations {
  static BlocXLocalizations? _loc;
  static set localizations(value) => _loc = value;
  static BlocXLocalizations get localizations => _loc ?? _DefaultLocalizations();

  String get tryAgain;
  String get copyDetails;
  String get report;
  String get close;
  String get details;
  String get errorDetailsCopied;
  String get somethingWentWrong;
  String get loadingText;
  String get emptyListText;

  String errorCodeMessage(BlocXErrorCode errorCode);
}

class _DefaultLocalizations extends BlocXLocalizations {
  @override
  String errorCodeMessage(BlocXErrorCode errorCode) {
    return switch (errorCode) {
      BlocXErrorCode.checkingUniqueValue => "Checking unique value, please wait...",
      BlocXErrorCode.unknown => "Unknown error",
      BlocXErrorCode.valueNotAvailable => "Value not available",
      BlocXErrorCode.errorGettingInitialFormData => "Error getting initial form data",
      BlocXErrorCode.fieldCannotBeEmpty => "This field cannot be empty",
    };
  }

  @override
  String get tryAgain => "Try again";

  @override
  String get copyDetails => "Copy Details";

  @override
  String get close => "Close";

  @override
  String get report => "Report";

  @override
  String get details => "Details";
  @override
  String get errorDetailsCopied => "Error details were copied!";
  @override
  String get somethingWentWrong => 'Something went wrong';
  @override
  String get loadingText => "Loading data, please wait";
  @override
  String get emptyListText => "No data, Empty list...";
}
