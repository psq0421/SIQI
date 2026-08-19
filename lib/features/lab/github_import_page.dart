import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class GithubImportPage extends ConsumerStatefulWidget {
  const GithubImportPage({super.key});
  @override
  ConsumerState<GithubImportPage> createState() => _GithubImportPageState();
}

class _GithubImportPageState extends ConsumerState<GithubImportPage> {
  final _owner = TextEditingController();
  final _repository = TextEditingController();
  final _token = TextEditingController();
  final _clientId = TextEditingController();
  String? _destination;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    final token = await ref.read(secureKeyServiceProvider).readGithubToken();
    if (mounted && token != null) _token.text = token;
  }

  @override
  void dispose() {
    _owner.dispose();
    _repository.dispose();
    _token.dispose();
    _clientId.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) setState(() => _destination = path);
  }

  Future<void> _oauth() async {
    final localizations = context.l10n;
    final clientId = _clientId.text.trim();
    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.oauthClientIdRequired)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final deviceCode = await ref
          .read(githubServiceProvider)
          .requestDeviceCode(clientId);
      await Clipboard.setData(ClipboardData(text: deviceCode.userCode));
      if (!await launchUrl(
        deviceCode.verificationUri,
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError(localizations.oauthOpenFailed);
      }
      if (!mounted) return;
      final wait = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(localizations.githubOAuth),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.oauthInstruction),
              const SizedBox(height: 12),
              SelectableText(
                deviceCode.userCode,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(localizations.oauthCodeCopied),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.authorizationComplete),
            ),
          ],
        ),
      );
      if (wait != true) return;
      final token = await ref
          .read(githubServiceProvider)
          .pollDeviceToken(clientId: clientId, deviceCode: deviceCode);
      if (token == null) throw StateError(localizations.oauthPendingOrExpired);
      _token.text = token;
      await ref.read(secureKeyServiceProvider).writeGithubToken(token);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.oauthSuccess)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.importFailed(error.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_owner.text.trim().isEmpty ||
        _repository.text.trim().isEmpty ||
        _destination == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.requiredField)));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(githubServiceProvider)
          .importRepository(
            owner: _owner.text.trim(),
            repository: _repository.text.trim(),
            destination: _destination!,
            token: _token.text.trim(),
          );
      if (_token.text.trim().isNotEmpty) {
        await ref
            .read(secureKeyServiceProvider)
            .writeGithubToken(_token.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.importSuccess)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.importFailed(error.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.githubImport)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _owner,
          decoration: InputDecoration(labelText: context.l10n.repoOwner),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _repository,
          decoration: InputDecoration(labelText: context.l10n.repoName),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _token,
          obscureText: true,
          decoration: InputDecoration(labelText: context.l10n.tokenOptional),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _clientId,
          decoration: InputDecoration(labelText: context.l10n.oauthClientId),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _oauth,
          icon: const SiqiIcon(SiqiGlyph.github),
          label: Text(context.l10n.githubOAuth),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const SiqiIcon(SiqiGlyph.folder),
          title: Text(context.l10n.destination),
          subtitle: Text(_destination ?? context.l10n.chooseFolder),
          trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
          onTap: _choose,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _import,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const SiqiIcon(SiqiGlyph.import),
          label: Text(context.l10n.importAction),
        ),
      ],
    ),
  );
}
