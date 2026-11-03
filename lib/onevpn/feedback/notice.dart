// The transient message surface for fork screens.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// Shows short messages as floating snack bars styled as cards.
///
/// A notice takes the tone of its kind. It draws a 2.5dp outline in the tone
/// color over a faint tint of it. It has card corners and a leading icon in the
/// tone. Info takes the primary tone, and a failure takes the destructive tone.
/// The app theme sets its placement. A screen with a split body wraps its
/// scaffold in `OneVpnSnackBarAnchor`, which moves the notice onto the end
/// pane. A new notice replaces the one on screen.
///
/// A lasting failure stays until the user closes it, a new notice replaces
/// it, or its handle closes it. A close button sits at its end. A failure
/// with a link always lasts. The link is one underlined span inside the
/// message. A tap on it closes the notice.
abstract final class OneVpnNotice {
  /// Shows [message] as information, in the primary tone.
  static void info(BuildContext context, String message) =>
      OneVpnNoticeTarget.of(context).info(message);

  /// Shows [message] as a failure, in the destructive tone. A [persist]
  /// failure lasts.
  static OneVpnNoticeHandle error(
    BuildContext context,
    String message, {
    bool persist = false,
  }) => OneVpnNoticeTarget.of(context).error(message, persist: persist);

  /// Shows [message] as a lasting failure with [link] in its link slot.
  ///
  /// A message that places the link other than exactly once shows as plain
  /// text, with the link label in the slot.
  static OneVpnNoticeHandle errorWithLink(
    BuildContext context,
    OneVpnLinkedMessage message,
    OneVpnNoticeLink link,
  ) => OneVpnNoticeTarget.of(context).errorWithLink(message, link);
}

/// Closes the notice it came from.
///
/// A notice already closed or replaced stays as it is. A notice still queued
/// behind another closes when it comes on screen. [close] is safe in a build
/// or a dispose: the hide runs in a microtask.
class OneVpnNoticeHandle {
  OneVpnNoticeHandle._(this._messenger);

  /// A handle for a notice that never showed.
  OneVpnNoticeHandle._none() : _messenger = null {
    _gone = true;
  }

  final ScaffoldMessengerState? _messenger;

  /// Whether the notice left the messenger.
  bool _gone = false;

  /// Whether the notice came on screen. The messenger builds only the
  /// notice on screen, so its body marks this.
  bool _shown = false;

  /// Whether [close] ran.
  bool _closing = false;

  /// Closes the notice.
  void close() {
    if (_gone || _closing) return;
    _closing = true;
    if (_shown) _hide();
  }

  void _watch(
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> shown,
  ) => unawaited(shown.closed.then((_) => _gone = true));

  void _markShown() {
    if (_shown) return;
    _shown = true;
    if (_closing) _hide();
  }

  /// Hides the notice on screen, which is this one while it is shown and not
  /// gone. Deferred: a hide can rebuild the messenger, which a build or a
  /// dispose must not.
  void _hide() => scheduleMicrotask(() {
    final messenger = _messenger;
    if (_gone || messenger == null || !messenger.mounted) return;
    messenger.hideCurrentSnackBar();
  });
}

/// A message with one link slot. It answers the message with [link] in
/// that slot.
typedef OneVpnLinkedMessage = String Function(String link);

/// The link a failure notice places in its message.
class OneVpnNoticeLink {
  const OneVpnNoticeLink({required this.label, required this.onTap});

  /// The link text.
  final String label;

  /// Runs on a tap, after the notice closes.
  final VoidCallback onTap;
}

/// The text before and after the link slot of [message], or null when the
/// message places the link other than exactly once.
(String, String)? oneVpnLinkParts(OneVpnLinkedMessage message) {
  final parts = message(_linkSlot).split(_linkSlot);
  return parts.length == 2 ? (parts[0], parts[1]) : null;
}

/// Stands in for the link while a message is split. It is a private-use
/// code point, so no translation holds it.
const _linkSlot = '\uE000';

/// The scaffold messenger and palette a notice shows with, captured from a
/// context. A notice shows through it after that context unmounts, on the
/// app's messenger.
class OneVpnNoticeTarget {
  OneVpnNoticeTarget.of(BuildContext context)
    : _messenger = ScaffoldMessenger.of(context),
      _palette = ColorManager.palette(context);

  final ScaffoldMessengerState _messenger;
  final AppPalette _palette;

  /// Shows [message] as information, in the primary tone.
  void info(String message) => _show(message, error: false);

  /// Shows [message] as a failure, in the destructive tone. A [persist]
  /// failure lasts.
  OneVpnNoticeHandle error(String message, {bool persist = false}) =>
      _show(message, error: true, persist: persist);

  /// Shows [message] as a lasting failure with [link] in its link slot. A
  /// message that places the link other than exactly once shows as plain
  /// text.
  OneVpnNoticeHandle errorWithLink(
    OneVpnLinkedMessage message,
    OneVpnNoticeLink link,
  ) {
    final parts = oneVpnLinkParts(message);
    final messenger = _messenger;
    return _show(
      message(link.label),
      error: true,
      persist: true,
      link: parts == null
          ? null
          : (
              before: parts.$1,
              label: link.label,
              after: parts.$2,
              onTap: () {
                messenger.hideCurrentSnackBar(
                  reason: SnackBarClosedReason.action,
                );
                link.onTap();
              },
            ),
    );
  }

  OneVpnNoticeHandle _show(
    String message, {
    required bool error,
    bool persist = false,
    _OneVpnInlineLink? link,
  }) {
    if (!_messenger.mounted) return OneVpnNoticeHandle._none();
    final palette = _palette;
    final tone = error ? palette.destructive : palette.primary;
    final handle = OneVpnNoticeHandle._(_messenger);
    _messenger.hideCurrentSnackBar();
    handle._watch(
      _messenger.showSnackBar(
        SnackBar(
          backgroundColor: Color.alphaBlend(
            tone.withValues(alpha: 0.08),
            palette.card,
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OneVpnCard.radius),
            side: BorderSide(color: tone, width: 2.5),
          ),
          persist: persist,
          showCloseIcon: persist,
          closeIconColor: palette.mutedForeground,
          content: _OneVpnNoticeBody(
            icon: error ? LucideIcons.circleAlert : LucideIcons.info,
            tone: tone,
            textColor: palette.foreground,
            linkColor: palette.primary,
            message: message,
            link: link,
            handle: handle,
          ),
        ),
      ),
    );
    return handle;
  }
}

/// A link inside a notice message: the text before it, its label, the text
/// after it, and its tap action.
typedef _OneVpnInlineLink = ({
  String before,
  String label,
  String after,
  VoidCallback onTap,
});

/// The icon and the message of a notice. It owns the tap recognizer of the
/// link, and it marks its notice shown on screen.
class _OneVpnNoticeBody extends StatefulWidget {
  const _OneVpnNoticeBody({
    required this.icon,
    required this.tone,
    required this.textColor,
    required this.linkColor,
    required this.message,
    required this.handle,
    this.link,
  });

  final IconData icon;
  final Color tone;
  final Color textColor;
  final Color linkColor;

  /// The whole message as plain text. It shows when [link] is null.
  final String message;

  /// The handle of this notice.
  final OneVpnNoticeHandle handle;

  /// The link inside the message, or null for a message with no link.
  final _OneVpnInlineLink? link;

  @override
  State<_OneVpnNoticeBody> createState() => _OneVpnNoticeBodyState();
}

class _OneVpnNoticeBodyState extends State<_OneVpnNoticeBody> {
  /// Created at the first build with a link.
  TapGestureRecognizer? _tap;

  @override
  void initState() {
    super.initState();
    widget.handle._markShown();
  }

  @override
  void dispose() {
    _tap?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.settingsSelect.copyWith(
      fontSize: 16,
      color: widget.textColor,
    );
    final link = widget.link;
    if (link != null) {
      _tap ??= TapGestureRecognizer()..onTap = () => widget.link?.onTap();
    }
    return Row(
      children: [
        Icon(widget.icon, size: 30, color: widget.tone),
        const SizedBox(width: 16),
        Expanded(
          child: link == null
              ? Text(widget.message, style: style)
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: link.before),
                      // The underline marks the link: color alone does not.
                      TextSpan(
                        text: link.label,
                        style: TextStyle(
                          color: widget.linkColor,
                          decoration: TextDecoration.underline,
                          decorationColor: widget.linkColor,
                        ),
                        recognizer: _tap,
                      ),
                      TextSpan(text: link.after),
                    ],
                  ),
                  style: style,
                ),
        ),
      ],
    );
  }
}
