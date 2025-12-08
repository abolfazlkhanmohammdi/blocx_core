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
  String get thisFieldIsRequired;

  String errorCodeMessage(BlocXErrorCode errorCode);

  String maxLengthError(dynamic maxLength);
  String minLengthError(dynamic maxLength);
  String lengthRangeError(dynamic minLength, dynamic maxLength);
  String exactLengthFieldError(int length);
  String minValueError(num minValue);
  String maxValueError(num maxValue);
  String numberRangeError(num minValue, num maxValue);
  String minDateError(DateTime minDate);

  String maxDateError(DateTime maxDate);

  String dateRangeError(DateTime minDate, DateTime maxDate);
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

  @override
  String get thisFieldIsRequired => "This field is required";

  @override
  String maxLengthError(maxLength) => "This field cannot exceed $maxLength characters";

  @override
  String minLengthError(minLength) => "This field must be at least $minLength characters long";

  @override
  String lengthRangeError(minLength, maxLength) =>
      "This field must be between $minLength and $maxLength characters long";

  @override
  String exactLengthFieldError(int length) => "This field must be exactly $length characters long";

  @override
  String maxValueError(num maxValue) => "This value must be less than or equal to $maxValue";

  @override
  String minValueError(num minValue) => "This value must be greater than or equal to $minValue";

  @override
  String numberRangeError(num minValue, num maxValue) => "This value must be between $minValue and $maxValue";

  @override
  String dateRangeError(DateTime minDate, DateTime maxDate) {
    return "Date must be between ${_formatDate(minDate)} and ${_formatDate(maxDate)}";
  }

  @override
  String maxDateError(DateTime maxDate) {
    return "Date must be before ${_formatDate(maxDate)}";
  }

  @override
  String minDateError(DateTime minDate) {
    return "Date must be after ${_formatDate(minDate)}";
  }

  /// Helper to format dates in a user-friendly way.
  String _formatDate(DateTime date) {
    // Customize format if needed, here using yyyy-MM-dd
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
