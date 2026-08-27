import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/controllers/chat_controller.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/models/privacy_models.dart';
import '../../core/models/workbench_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/local_task_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';
import '../../shared/adaptive_top_bar.dart';
import '../../ui/chat/input_field.dart';
import 'model_sheet.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _recording = false;
  bool _transcribing = false;
  bool _recognizingImage = false;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _messageController.removeListener(_refresh);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await ref
        .read(chatProvider.notifier)
        .send(text, newConversationTitle: context.l10n.newChatTitle);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final modelInfo = _modelInfo(settings.selectedModelId, chat.profiles);
    final errorText = _errorText(context, chat.errorCode, chat.errorDetail);
    if (chat.sending && chat.partialResponse.isNotEmpty) _scrollToEnd();

    final conversation = Column(
      children: [
        AdaptiveTopBar(
          title: context.l10n.navChat,
          subtitle:
              chat.currentSession?.title ?? context.l10n.chatWorkspaceSubtitle,
          actions: [
            IconButton(
              tooltip: context.l10n.conversations,
              onPressed: () => _showHistory(context),
              icon: const SiqiIcon(SiqiGlyph.history),
            ),
            IconButton(
              tooltip: context.l10n.newConversation,
              onPressed: () => ref
                  .read(chatProvider.notifier)
                  .newSession(context.l10n.newChatTitle),
              icon: const SiqiIcon(SiqiGlyph.add),
            ),
          ],
        ),
        if (errorText != null)
          MaterialBanner(
            content: Text(errorText),
            leading: const SiqiIcon(SiqiGlyph.warning),
            actions: [
              TextButton(
                onPressed: ref.read(chatProvider.notifier).clearError,
                child: Text(context.l10n.close),
              ),
            ],
          ),
        _WorkbenchStrip(
          modelName: modelInfo.name,
          multimodal: modelInfo.multimodal,
          mode: settings.selectedChatMode,
          workspacePath: settings.activeWorkspacePath,
          contextWindow: settings.contextWindow,
          streaming: settings.streamResponses,
          onModel: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: false,
            builder: (_) => const ModelSheet(),
          ),
          onMode: _selectMode,
        ),
        Expanded(
          child: chat.loading
              ? const Center(child: CircularProgressIndicator())
              : chat.messages.isEmpty && !chat.sending
              ? _EmptyConversation(
                  onSuggestion: (value) {
                    _messageController.text = value;
                    _messageController.selection = TextSelection.collapsed(
                      offset: value.length,
                    );
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  itemCount:
                      chat.messages.length +
                      (chat.sending ? 1 : 0) +
                      (chat.agentEnvelope == null ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index < chat.messages.length) {
                      return _MessageBubble(
                        message: chat.messages[index],
                        settings: settings,
                        onReadAloud:
                            chat.messages[index].role == MessageRole.assistant
                            ? () => _readAloud(chat.messages[index].content)
                            : null,
                      );
                    }
                    if (chat.sending && index == chat.messages.length) {
                      return _ThinkingBubble(partial: chat.partialResponse);
                    }
                    return _AgentApprovalPanel(
                      envelope: chat.agentEnvelope!,
                      results: chat.agentResults,
                      confirmMutations: settings.confirmAgentWrites,
                      rollingBack: chat.rollingBack,
                      rollbackComplete: chat.rollbackComplete,
                    );
                  },
                ),
        ),
        ChatInputField(
          controller: _messageController,
          attachments: chat.attachments,
          multimodal: modelInfo.multimodal,
          sending: chat.sending,
          cancelling: chat.cancelling,
          recording: _recording,
          transcribing: _transcribing,
          recognizingImage: _recognizingImage,
          onAttach: () => _attach(modelInfo.multimodal),
          onVoice: _toggleVoiceInput,
          onOcr: _recognizeScreenshot,
          onRemove: ref.read(chatProvider.notifier).removeAttachment,
          onSend: _send,
          onStop: ref.read(chatProvider.notifier).cancel,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 1080
          ? Row(
              children: [
                const SizedBox(width: 304, child: _HistoryPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: conversation),
              ],
            )
          : conversation,
    );
  }

  Future<void> _attach(bool multimodal) async {
    if (!multimodal) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.pureTextNotice)));
      return;
    }
    try {
      final files = await ref
          .read(fileContentServiceProvider)
          .pick(multimodal: true);
      await ref
          .read(permissionServiceProvider)
          .recordSystemPicker(
            kind: AppPermissionKind.photos,
            purpose: PermissionPurpose.imageAttachment,
            granted: files.isNotEmpty,
            detail: files.map((file) => file.name).join(', '),
          );
      ref.read(chatProvider.notifier).addAttachments(files);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.fileReadFailed(error.toString())),
          ),
        );
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    final service = ref.read(asrServiceProvider);
    if (_recording) {
      setState(() {
        _recording = false;
        _transcribing = true;
      });
      try {
        final path = await service.stopRecording();
        if (path == null) return;
        final model = await _installedTaskModel(ModelTask.speechRecognition);
        if (model == null) {
          throw const LocalTaskException('asr-model-not-installed');
        }
        final result = await service.transcribe(model: model, audioPath: path);
        if (!mounted) return;
        _insertComposerText(result.text);
      } on Object catch (error) {
        _showLocalTaskError(error);
      } finally {
        if (mounted) setState(() => _transcribing = false);
      }
      return;
    }

    final model = await _installedTaskModel(ModelTask.speechRecognition);
    if (model == null) {
      _showLocalTaskError(const LocalTaskException('asr-model-not-installed'));
      return;
    }
    final decision = await ref
        .read(permissionServiceProvider)
        .request(
          AppPermissionKind.microphone,
          PermissionPurpose.speechToText,
          detail: model.id,
        );
    if (decision != PermissionDecision.granted) {
      _showLocalTaskError(const LocalTaskException('microphone-denied'));
      return;
    }
    try {
      await service.startRecording();
      if (mounted) setState(() => _recording = true);
    } on Object catch (error) {
      _showLocalTaskError(error);
    }
  }

  Future<void> _recognizeScreenshot() async {
    final path = await ref.read(fileContentServiceProvider).pickImageForOcr();
    await ref
        .read(permissionServiceProvider)
        .recordSystemPicker(
          kind: AppPermissionKind.photos,
          purpose: PermissionPurpose.imageAttachment,
          granted: path != null,
          detail: path,
        );
    if (path == null || !mounted) return;
    setState(() => _recognizingImage = true);
    try {
      final result = await ref
          .read(ocrServiceProvider)
          .recognize(imagePath: path, settings: ref.read(settingsProvider));
      if (!mounted) return;
      _insertComposerText(result.text);
    } on Object catch (error) {
      _showLocalTaskError(error);
    } finally {
      if (mounted) setState(() => _recognizingImage = false);
    }
  }

  Future<void> _readAloud(String text) async {
    if (_speaking) {
      await ref.read(ttsServiceProvider).stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final model = await _installedTaskModel(ModelTask.speechSynthesis);
    if (model == null) {
      _showLocalTaskError(const LocalTaskException('tts-model-not-installed'));
      return;
    }
    setState(() => _speaking = true);
    try {
      await ref.read(ttsServiceProvider).speak(model: model, text: text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.speechPlaybackStarted)),
        );
      }
    } on Object catch (error) {
      _showLocalTaskError(error);
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<ModelDefinition?> _installedTaskModel(ModelTask task) async {
    for (final model in ModelCatalog.models.where(
      (item) => item.task == task && item.runnable,
    )) {
      if (await ref
          .read(modelDownloadServiceProvider)
          .isFullyInstalled(model)) {
        return model;
      }
    }
    return null;
  }

  void _insertComposerText(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final current = _messageController.text.trimRight();
    _messageController.text = current.isEmpty
        ? normalized
        : '$current\n$normalized';
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  void _showLocalTaskError(Object error) {
    if (!mounted) return;
    final code = error is LocalTaskException ? error.code : 'unknown';
    final message = switch (code) {
      'asr-model-not-installed' => context.l10n.asrModelRequired,
      'tts-model-not-installed' => context.l10n.ttsModelRequired,
      'vision-model-not-installed' => context.l10n.ocrModelRequired,
      'microphone-denied' => context.l10n.microphonePermissionDenied,
      'audio-too-long' => context.l10n.audioMaximumDuration,
      'insufficient-memory' => context.l10n.errorMemory,
      'text-too-long' => context.l10n.ttsTextTooLong,
      _ => context.l10n.localFeatureFailed(error.toString()),
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectMode(ChatMode mode) async {
    if (mode == ChatMode.agent) {
      final preferences = ref.read(sharedPreferencesProvider);
      final seen = preferences.getBool('agent_warning_seen') ?? false;
      if (!seen && mounted) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const SiqiIcon(SiqiGlyph.agent, size: 34),
            title: Text(context.l10n.agentWarningTitle),
            content: Text(context.l10n.agentWarningBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.enable),
              ),
            ],
          ),
        );
        if (accepted != true) return;
        await preferences.setBool('agent_warning_seen', true);
      }
    }
    String? harnessModelId;
    if (mode == ChatMode.harness) {
      final profileId = ref.read(settingsProvider).harnessApiProfileId;
      final profile = ref
          .read(chatProvider)
          .profiles
          .where(
            (item) =>
                item.id == profileId &&
                item.format != ApiFormat.local &&
                item.isDeepSeekProfile,
          )
          .firstOrNull;
      if (profile != null) {
        harnessModelId = 'custom:${profile.id}';
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorHarnessProfileRequired)),
        );
      }
    }
    await ref
        .read(settingsProvider.notifier)
        .update(
          (current) => current.copyWith(
            selectedChatMode: mode,
            selectedModelId: harnessModelId,
          ),
        );
  }

  void _showHistory(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.82, child: _HistoryPanel()),
  );
}

class _WorkbenchStrip extends StatelessWidget {
  const _WorkbenchStrip({
    required this.modelName,
    required this.multimodal,
    required this.mode,
    required this.workspacePath,
    required this.contextWindow,
    required this.streaming,
    required this.onModel,
    required this.onMode,
  });
  final String modelName;
  final bool multimodal;
  final ChatMode mode;
  final String? workspacePath;
  final int contextWindow;
  final bool streaming;
  final VoidCallback onModel;
  final ValueChanged<ChatMode> onMode;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 2, 12, 7),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onModel,
                icon: SiqiIcon(
                  multimodal ? SiqiGlyph.image : SiqiGlyph.chip,
                  size: 19,
                ),
                label: Text(
                  modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ModeMenu(current: mode, onSelected: onMode),
          ],
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SiqiStatusPill(
                label: workspacePath == null
                    ? context.l10n.noWorkspace
                    : workspacePath!.split(RegExp(r'[/\\]')).last,
                glyph: SiqiGlyph.workspace,
                compact: true,
                color: workspacePath == null
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              const SizedBox(width: 7),
              SiqiStatusPill(
                label: context.l10n.contextValue(
                  (contextWindow / 1024).round(),
                ),
                glyph: SiqiGlyph.memory,
                compact: true,
              ),
              const SizedBox(width: 7),
              SiqiStatusPill(
                label: streaming
                    ? context.l10n.streamingOn
                    : context.l10n.streamingOff,
                glyph: SiqiGlyph.tokens,
                compact: true,
              ),
              const SizedBox(width: 7),
              SiqiStatusPill(
                label: multimodal
                    ? context.l10n.multimodalReady
                    : context.l10n.textOnly,
                glyph: multimodal ? SiqiGlyph.image : SiqiGlyph.code,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(chatProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: TextField(
            onChanged: ref.read(chatProvider.notifier).searchSessions,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SiqiIcon(SiqiGlyph.search),
              ),
              hintText: context.l10n.searchHistory,
            ),
          ),
        ),
        if (current.sessions.isEmpty)
          Expanded(
            child: SiqiEmptyState(
              title: context.l10n.noConversations,
              body: context.l10n.noConversationsBody,
              glyph: SiqiGlyph.history,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: current.sessions.length,
              itemBuilder: (context, index) {
                final session = current.sessions[index];
                return ListTile(
                  selected: session.id == current.currentSession?.id,
                  title: Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const SiqiIcon(SiqiGlyph.chat),
                  trailing: IconButton(
                    tooltip: context.l10n.delete,
                    onPressed: () =>
                        ref.read(chatProvider.notifier).deleteSession(session),
                    icon: const SiqiIcon(SiqiGlyph.close, size: 19),
                  ),
                  onTap: () {
                    ref.read(chatProvider.notifier).selectSession(session);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ModeMenu extends StatelessWidget {
  const _ModeMenu({required this.current, required this.onSelected});
  final ChatMode current;
  final ValueChanged<ChatMode> onSelected;
  @override
  Widget build(BuildContext context) => PopupMenuButton<ChatMode>(
    tooltip: _modeName(context, current),
    initialValue: current,
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final mode in ChatMode.values)
        PopupMenuItem(
          value: mode,
          child: Row(
            children: [
              SiqiIcon(_modeGlyph(mode), size: 19),
              const SizedBox(width: 10),
              Text(_modeName(context, mode)),
            ],
          ),
        ),
    ],
    child: Chip(
      avatar: SiqiIcon(_modeGlyph(current), size: 18),
      label: Text(_modeName(context, current)),
    ),
  );
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MaterialSurface(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SiqiBrandMark(size: 64),
              const SizedBox(height: 16),
              Text(
                context.l10n.chatWelcomeTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.l10n.noMessages,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const SiqiIcon(SiqiGlyph.chat, size: 17),
                    label: Text(context.l10n.suggestionExplain),
                    onPressed: () =>
                        onSuggestion(context.l10n.suggestionExplainPrompt),
                  ),
                  ActionChip(
                    avatar: const SiqiIcon(SiqiGlyph.review, size: 17),
                    label: Text(context.l10n.suggestionReview),
                    onPressed: () =>
                        onSuggestion(context.l10n.suggestionReviewPrompt),
                  ),
                  ActionChip(
                    avatar: const SiqiIcon(SiqiGlyph.agent, size: 17),
                    label: Text(context.l10n.suggestionBuild),
                    onPressed: () =>
                        onSuggestion(context.l10n.suggestionBuildPrompt),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.settings,
    this.onReadAloud,
  });
  final ChatMessage message;
  final AppSettings settings;
  final VoidCallback? onReadAloud;
  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onReadAloud == null
            ? null
            : () => showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: ListTile(
                    leading: const SiqiIcon(SiqiGlyph.play),
                    title: Text(context.l10n.readAloud),
                    subtitle: Text(context.l10n.localTtsReadAloud),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onReadAloud?.call();
                    },
                  ),
                ),
              ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          margin: EdgeInsets.only(bottom: settings.messageSpacing),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(SiqiRadius.surface),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SiqiIcon(
                    isUser ? SiqiGlyph.user : SiqiGlyph.brand,
                    size: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUser ? context.l10n.roleYou : context.l10n.appName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (message.attachments.isNotEmpty) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.attachments
                      .map(
                        (attachment) => Chip(
                          avatar: SiqiIcon(
                            _attachmentGlyph(attachment),
                            size: 16,
                          ),
                          label: Text(attachment.name),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 6),
              SelectableText(message.content),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTime(
                    context,
                    message.createdAt,
                    settings.timestampStyle,
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.partial});
  final String partial;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: MaterialSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: partial.isEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(context.l10n.thinking),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox.square(
                        dimension: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.streamingResponse,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(partial),
                ],
              ),
      ),
    ),
  );
}

class _AgentApprovalPanel extends ConsumerWidget {
  const _AgentApprovalPanel({
    required this.envelope,
    required this.results,
    required this.confirmMutations,
    required this.rollingBack,
    required this.rollbackComplete,
  });
  final AgentEnvelope envelope;
  final List<AgentActionResult> results;
  final bool confirmMutations;
  final bool rollingBack;
  final bool rollbackComplete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = results.isEmpty;
    final canRollback = results.any(
      (result) => result.success && result.action.mutatesWorkspace,
    );
    return Card(
      margin: const EdgeInsets.only(top: 4, bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SiqiSectionHeader(
              title: context.l10n.agentActionPlan,
              subtitle: envelope.summary,
              icon: SiqiGlyph.agent,
              trailing: SiqiStatusPill(
                label: context.l10n.actionCount(envelope.actions.length),
                glyph: SiqiGlyph.queue,
                compact: true,
              ),
            ),
            if (envelope.steps.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (var index = 0; index < envelope.steps.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              envelope.steps[index].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              envelope.steps[index].description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const Divider(height: 24),
            for (final action in envelope.actions)
              _AgentActionTile(
                action: action,
                result: results
                    .where((item) => item.action.id == action.id)
                    .firstOrNull,
              ),
            if (pending) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: ref
                        .read(chatProvider.notifier)
                        .clearAgentActions,
                    icon: const SiqiIcon(SiqiGlyph.close, size: 17),
                    label: Text(context.l10n.rejectActions),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(chatProvider.notifier)
                        .executePendingAgentActions(allowMutations: false),
                    icon: const SiqiIcon(SiqiGlyph.shield, size: 17),
                    label: Text(context.l10n.approveReadOnly),
                  ),
                  FilledButton.icon(
                    onPressed: () => _approveAll(context, ref),
                    icon: const SiqiIcon(SiqiGlyph.check, size: 17),
                    label: Text(context.l10n.approveAll),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!rollbackComplete)
                    FilledButton.tonalIcon(
                      onPressed: rollingBack
                          ? null
                          : () => ref
                                .read(chatProvider.notifier)
                                .continueAgentRun(
                                  instruction: context.l10n.agentResultsPrompt,
                                  conversationTitle:
                                      context.l10n.newConversation,
                                ),
                      icon: const SiqiIcon(SiqiGlyph.agent, size: 17),
                      label: Text(context.l10n.continueAgent),
                    ),
                  if (canRollback)
                    OutlinedButton.icon(
                      onPressed: rollingBack || rollbackComplete
                          ? null
                          : () => _confirmRollback(context, ref),
                      icon: rollingBack
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : SiqiIcon(
                              rollbackComplete
                                  ? SiqiGlyph.check
                                  : SiqiGlyph.history,
                              size: 17,
                            ),
                      label: Text(
                        rollingBack
                            ? context.l10n.rollingBack
                            : rollbackComplete
                            ? context.l10n.rollbackComplete
                            : context.l10n.rollbackChanges,
                      ),
                    ),
                  TextButton(
                    onPressed: rollingBack
                        ? null
                        : ref.read(chatProvider.notifier).clearAgentActions,
                    child: Text(context.l10n.done),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref) async {
    if (confirmMutations &&
        envelope.actions.any((action) => action.mutatesWorkspace)) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const SiqiIcon(SiqiGlyph.warning, size: 34),
          title: Text(context.l10n.confirmAgentActionsTitle),
          content: Text(context.l10n.confirmAgentActionsBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirmExecute),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    await ref
        .read(chatProvider.notifier)
        .executePendingAgentActions(allowMutations: true);
  }

  Future<void> _confirmRollback(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const SiqiIcon(SiqiGlyph.history, size: 34),
        title: Text(context.l10n.rollbackTitle),
        content: Text(context.l10n.rollbackBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.rollbackChanges),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref.read(chatProvider.notifier).rollbackLastAgentExecution();
    }
  }
}

class _AgentActionTile extends StatelessWidget {
  const _AgentActionTile({required this.action, this.result});
  final AgentAction action;
  final AgentActionResult? result;
  @override
  Widget build(BuildContext context) {
    final success = result?.success;
    final color = success == null
        ? Theme.of(context).colorScheme.primary
        : success
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(SiqiRadius.surface),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SiqiIcon(_actionGlyph(action.type), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _actionName(context, action.type),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (success != null)
                SiqiIcon(
                  success ? SiqiGlyph.check : SiqiGlyph.warning,
                  size: 17,
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: 5),
          SelectableText(
            action.type == AgentActionType.runCommand
                ? action.command ?? ''
                : action.path,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          if (action.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                action.reason,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (result != null && result!.output.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  context.l10n.executionOutput,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(SiqiRadius.surface),
                    ),
                    child: SelectableText(
                      result!.output,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

({String name, bool multimodal}) _modelInfo(
  String id,
  List<ApiProfile> profiles,
) {
  if (id.startsWith('custom:')) {
    final profileId = id.substring('custom:'.length);
    final profile = profiles.where((item) => item.id == profileId).firstOrNull;
    return (
      name: profile?.name ?? profileId,
      multimodal: profile?.isMultimodal ?? false,
    );
  }
  final model = ModelCatalog.byId(id);
  return (name: model.displayName, multimodal: model.isMultimodal);
}

String? _errorText(BuildContext context, ChatErrorCode? code, String? detail) =>
    switch (code) {
      null => null,
      ChatErrorCode.apiNotTested => context.l10n.errorApiNotTested,
      ChatErrorCode.localNotDownloaded => context.l10n.errorLocalNotDownloaded,
      ChatErrorCode.localEngineUnavailable => switch (detail) {
        'modelLoad' => context.l10n.errorLocalModelLoad,
        'prompt' => context.l10n.errorLocalPrompt,
        'generation' => context.l10n.errorLocalGeneration,
        'emptyOutput' => context.l10n.errorLocalEmptyOutput,
        _ => context.l10n.errorEngineUnavailable,
      },
      ChatErrorCode.insufficientMemory => context.l10n.errorMemory,
      ChatErrorCode.networkUnavailable => context.l10n.errorNetwork,
      ChatErrorCode.requestFailed => context.l10n.errorRequest,
      ChatErrorCode.workspaceRequired => context.l10n.errorWorkspaceRequired,
      ChatErrorCode.harnessDeepSeekRequired =>
        context.l10n.errorHarnessProfileRequired,
    };

String _modeName(BuildContext context, ChatMode mode) => switch (mode) {
  ChatMode.chat => context.l10n.modeChat,
  ChatMode.agent => context.l10n.modeAgent,
  ChatMode.harness => context.l10n.modeHarness,
  ChatMode.mcp => context.l10n.modeMcp,
  ChatMode.team => context.l10n.modeTeam,
};
SiqiGlyph _modeGlyph(ChatMode mode) => switch (mode) {
  ChatMode.chat => SiqiGlyph.chat,
  ChatMode.agent => SiqiGlyph.agent,
  ChatMode.harness => SiqiGlyph.harness,
  ChatMode.mcp => SiqiGlyph.mcp,
  ChatMode.team => SiqiGlyph.queue,
};
SiqiGlyph _actionGlyph(AgentActionType type) => switch (type) {
  AgentActionType.listFiles => SiqiGlyph.folder,
  AgentActionType.readFile => SiqiGlyph.code,
  AgentActionType.writeFile => SiqiGlyph.review,
  AgentActionType.createDirectory => SiqiGlyph.add,
  AgentActionType.runCommand => SiqiGlyph.terminal,
};
String _actionName(BuildContext context, AgentActionType type) =>
    switch (type) {
      AgentActionType.listFiles => context.l10n.actionListFiles,
      AgentActionType.readFile => context.l10n.actionReadFile,
      AgentActionType.writeFile => context.l10n.actionWriteFile,
      AgentActionType.createDirectory => context.l10n.actionCreateDirectory,
      AgentActionType.runCommand => context.l10n.actionRunCommand,
    };

SiqiGlyph _attachmentGlyph(AppAttachment attachment) {
  if (attachment.mimeType.startsWith('image/')) return SiqiGlyph.image;
  if (attachment.mimeType.startsWith('audio/')) return SiqiGlyph.audio;
  if (attachment.mimeType.contains('pdf')) return SiqiGlyph.pdf;
  return SiqiGlyph.code;
}

String _formatTime(BuildContext context, DateTime date, TimestampStyle style) {
  if (style == TimestampStyle.twelveHour) {
    return DateFormat(
      'h:mm a',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }
  if (style == TimestampStyle.twentyFourHour) {
    return DateFormat(
      'HH:mm',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return context.l10n.justNow;
  if (difference.inHours < 1) {
    return context.l10n.minutesAgo(difference.inMinutes);
  }
  if (difference.inDays < 1) return context.l10n.hoursAgo(difference.inHours);
  return context.l10n.daysAgo(difference.inDays);
}
