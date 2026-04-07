import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
import 'package:provider/provider.dart';

/// 新建群聊（独立页，轻表单）。
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = '请输入群名称');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final groupProvider = context.read<GroupProvider>();
    final ok = await groupProvider.createGroup(
      _nameController.text.trim(),
      _descController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(FeedbackUxStrings.snackGroupCreated)),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _error = FeedbackUxStrings.messageOrFallback(
          groupProvider.error,
          FeedbackUxStrings.fallbackOperationFailed,
        );
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommonTokens.bgPrimary,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CommonTokens.bgPrimary,
        foregroundColor: CommonTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('创建群聊'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CommonTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CommonTokens.lineSubtle),
            ),
            child: TextField(
              controller: _nameController,
              decoration: ImTemplateShell.dialogFieldDecoration(label: '群名称'),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CommonTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CommonTokens.lineSubtle),
            ),
            child: TextField(
              controller: _descController,
              maxLines: 3,
              decoration: ImTemplateShell.dialogFieldDecoration(
                label: '群介绍',
                alignLabelWithHint: true,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: CommonTokens.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: UiTokens.filledPrimary(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting
                  ? FeedbackUxStrings.buttonCreatingInProgress
                  : FeedbackUxStrings.buttonCreate,
            ),
          ),
        ],
      ),
    );
  }
}
