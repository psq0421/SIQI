import 'package:flutter/material.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../l10n/l10n.dart';

class ChatInputField extends StatelessWidget {
  const ChatInputField({
    required this.controller,
    required this.attachments,
    required this.multimodal,
    required this.sending,
    required this.cancelling,
    required this.recording,
    required this.transcribing,
    required this.recognizingImage,
    required this.onAttach,
    required this.onVoice,
    required this.onOcr,
    required this.onRemove,
    required this.onSend,
    required this.onStop,
    super.key,
  });

  final TextEditingController controller;
  final List<AppAttachment> attachments;
  final bool multimodal;
  final bool sending;
  final bool cancelling;
  final bool recording;
  final bool transcribing;
  final bool recognizingImage;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final VoidCallback onOcr;
  final ValueChanged<AppAttachment> onRemove;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachments.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: attachments
                    .map(
                      (attachment) => InputChip(
                        avatar: SiqiIcon(
                          _attachmentGlyph(attachment),
                          size: 15,
                        ),
                        label: Text(attachment.name),
                        onDeleted: () => onRemove(attachment),
                      ),
                    )
                    .toList(),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: context.l10n.attach,
                color: multimodal
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
                onPressed: sending ? null : onAttach,
                icon: const SiqiIcon(SiqiGlyph.add),
              ),
              IconButton(
                tooltip: recording
                    ? context.l10n.stopRecording
                    : context.l10n.voiceInput,
                color: recording ? Theme.of(context).colorScheme.error : null,
                onPressed: sending || transcribing ? null : onVoice,
                icon: transcribing
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : SiqiIcon(recording ? SiqiGlyph.stop : SiqiGlyph.audio),
              ),
              IconButton(
                tooltip: context.l10n.screenshotOcr,
                onPressed: sending || recognizingImage ? null : onOcr,
                icon: recognizingImage
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SiqiIcon(SiqiGlyph.image),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: recording
                        ? context.l10n.recordingInProgress
                        : context.l10n.messageHint,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: sending ? context.l10n.stop : context.l10n.send,
                onPressed: sending
                    ? (cancelling ? null : onStop)
                    : (controller.text.trim().isEmpty ? null : onSend),
                icon: cancelling
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : SiqiIcon(
                        sending ? SiqiGlyph.stop : SiqiGlyph.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

SiqiGlyph _attachmentGlyph(AppAttachment attachment) {
  if (attachment.mimeType.startsWith('image/')) return SiqiGlyph.image;
  if (attachment.mimeType.startsWith('audio/')) return SiqiGlyph.audio;
  if (attachment.mimeType.contains('pdf')) return SiqiGlyph.pdf;
  return SiqiGlyph.code;
}
