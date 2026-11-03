// The rating prompt that follows a user-initiated disconnect.

import 'dart:async';

import 'package:in_app_review/in_app_review.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the store review flow for this app.
abstract interface class OneVpnReviewLauncher {
  /// Opens the review flow. Resolves when the platform call returns.
  Future<void> openReview();
}

/// The native store review flow through the in_app_review plugin, with the
/// store listing as its fallback.
///
/// [openReview] requests the in-app review sheet. The store decides whether
/// the sheet shows and never reports it. The sheet covers the app, so the
/// app leaving the resumed state during the request counts as a shown sheet.
/// With no such change, or a failed request, [openReview] opens the store
/// listing. A failing store listing resolves quietly.
class OneVpnPlayReviewLauncher implements OneVpnReviewLauncher {
  OneVpnPlayReviewLauncher({InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<void> openReview() async {
    var covered = false;
    final listener = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.resumed) covered = true;
      },
    );
    try {
      await _review.requestReview();
    } catch (_) {
      // A failed request falls through to the store listing.
    } finally {
      listener.dispose();
    }
    if (covered) return;
    try {
      await _review.openStoreListing();
    } catch (_) {
      // No store on the device. The answer stays recorded.
    }
  }
}

/// The rating prompt after a user-initiated disconnect.
///
/// The prompt asks whether the user is enjoying the app. It shows after every
/// user-initiated disconnect until the user answers. An answer ends the
/// prompt for good. A dismissal records its time, and the next
/// user-initiated disconnect shows the prompt again.
///
/// [answer] records the answer and its time in the fork preferences and
/// sends nothing anywhere. A yes then starts the review flow through
/// [OneVpnReviewLauncher]. [answer] resolves once the answer is stored, and
/// the review flow runs on. A no only closes the dialog.
///
/// The connect screen calls [afterUserDisconnect] only for a tap that
/// disconnects a connected tunnel. A failed start, a lost tunnel, a stop
/// from the notification or the tile, and a failed disconnect show nothing.
class OneVpnRatingPrompt {
  OneVpnRatingPrompt({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
    OneVpnReviewLauncher? launcher,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _now = now ?? DateTime.now,
       _launcher = launcher ?? OneVpnPlayReviewLauncher();

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;
  final OneVpnReviewLauncher _launcher;

  /// The fork key for the answer, true when the user is enjoying the app.
  /// Its presence ends the prompt.
  static const answerKey = 'onevpn.ratingAnswer';

  /// The fork key for the time of the answer, in milliseconds since the
  /// epoch in UTC.
  static const answeredAtKey = 'onevpn.ratingAnswerAt';

  /// The fork key for the time of the last dismissal, in milliseconds since
  /// the epoch in UTC. It never suppresses the prompt.
  static const dismissedAtKey = 'onevpn.ratingDismissedAt';

  /// Whether the prompt shows on the next user-initiated disconnect. An
  /// unreadable answer reads as no answer.
  Future<bool> isDue() async {
    try {
      return await _preferences.getBool(answerKey) == null;
    } catch (_) {
      return true;
    }
  }

  /// Records [enjoying] and the time of the answer. A yes then starts the
  /// review flow. A refused write still starts the review flow.
  ///
  /// Resolves once the answer is stored. The review flow runs on after that.
  /// A failed review flow leaves the answer stored.
  Future<void> answer(bool enjoying) async {
    try {
      await _preferences.setBool(answerKey, enjoying);
      await _preferences.setInt(answeredAtKey, _stamp());
    } catch (_) {
      // A refused write costs one repeat prompt.
    }
    // Must not hold the caller: a review sheet the user leaves never returns.
    if (enjoying) unawaited(_openReview());
  }

  /// Opens the review flow. A failure resolves quietly.
  Future<void> _openReview() async {
    try {
      await _launcher.openReview();
    } catch (_) {
      // The answer stays recorded.
    }
  }

  /// Records the time of a dismissal.
  Future<void> dismiss() async {
    try {
      await _preferences.setInt(dismissedAtKey, _stamp());
    } catch (_) {
      // The stamp is a record only. The prompt behaves the same without it.
    }
  }

  /// Shows the rating dialog over [context] when the prompt is due. An
  /// answer goes to [answer]. A barrier tap or back goes to [dismiss].
  /// Resolves once the answer or the dismissal is stored.
  Future<void> afterUserDisconnect(BuildContext context) async {
    if (!await isDue() || !context.mounted) return;
    final enjoying = await showDialog<bool>(
      context: context,
      builder: (_) => const OneVpnRatingDialog(),
    );
    if (enjoying == null) {
      await dismiss();
      return;
    }
    await answer(enjoying);
  }

  int _stamp() => _now().toUtc().millisecondsSinceEpoch;
}

/// The rating dialog: the centered question over Yes and No in one row. Yes
/// pops true and No pops false. A barrier tap, Esc, and back pop null.
class OneVpnRatingDialog extends StatelessWidget {
  const OneVpnRatingDialog({super.key});

  /// The widest the dialog grows.
  static const double maxWidth = 420;

  /// The space above the question.
  static const double topPadding = 32;

  /// The gap between the question and the buttons.
  static const double questionGap = 26;

  /// The gap between the Yes and No buttons.
  static const double buttonGap = 12;

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final question = l.onevpnEnjoyingQuestion;
    return Dialog(
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.all(OneVpnCard.margin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneVpnCard.headlineRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        // The dialog names its route for screen readers.
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: question,
          child: SingleChildScrollView(
            padding: OneVpnCard.headlinePadding.copyWith(top: topPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question,
                  textAlign: TextAlign.center,
                  style: AppTypography.panelTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: questionGap),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: OneVpnButton.style,
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.onevpnYes),
                      ),
                    ),
                    const SizedBox(width: buttonGap),
                    Expanded(
                      child: OutlinedButton(
                        style: OneVpnButton.style,
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.onevpnNo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
