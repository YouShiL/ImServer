import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
import 'package:provider/provider.dart';

/// 编辑群资料与入群设置（独立页）。
class EditGroupProfileScreen extends StatefulWidget {
  const EditGroupProfileScreen({
    super.key,
    required this.groupId,
    required this.group,
  });

  final int groupId;
  final GroupDTO group;

  @override
  State<EditGroupProfileScreen> createState() =>
      _EditGroupProfileScreenState();
}

class _EditGroupProfileScreenState extends State<EditGroupProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noticeController;
  late bool _allowMemberInvite;
  late int _joinType;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameController = TextEditingController(text: g.groupName ?? '');
    _descriptionController = TextEditingController(text: g.description ?? '');
    _noticeController = TextEditingController(text: g.notice ?? '');
    _allowMemberInvite = g.allowMemberInvite ?? true;
    _joinType = g.joinType ?? ((g.needVerify ?? false) ? 1 : 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _noticeController.dispose();
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
    final success = await groupProvider.updateGroup(widget.groupId, {
      'groupName': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'notice': _noticeController.text.trim(),
      'allowMemberInvite': _allowMemberInvite,
      'joinType': _joinType,
    });
    if (!mounted) {
      return;
    }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(FeedbackUxStrings.snackGroupSettingsSaved)),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = FeedbackUxStrings.messageOrFallback(
          groupProvider.error,
          FeedbackUxStrings.fallbackSaveFailed,
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
        title: const Text('编辑群资料'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _whiteBlock(
            child: TextField(
              controller: _nameController,
              decoration: ImTemplateShell.dialogFieldDecoration(label: '群名称'),
            ),
          ),
          const SizedBox(height: 10),
          _whiteBlock(
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: ImTemplateShell.dialogFieldDecoration(
                label: '群简介',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _whiteBlock(
            child: TextField(
              controller: _noticeController,
              maxLines: 3,
              decoration: ImTemplateShell.dialogFieldDecoration(
                label: '群公告',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _whiteBlock(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('允许成员邀请'),
              subtitle: const Text('关闭后，仅群主或管理员可添加或邀请新成员'),
              value: _allowMemberInvite,
              onChanged: (v) => setState(() => _allowMemberInvite = v),
            ),
          ),
          const SizedBox(height: 10),
          _whiteBlock(
            child: DropdownButtonFormField<int>(
              initialValue: _joinType,
              decoration: ImTemplateShell.dialogFieldDecoration(
                label: '入群方式',
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('允许直接入群')),
                DropdownMenuItem(value: 1, child: Text('需管理员确认入群')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _joinType = v);
                }
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: CommonTokens.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: UiTokens.filledPrimary(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting
                  ? FeedbackUxStrings.buttonSavingInProgress
                  : FeedbackUxStrings.buttonSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteBlock({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CommonTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommonTokens.lineSubtle),
      ),
      child: child,
    );
  }
}
