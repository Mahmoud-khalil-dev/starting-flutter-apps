import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The text for [failure], or null when nothing is shown (a cancel).
/// Validation and a conflict show the backend's own text when it sent
/// one; the backend localizes it from Accept-Language.
String? failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NoConnection() => l10n.errorNoConnection,
      TimeoutFailure(outcomeKnown: true) => l10n.errorTimeout,
      TimeoutFailure(outcomeKnown: false) => l10n.errorOutcomeUnknown,
      ServerFailure() => l10n.errorServer,
      Unauthorized() => l10n.errorSessionEnded,
      Forbidden() => l10n.errorForbidden,
      NotFound() => l10n.errorNotFound,
      ValidationFailure(:final messages) =>
        messages.isEmpty ? l10n.errorUnknown : messages.join('\n'),
      Conflict(:final message) => message ?? l10n.errorConflict,
      TooManyRequests(retryAfter: final wait?) => l10n.errorTooManyRequestsIn(
        AppFormats(l10n.localeName).formatDuration(wait),
      ),
      TooManyRequests() => l10n.errorTooManyRequests,
      CodeExpired() => l10n.errorCodeExpired,
      Cancelled() => null,
      UnknownFailure() => l10n.errorUnknown,
    };
