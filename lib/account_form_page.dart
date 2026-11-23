import 'package:flutter/material.dart';

/// Values submitted by the account forms. Passwords retain their exact input.
typedef AccountFormValues = ({
  String username,
  String phone,
  String address,
  String password,
});

class AccountFormPage extends StatefulWidget {
  const AccountFormPage({
    super.key,
    this.isPassword = false,
    this.username = '',
    this.phone = '',
    this.address = '',
    required this.onSave,
  });

  final bool isPassword;
  final String username;
  final String phone;
  final String address;
  final Future<String> Function(AccountFormValues values) onSave;

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _username = TextEditingController(text: widget.username);
  late final _phone = TextEditingController(text: widget.phone);
  late final _address = TextEditingController(text: widget.address);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _username,
      _phone,
      _address,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final message = await widget.onSave((
        username: _username.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        password: _password.text,
      ));
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(message);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is String
            ? error
            : 'Could not save your changes. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF1F3F5) : const Color(0xFF19232D);
    final muted = dark ? const Color(0xFFABB5C0) : const Color(0xFF626D78);
    final background = dark ? const Color(0xFF141A22) : const Color(0xFFFAFBFC);
    final accent = dark ? const Color(0xFF8ABFFF) : const Color(0xFF1565C0);

    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.isPassword
                              ? Icons.lock_outline_rounded
                              : Icons.manage_accounts_outlined,
                          color: accent,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isPassword ? 'Change password' : 'Edit profile',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.15,
                      letterSpacing: -0.4,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isPassword
                        ? 'Choose a password you don’t use for another account.'
                        : 'Keep your account and contact details up to date.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: muted),
                  ),
                  const SizedBox(height: 24),
                  if (widget.isPassword) ...[
                    _field(
                      label: 'New password',
                      controller: _password,
                      obscure: _hidePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      helper: 'Use at least 6 characters.',
                      validator: (value) => (value ?? '').length < 6
                          ? 'Enter at least 6 characters.'
                          : null,
                      suffix: _visibilityButton(_hidePassword, () {
                        setState(() => _hidePassword = !_hidePassword);
                      }),
                    ),
                    _field(
                      label: 'Confirm new password',
                      controller: _confirm,
                      obscure: _hideConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      last: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Re-enter your new password.'
                          : value != _password.text
                          ? 'Passwords don’t match.'
                          : null,
                      suffix: _visibilityButton(_hideConfirm, () {
                        setState(() => _hideConfirm = !_hideConfirm);
                      }),
                    ),
                  ] else ...[
                    _sectionLabel('Account details', ink),
                    _field(
                      label: 'Username',
                      controller: _username,
                      autofillHints: const [AutofillHints.username],
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your username.'
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Divider(
                        color: theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                    _sectionLabel('Contact details', ink),
                    _field(
                      label: 'Phone number',
                      optional: true,
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    _field(
                      label: 'Address',
                      optional: true,
                      controller: _address,
                      keyboardType: TextInputType.streetAddress,
                      autofillHints: const [AutofillHints.fullStreetAddress],
                      last: true,
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: dark
                          ? const Color(0xFF102B49)
                          : Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _saving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Saving…'),
                            ],
                          )
                        : Text(
                            widget.isPassword
                                ? 'Update password'
                                : 'Save changes',
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: muted,
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _visibilityButton(bool hidden, VoidCallback toggle) => IconButton(
    tooltip: hidden ? 'Show password' : 'Hide password',
    onPressed: _saving ? null : toggle,
    icon: Icon(
      hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      size: 21,
    ),
  );

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool optional = false,
    bool obscure = false,
    bool last = false,
    String? helper,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: dark ? const Color(0xFF3C4653) : const Color(0xFFD5DBE1),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (optional)
                  TextSpan(
                    text: '  (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: controller,
            enabled: !_saving,
            obscureText: obscure,
            autocorrect: !widget.isPassword,
            enableSuggestions: !widget.isPassword,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: last ? (_) => _submit() : null,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: dark ? const Color(0xFF1C242F) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: dark
                      ? const Color(0xFF8ABFFF)
                      : const Color(0xFF1565C0),
                  width: 1.5,
                ),
              ),
              suffixIcon: suffix,
              helperText: helper,
              helperMaxLines: 4,
              errorMaxLines: 3,
              helperStyle: TextStyle(
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
