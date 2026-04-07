import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/profile_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/wx_list_group.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// 资料“已保存态”快照，用于脏检测（与 [AuthProvider.updateUserInfo] 提交语义一致）。
class _EditBaseline {
  const _EditBaseline({
    required this.nickname,
    required this.signature,
    required this.region,
    required this.avatar,
    required this.birthdayYmd,
    required this.genderSubmit,
  });

  final String nickname;
  final String signature;
  final String region;
  final String avatar;
  final String birthdayYmd;
  /// 与提交一致：`0` 未设置，`1/2` 男/女。
  final int genderSubmit;
}

/// 当前登录用户的基础资料编辑；提交走 [AuthProvider.updateUserInfo]。
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nickname;
  late final TextEditingController _signature;
  late final TextEditingController _region;
  late final TextEditingController _avatar;
  int? _gender;
  bool _seeded = false;
  bool _saving = false;
  /// 新选头像的本地预览（保存时先上传再写入 profile）。
  Uint8List? _pickedAvatarBytes;
  String? _pickedAvatarFilename;
  /// `yyyy-MM-dd`，空字符串表示未设置。
  String _birthdayYmd = '';

  _EditBaseline? _baseline;

  void _onFieldsDirty() {
    if (mounted) {
      setState(() {});
    }
  }

  static int _genderSubmitValue(int? g) => (g == 1 || g == 2) ? g! : 0;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController();
    _signature = TextEditingController();
    _region = TextEditingController();
    _avatar = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return;
    }
    _seeded = true;
    _nickname.text = (user.nickname ?? '').trim();
    _signature.text = (user.signature ?? '').trim();
    _region.text = (user.region ?? '').trim();
    _avatar.text = (user.avatar ?? '').trim();
    final int? g = user.gender;
    _gender = (g == 1 || g == 2) ? g : null;
    _birthdayYmd = _normalizeBirthdayIncoming(user.birthday);

    _nickname.addListener(_onFieldsDirty);
    _signature.addListener(_onFieldsDirty);
    _region.addListener(_onFieldsDirty);
    _avatar.addListener(_onFieldsDirty);

    _captureBaseline();
  }

  void _captureBaseline() {
    _baseline = _EditBaseline(
      nickname: _nickname.text.trim(),
      signature: _signature.text.trim(),
      region: _region.text.trim(),
      avatar: _avatar.text.trim(),
      birthdayYmd: _birthdayYmd.trim(),
      genderSubmit: _genderSubmitValue(_gender),
    );
  }

  Widget _editPanel({required Widget child}) {
    return WxListGroup(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: child,
    );
  }

  bool get _isDirty {
    final _EditBaseline? b = _baseline;
    if (!(_seeded && b != null)) {
      return false;
    }
    if (_pickedAvatarBytes != null) {
      return true;
    }
    if (_nickname.text.trim() != b.nickname) {
      return true;
    }
    if (_signature.text.trim() != b.signature) {
      return true;
    }
    if (_region.text.trim() != b.region) {
      return true;
    }
    if (_avatar.text.trim() != b.avatar) {
      return true;
    }
    if (_birthdayYmd.trim() != b.birthdayYmd) {
      return true;
    }
    if (_genderSubmitValue(_gender) != b.genderSubmit) {
      return true;
    }
    return false;
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isDirty) {
      return true;
    }
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: ImTemplateShell.dialogShape,
          insetPadding: ImTemplateShell.dialogInsetPadding,
          title: const ImDialogTitle('放弃修改？'),
          titlePadding: ImTemplateShell.dialogTitlePadding,
          contentPadding: ImTemplateShell.dialogContentPadding,
          content: Text(
            '当前资料有未保存的修改，确定要离开吗？',
            style: TextStyle(
              color: UiTokens.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          actionsPadding: ImTemplateShell.dialogActionsPadding,
          actionsAlignment: MainAxisAlignment.end,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                '继续编辑',
                style: TextStyle(color: UiTokens.textSecondary),
              ),
            ),
            FilledButton(
              style: UiTokens.filledPrimary(),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('离开'),
            ),
          ],
        );
      },
    );
    return discard ?? false;
  }

  /// 兼容 `yyyy-MM-dd`、`yyyy-MM-ddTHH:mm:ss` 及后端暂缺字段。
  static String _normalizeBirthdayIncoming(String? raw) {
    if (raw == null) {
      return '';
    }
    final String t = raw.trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.length >= 10) {
      final String head = t.substring(0, 10);
      final RegExp ymd = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (ymd.hasMatch(head)) {
        return head;
      }
    }
    try {
      final DateTime d = DateTime.parse(t).toLocal();
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  DateTime? _dateFromYmd(String ymd) {
    final String t = ymd.trim();
    if (t.length < 10) {
      return null;
    }
    final List<String> parts = t.substring(0, 10).split('-');
    if (parts.length != 3) {
      return null;
    }
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      return null;
    }
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickBirthday() async {
    if (_saving) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime initial =
        _dateFromYmd(_birthdayYmd) ?? DateTime(now.year - 25, now.month, now.day);
    if (initial.isAfter(today)) {
      initial = DateTime(now.year - 18, now.month, now.day);
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: today,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _birthdayYmd =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  void _clearBirthday() {
    if (_saving) {
      return;
    }
    setState(() => _birthdayYmd = '');
  }

  @override
  void dispose() {
    if (_seeded) {
      _nickname.removeListener(_onFieldsDirty);
      _signature.removeListener(_onFieldsDirty);
      _region.removeListener(_onFieldsDirty);
      _avatar.removeListener(_onFieldsDirty);
    }
    _nickname.dispose();
    _signature.dispose();
    _region.dispose();
    _avatar.dispose();
    super.dispose();
  }

  bool _isNetworkAvatar(String url) {
    final t = url.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  Future<void> _pickAvatar() async {
    if (_saving) {
      return;
    }
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (file == null || !mounted) {
        return;
      }
      final List<int> raw = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _pickedAvatarBytes = Uint8List.fromList(raw);
        final String name = file.name.trim();
        _pickedAvatarFilename = name.isEmpty ? 'avatar.jpg' : name;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(FeedbackUxStrings.snackImagePickFailed)),
      );
    }
  }

  void _clearPickedAvatar() {
    if (_saving) {
      return;
    }
    setState(() {
      _pickedAvatarBytes = null;
      _pickedAvatarFilename = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_isDirty) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final nick = _nickname.text.trim();
    final sig = _signature.text.trim();
    final region = _region.text.trim();
    var avatar = _avatar.text.trim();

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (_pickedAvatarBytes != null) {
      final upload = await ApiService.uploadImageBytes(
        _pickedAvatarBytes!,
        filename: _pickedAvatarFilename ?? 'avatar.jpg',
      );
      if (!mounted) {
        return;
      }
      final String? url = upload.data?.fileUrl ?? upload.data?.filePath;
      if (!upload.isSuccess || url == null || url.trim().isEmpty) {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              FeedbackUxStrings.messageOrFallback(
              upload.message,
              '头像上传失败，请检查网络后重试',
            ),
            ),
          ),
        );
        return;
      }
      avatar = url.trim();
    }

    final data = <String, dynamic>{
      'nickname': nick,
      'signature': sig,
      'region': region,
      'avatar': avatar,
      'birthday': _birthdayYmd.trim(),
      'gender': _gender ?? 0,
    };

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateUserInfo(data);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (ok) {
      _pickedAvatarBytes = null;
      _pickedAvatarFilename = null;
      setState(_captureBaseline);
      messenger.showSnackBar(
        const SnackBar(content: Text(FeedbackUxStrings.snackProfileSaved)),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            FeedbackUxStrings.messageOrFallback(
              auth.error,
              FeedbackUxStrings.fallbackSaveFailed,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    if (authUser == null) {
      return Scaffold(
        backgroundColor: ProfileUiTokens.pageBackground,
        appBar: AppBar(title: const Text('编辑资料')),
        body: Center(
          child: Text(
            '无法加载账号资料',
            style: CommonTokens.body.copyWith(color: CommonTokens.textSecondary),
          ),
        ),
      );
    }

    final previewUrl = _avatar.text.trim();
    final bool hasPicked = _pickedAvatarBytes != null;
    final bool showNetwork =
        !hasPicked && previewUrl.isNotEmpty && _isNetworkAvatar(previewUrl);

    return PopScope(
      canPop: !_isDirty && !_saving,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        if (_saving) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(FeedbackUxStrings.buttonSavingInProgress)),
          );
          return;
        }
        final bool leave = await _confirmDiscardIfNeeded();
        if (!context.mounted) return;
        if (leave) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: UiTokens.backgroundGray,
      appBar: AppBar(
        title: const Text('编辑资料'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UiTokens.backgroundGray,
        foregroundColor: UiTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving
              ? null
              : () async {
                  if (!_isDirty) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    return;
                  }
                  final bool leave = await _confirmDiscardIfNeeded();
                  if (!context.mounted) return;
                  if (leave) {
                    Navigator.of(context).pop();
                  }
                },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ImTemplateShell.pagePaddingH,
                  ImTemplateShell.pagePaddingV,
                  ImTemplateShell.pagePaddingH,
                  ImTemplateShell.sectionGap,
                ),
                children: <Widget>[
                  _editPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '头像',
                          style: CommonTokens.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saving ? null : _pickAvatar,
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.12),
                          child: ClipOval(
                            child: hasPicked
                                ? Image.memory(
                                    _pickedAvatarBytes!,
                                    fit: BoxFit.cover,
                                    width: 72,
                                    height: 72,
                                  )
                                : showNetwork
                                    ? Image.network(
                                        previewUrl,
                                        fit: BoxFit.cover,
                                        width: 72,
                                        height: 72,
                                        filterQuality: FilterQuality.medium,
                                        loadingBuilder:
                                            (BuildContext context, Widget child,
                                                ImageChunkEvent? progress) {
                                          if (progress == null) {
                                            return child;
                                          }
                                          final double? v =
                                              progress.expectedTotalBytes != null
                                                  ? progress.cumulativeBytesLoaded /
                                                      progress.expectedTotalBytes!
                                                  : null;
                                          return Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: v,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (BuildContext context, Object error,
                                                StackTrace? stack) {
                                          return _networkAvatarErrorPlaceholder(
                                              context);
                                        },
                                      )
                                    : _localAvatarPlaceholder(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '点击更换',
                      style: CommonTokens.caption.copyWith(
                        color: CommonTokens.textTertiary,
                      ),
                    ),
                    if (hasPicked)
                      TextButton(
                        onPressed: _saving ? null : _clearPickedAvatar,
                        child: const Text('清除所选图片'),
                      ),
                  ],
                ),
                const SizedBox(width: CommonTokens.space16),
                Expanded(
                  child: TextFormField(
                    controller: _avatar,
                    decoration: UiTokens.screenFieldDecoration(
                      label: '头像链接（可选）',
                      hint: '也可粘贴图片 URL；相册所选保存时会优先上传',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                    onChanged: (String _) {
                      setState(() {
                        _pickedAvatarBytes = null;
                        _pickedAvatarFilename = null;
                      });
                    },
                  ),
                ),
              ],
            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ImTemplateShell.sectionGap),
                  _editPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
            TextFormField(
              controller: _nickname,
              decoration: UiTokens.screenFieldDecoration(
                label: '昵称',
              ).copyWith(
                filled: true,
                fillColor: CommonTokens.surfacePrimary,
              ),
              maxLength: 50,
              validator: (String? v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) {
                  return '请输入昵称';
                }
                if (t.length < 2) {
                  return '昵称至少 2 个字';
                }
                return null;
              },
            ),
            const SizedBox(height: ImTemplateShell.elementGapMd),
            TextFormField(
              controller: _signature,
              decoration: UiTokens.screenFieldDecoration(
                label: '个性签名（可选）',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
              validator: (String? v) {
                if ((v ?? '').trim().length > 200) {
                  return '签名过长';
                }
                return null;
              },
            ),
            const SizedBox(height: ImTemplateShell.elementGapMd),
            Text(
              '性别',
              style: CommonTokens.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: UiTokens.textPrimary,
              ),
            ),
            const SizedBox(height: ImTemplateShell.elementGapSm),
            Wrap(
              spacing: CommonTokens.space8,
              runSpacing: CommonTokens.space8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('未设置'),
                  selected: _gender == null,
                  onSelected: _saving
                      ? null
                      : (bool selected) {
                          if (selected) {
                            setState(() => _gender = null);
                          }
                        },
                ),
                ChoiceChip(
                  label: const Text('男'),
                  selected: _gender == 1,
                  onSelected: _saving
                      ? null
                      : (bool selected) {
                          if (selected) {
                            setState(() => _gender = 1);
                          }
                        },
                ),
                ChoiceChip(
                  label: const Text('女'),
                  selected: _gender == 2,
                  onSelected: _saving
                      ? null
                      : (bool selected) {
                          if (selected) {
                            setState(() => _gender = 2);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: ImTemplateShell.elementGapMd),
            TextFormField(
              controller: _region,
              decoration: UiTokens.screenFieldDecoration(
                label: '地区（可选）',
                hint: '可直接填写文字，例如：上海市',
              ),
              maxLength: 100,
              validator: (String? v) {
                if ((v ?? '').trim().length > 100) {
                  return '地区文字过长';
                }
                return null;
              },
            ),
            const SizedBox(height: ImTemplateShell.elementGapMd),
            Text(
              '生日（可选）',
              style: CommonTokens.body.copyWith(
                color: CommonTokens.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: ImTemplateShell.elementGapSm),
            InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: UiTokens.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiTokens.radiusSmall),
                  borderSide: const BorderSide(color: UiTokens.lineSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiTokens.radiusSmall),
                  borderSide: const BorderSide(color: UiTokens.lineSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiTokens.radiusSmall),
                  borderSide: const BorderSide(color: UiTokens.primaryBlue, width: 1.5),
                ),
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: UiTokens.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              child: InkWell(
                onTap: _saving ? null : _pickBirthday,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _birthdayYmd.isEmpty ? '点击选择日期' : _birthdayYmd,
                          style: CommonTokens.body.copyWith(
                            color: _birthdayYmd.isEmpty
                                ? CommonTokens.textTertiary
                                : CommonTokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_birthdayYmd.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _saving ? null : _clearBirthday,
                  child: const Text('清除生日'),
                ),
              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: UiTokens.backgroundGray,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: CommonTokens.lineSubtle),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ImTemplateShell.pagePaddingH,
                    10,
                    ImTemplateShell.pagePaddingH,
                    12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: UiTokens.filledPrimary(),
                      onPressed: (_saving || !_isDirty) ? null : _save,
                      child: _saving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  FeedbackUxStrings.buttonSavingInProgress,
                                ),
                              ],
                            )
                          : const Text(FeedbackUxStrings.buttonSave),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// 非网络 URL（含空）时的占位，与网络失败态风格一致。
  Widget _localAvatarPlaceholder(BuildContext context) {
    final Color c = Theme.of(context).primaryColor;
    return ColoredBox(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
      child: Icon(Icons.person_outline_rounded, size: 36, color: c),
    );
  }

  Widget _networkAvatarErrorPlaceholder(BuildContext context) {
    final Color c = Theme.of(context).primaryColor;
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
      child: Icon(Icons.broken_image_outlined, size: 32, color: c),
    );
  }
}
