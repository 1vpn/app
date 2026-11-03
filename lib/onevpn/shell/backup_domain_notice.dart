import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// Opens [uri] in the browser. The notice's default is [openExternalLink].
typedef OneVpnOpenLink = Future<void> Function(BuildContext context, Uri uri);

/// The connect screen's backup-domain line, shown at the foot of the screen
/// while [backupDomain] names a backup domain.
///
/// It shows whether or not the tunnel is up, because the fact comes from the
/// account walk. It is one line of muted, centered text that names the bare
/// host. The locale's string places the host. The line is a text button
/// sized to its text, with the hover and press tint of the app's other text
/// links. A tap opens the backup domain's home page through [open]. With no
/// backup domain it renders nothing and takes no space.
class OneVpnBackupDomainNotice extends StatelessWidget {
  const OneVpnBackupDomainNotice({super.key, this.backupDomain, this.open});

  /// Marks the notice text.
  static const textKey = ValueKey<String>('onevpn-backup-domain-notice');

  /// The backup domain in use, or null on the primary. Defaults to
  /// [OneVpnApiTransport.backupDomainInUse].
  final ValueListenable<String?>? backupDomain;

  /// Opens the link. Defaults to [openExternalLink].
  final OneVpnOpenLink? open;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable:
        backupDomain ?? OneVpnApiTransport.instance.backupDomainInUse,
    builder: (context, backup, _) {
      if (backup == null) return const SizedBox.shrink();
      final palette = ColorManager.palette(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          OneVpnCard.margin,
          OneVpnCard.stackGap,
          OneVpnCard.margin,
          0,
        ),
        child: Center(
          child: Semantics(
            link: true,
            child: TextButton(
              onPressed: () => (open ?? openExternalLink)(
                context,
                Uri(scheme: 'https', host: backup, path: '/'),
              ),
              style: TextButton.styleFrom(
                foregroundColor: palette.mutedForeground,
                textStyle: AppTypography.settingsValueLabel,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
              child: Text(
                OneVpnLocalizations.of(context)!
                    .onevpnBackupDomainBlocked(backup),
                key: textKey,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    },
  );
}
