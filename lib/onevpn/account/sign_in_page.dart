// The dual-mode auth surface: sign-up and log-in behind one screen. It
// calls the account transport and adopts the session the server hands back.
//
// The error mapping:
//
//   1001 reveals the two-factor field, log-in only.
//   An "email already used" sign-up offers "Log in instead".
//   A 403 is a rate limit.
//   Wrong password and unknown email share one message. The server does
//   not distinguish them.
//
// Two-factor enrollment is web-only. The app has no enrol flow.
//
// Keyboard Next moves to the next field. Done on the last field submits.
//
// The form is one column capped at [OneVpnLayout.formCap] in both layout
// modes. It never splits. The column starts at the top. It scrolls. A
// keyboard inset never clips the focused field. While the submitting field
// has focus, the submit button also scrolls into view above the keyboard.

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/field.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// Which mode the screen opens in.
enum OneVpnSignInMode { logIn, signUp }

/// The route argument the paywall funnel and the menu pass through
/// GoRouterState.extra. An absent extra opens log-in with no prefill.
class OneVpnSignInArgs {
  const OneVpnSignInArgs({
    required this.mode,
    this.email = '',
    this.lockEmail = false,
    this.edge = OneVpnStackedEdge.top,
  });

  final OneVpnSignInMode mode;
  final String email;

  /// The edge the screen comes from when stacked: the edge of its entry
  /// point.
  final OneVpnStackedEdge edge;

  /// Whether [email] may be edited. The buy-first funnel locks it: an
  /// address changed between paying and signing up breaks the link and
  /// strands the purchase.
  final bool lockEmail;
}

/// Called on a successful sign-up/log-in with the server payload. Defaults
/// to adopting the session and popping with the [OneVpnSignInMode] it
/// completed in.
///
/// Runs only while the page is mounted, so [BuildContext] is live on entry.
/// A success that returns after the page is dismissed skips a custom
/// handler. The default handler then adopts the session only while no
/// later submit from any sign-in page has started, and skips the pop.
typedef OneVpnAuthenticated = Future<void> Function(
  BuildContext context,
  OneVpnUserData data,
);

class OneVpnSignInPage extends StatefulWidget {
  const OneVpnSignInPage({
    super.key,
    this.initialMode = OneVpnSignInMode.logIn,
    this.initialEmail = '',
    this.lockEmail = false,
    this.api,
    this.onAuthenticated,
  });

  final OneVpnSignInMode initialMode;
  final String initialEmail;

  /// Whether [initialEmail] is fixed. The purchase funnel sets it. The
  /// account then carries the address the purchase used. The lock survives
  /// a mode switch.
  final bool lockEmail;

  /// The account transport. Defaults to the real one. Tests script it.
  final OneVpnAccountApi? api;

  /// The success handler. Null selects the default: adopt the session,
  /// then pop. See [OneVpnAuthenticated] for when each part runs.
  final OneVpnAuthenticated? onAuthenticated;

  @override
  State<OneVpnSignInPage> createState() => _OneVpnSignInPageState();
}

class _OneVpnSignInPageState extends State<OneVpnSignInPage> {
  late final OneVpnAccountApi _api;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();
  final TextEditingController _twoFactor = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _twoFactorFocus = FocusNode();

  /// Marks the submit button, which [_revealSubmit] scrolls into view.
  final GlobalKey _submitKey = GlobalKey();
  bool _revealPending = false;

  late OneVpnSignInMode _mode;
  bool _showTwoFactor = false;
  bool _showLogInInstead = false;
  bool _submitting = false;
  String? _error;

  /// The newest submit across every sign-in page. Each submit takes the
  /// next value. A dismissed page adopts only while its value is newest.
  static int _submits = 0;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? OneVpnAccountApi();
    _mode = widget.initialMode;
    _email = TextEditingController(text: widget.initialEmail);
    _passwordFocus.addListener(_onFocusChanged);
    _twoFactorFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _twoFactor.dispose();
    _passwordFocus.dispose();
    _twoFactorFocus.dispose();
    super.dispose();
  }

  bool get _isLogIn => _mode == OneVpnSignInMode.logIn;

  /// The field whose Done key submits: the two-factor field once shown,
  /// the password field before.
  FocusNode get _submitFocus =>
      _showTwoFactor ? _twoFactorFocus : _passwordFocus;

  void _onFocusChanged() {
    if (_submitFocus.hasFocus) _revealSubmit();
  }

  /// Scrolls the submit button into view at the end of the visible area,
  /// after the next frame lays out.
  ///
  /// Runs when the submitting field gains focus and on each rebuild while it
  /// holds focus. A keyboard inset change rebuilds the page. When the field
  /// and the button do not both fit, the button stays in view.
  void _revealSubmit() {
    if (_revealPending) return;
    _revealPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealPending = false;
      final target = _submitKey.currentContext;
      if (!mounted || target == null || !_submitFocus.hasFocus) return;
      Scrollable.ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _switchTo(OneVpnSignInMode mode, {String? email}) {
    setState(() {
      _mode = mode;
      if (email != null && !widget.lockEmail) _email.text = email;
      _password.clear();
      _twoFactor.clear();
      _showTwoFactor = false;
      _showLogInInstead = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final l = OneVpnLocalizations.of(context)!;
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l.onevpnAuthFieldsRequired);
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = l.onevpnAuthInvalidEmail);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _showLogInInstead = false;
    });

    final ticket = ++_submits;
    // Read once, before the request. The page may be dismissed while it
    // runs. The dismissed and mounted paths use this one handler.
    final custom = widget.onAuthenticated;
    final result = _isLogIn
        ? await _api.logIn(
            email: email,
            password: password,
            twoFactorToken: _showTwoFactor ? _twoFactor.text.trim() : null,
          )
        : await _api.signUp(email: email, password: password);

    if (!mounted) {
      // A dismissed page still adopts a success under the default handler.
      // A later submit supersedes it. The session the user picked after
      // the dismiss stands. An error shows nothing.
      if (custom == null &&
          ticket == _submits &&
          result is OneVpnApiSuccess<OneVpnUserData>) {
        await OneVpnAccountService.instance.adoptSession(result.data);
      }
      return;
    }
    // A success stays busy through the handler and the pop it starts. A
    // handler that leaves this route in the stack frees the form, on top or
    // covered.
    final succeeded = result is OneVpnApiSuccess<OneVpnUserData>;
    if (!succeeded) setState(() => _submitting = false);
    try {
      await _handle(result, email, l, custom);
    } finally {
      if (succeeded && mounted && (ModalRoute.of(context)?.isActive ?? true)) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handle(
    OneVpnApiResult<OneVpnUserData> result,
    String email,
    OneVpnLocalizations l,
    OneVpnAuthenticated? custom,
  ) async {
    switch (result) {
      case OneVpnApiSuccess<OneVpnUserData>(:final data):
        final onAuthenticated = custom ?? _defaultAuthenticated;
        await onAuthenticated(context, data);
      case OneVpnApiRejected<OneVpnUserData> rejected:
        _handleRejected(rejected, email, l);
      case OneVpnApiUnreachable<OneVpnUserData>():
        setState(() => _error = l.onevpnAuthUnreachable);
      case OneVpnApiMalformed<OneVpnUserData>():
        setState(() => _error = l.onevpnAuthGenericError);
    }
  }

  void _handleRejected(
    OneVpnApiRejected<OneVpnUserData> rejected,
    String email,
    OneVpnLocalizations l,
  ) {
    // The backend reuses 1001 for "second factor required" and for "wrong
    // token". A 1001 arriving while the field is already shown means the
    // token just submitted was wrong.
    if (_isLogIn && rejected.isTwoFactorRequired) {
      final firstReveal = !_showTwoFactor;
      setState(() {
        _showTwoFactor = true;
        _error = firstReveal ? null : l.onevpnAuthInvalidTwoFactor;
      });
      // Must run after the frame: the field is built and enabled by then.
      // A request to a disabled field is dropped.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _twoFactorFocus.requestFocus();
      });
      return;
    }
    if (rejected.status == 403) {
      setState(() => _error = l.onevpnAuthRateLimited);
      return;
    }
    if (!_isLogIn && _looksLikeEmailInUse(rejected.message)) {
      setState(() {
        _error = l.onevpnAuthEmailInUse;
        _showLogInInstead = true;
      });
      return;
    }
    setState(() {
      _error = _isLogIn
          ? l.onevpnAuthInvalidCredentials
          : l.onevpnAuthGenericError;
    });
  }

  /// The backend sends "Email is already used". This matches the two
  /// load-bearing words, not the exact sentence.
  static bool _looksLikeEmailInUse(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already') &&
        (lower.contains('used') ||
            lower.contains('registered') ||
            lower.contains('exist'));
  }

  /// The default success handler. Adopts the session, then pops while this
  /// route is current.
  Future<void> _defaultAuthenticated(
    BuildContext context,
    OneVpnUserData data,
  ) async {
    // The adoption completes before the pop. A caller that awaited this
    // route resumes with the session already flipped. The optimistic grant
    // records nothing against a session still being adopted.
    // The route is captured before the adoption. A page dismissed during
    // the adoption stays mounted while the route beneath is current. The
    // page pops only while its own route is current.
    final route = ModalRoute.of(context);
    await OneVpnAccountService.instance.adoptSession(data);
    if (context.mounted && (route?.isCurrent ?? false) && context.canPop()) {
      context.pop(_mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final title = _isLogIn ? l.onevpnLogIn : l.onevpnSignUp;
    // The build depends on the keyboard inset. An inset change rebuilds
    // the page and re-runs the reveal.
    MediaQuery.viewInsetsOf(context);
    if (_submitFocus.hasFocus) _revealSubmit();

    return Scaffold(
      appBar: oneVpnCloseAppBar(context, title),
      body: SafeArea(
        child: OneVpnConstrainedBody(
          maxWidth: OneVpnLayout.formCap,
          scrollable: true,
          child: Padding(
            padding: const EdgeInsets.all(OneVpnCard.margin),
            child: _form(context, l, palette, title),
          ),
        ),
      ),
    );
  }

  /// The fields, the submit button, and the links row. [title] labels the
  /// idle submit button. A busy one reads as loading.
  Widget _form(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
    String title,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          controller: _email,
          label: l.onevpnAuthEmailLabel,
          keyboardType: TextInputType.emailAddress,
          readOnly: widget.lockEmail,
          // The first editable field takes focus when the page opens.
          autofocus: !widget.lockEmail,
          action: TextInputAction.next,
          onSubmitted: _passwordFocus.requestFocus,
        ),
        if (widget.lockEmail)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.onevpnAuthEmailLockedHint,
              style: AppTypography.settingsValueLabel.copyWith(
                color: palette.mutedForeground,
              ),
            ),
          ),
        const SizedBox(height: _gap),
        _field(
          controller: _password,
          label: l.onevpnAuthPasswordLabel,
          obscure: true,
          focusNode: _passwordFocus,
          autofocus: widget.lockEmail,
          action: _showTwoFactor ? TextInputAction.next : TextInputAction.done,
          onSubmitted: _showTwoFactor
              ? _twoFactorFocus.requestFocus
              : _submitFromKeyboard,
        ),
        if (_showTwoFactor) ...[
          const SizedBox(height: _gap),
          _field(
            controller: _twoFactor,
            label: l.onevpnAuthTwoFactorLabel,
            // The field takes six-digit codes and eight-character backup
            // codes, so it uses a text keyboard.
            keyboardType: TextInputType.text,
            autocorrect: false,
            focusNode: _twoFactorFocus,
            action: TextInputAction.done,
            onSubmitted: _submitFromKeyboard,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: _submitGap),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTypography.settingsSelect.copyWith(
              color: palette.destructive,
            ),
          ),
        ],
        const SizedBox(height: _submitGap),
        KeyedSubtree(
          key: _submitKey,
          child: _primaryButton(
            palette: palette,
            label: _submitting ? l.onevpnAuthSubmitting : title,
            onPressed: _submitting ? null : _submit,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // The collision recovery shows one log-in affordance.
            // Its dedicated link replaces the mode switch until it
            // clears.
            Flexible(
              child: _showLogInInstead
                  ? _link(
                      palette,
                      l.onevpnAuthLogInInstead,
                      _submitting
                          ? null
                          : () => _switchTo(
                              OneVpnSignInMode.logIn,
                              email: _email.text.trim(),
                            ),
                    )
                  : _link(
                      palette,
                      _isLogIn
                          ? l.onevpnAuthCreateAccount
                          : l.onevpnAuthHaveAccount,
                      _submitting
                          ? null
                          : () => _switchTo(
                              _isLogIn
                                  ? OneVpnSignInMode.signUp
                                  : OneVpnSignInMode.logIn,
                            ),
                    ),
            ),
            Flexible(
              child: _link(
                palette,
                l.onevpnAuthForgotPassword,
                () => openExternalLink(context, OneVpnLinks.passwordReset),
                end: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The gap between two form rows.
  static const double _gap = 12;

  /// The gap above the submit button. A shown error sits this far below
  /// the last field as well.
  static const double _submitGap = 20;

  /// A plain-text link under the submit button, at a 48dp tap height.
  /// A disabled link keeps the enabled color. With [end], the label aligns
  /// to the end edge, wrapped lines included.
  Widget _link(
    AppPalette palette,
    String label,
    VoidCallback? onPressed, {
    bool end = false,
  }) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: palette.foreground,
      disabledForegroundColor: palette.foreground,
      textStyle: AppTypography.settingsSelect,
      minimumSize: const Size(0, OneVpnButton.height),
      padding: EdgeInsets.zero,
      alignment: end ? AlignmentDirectional.centerEnd : null,
    ),
    child: Text(label, textAlign: end ? TextAlign.end : null),
  );

  /// Submits from the keyboard's Done key. A busy form ignores it.
  void _submitFromKeyboard() {
    if (!_submitting) _submit();
  }

  /// One form field. [action] sets the keyboard's action key and
  /// [onSubmitted] runs when the user presses it. With [autofocus], the
  /// field takes focus on its first build. With [autocorrect] false, the
  /// keyboard neither corrects nor suggests.
  Widget _field({
    required TextEditingController controller,
    required String label,
    required TextInputAction action,
    required VoidCallback onSubmitted,
    bool obscure = false,
    bool readOnly = false,
    bool autofocus = false,
    bool autocorrect = true,
    TextInputType? keyboardType,
    FocusNode? focusNode,
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    autofocus: autofocus,
    obscureText: obscure,
    keyboardType: keyboardType,
    autocorrect: autocorrect,
    enableSuggestions: autocorrect,
    readOnly: readOnly,
    textInputAction: action,
    onSubmitted: (_) => onSubmitted(),
    // A locked field takes no focus ring, cursor, or keyboard on tap.
    canRequestFocus: !readOnly,
    enabled: !_submitting,
    style: OneVpnField.text,
    decoration: OneVpnField.decoration(ColorManager.palette(context), label),
  );

  /// The submit button. A null [onPressed] disables the tap and keeps the
  /// enabled color.
  Widget _primaryButton({
    required AppPalette palette,
    required String label,
    required VoidCallback? onPressed,
  }) => Material(
    color: palette.primarySolid,
    borderRadius: BorderRadius.circular(OneVpnButton.radius),
    child: InkWell(
      borderRadius: BorderRadius.circular(OneVpnButton.radius),
      overlayColor: OneVpnButton.solidOverlay(context),
      onTap: onPressed,
      child: Container(
        height: OneVpnButton.height,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.settingsRow.copyWith(
            color: palette.primaryForeground,
          ),
        ),
      ),
    ),
  );
}
