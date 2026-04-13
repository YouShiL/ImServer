import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_api_flows_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_chat_entry_log.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/group_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/widgets_v2/contacts/contact_section_header_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/contacts/contacts_empty_state_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/contacts/group_list_item_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class GroupsV2Page extends StatefulWidget {
  const GroupsV2Page({super.key});

  @override
  State<GroupsV2Page> createState() => _GroupsV2PageState();
}

class _GroupsV2PageState extends State<GroupsV2Page> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await context.read<GroupProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GroupProvider groupProvider = context.watch<GroupProvider>();
    final List<GroupDTO> groups = groupProvider.groups;

    Widget child;
    if (groupProvider.isLoading && groups.isEmpty) {
      child = const Center(child: CircularProgressIndicator());
    } else if (groups.isEmpty) {
      child = const ContactsEmptyStateV2(
        title: '暂无群组',
        subtitle: '当前还没有可展示的群组数据。',
      );
    } else {
      child = ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: groups.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return const ContactSectionHeaderV2(title: '我的群组');
          }

          final GroupDTO group = groups[index - 1];
          // 与后端契约一致：message.group_id / WuKong channel_id 均为 group_chat.id（GroupDTO.id）。
          // groupId 为业务展示用字符串（如 10 位数字），不可用作 REST / IM 的群标识。
          final int? targetId = group.id;
          final String title = (group.groupName ?? '').trim().isNotEmpty
              ? group.groupName!.trim()
              : '未命名群组';
          final String subtitle = group.description?.trim().isNotEmpty == true
              ? group.description!.trim()
              : group.memberCount != null
                  ? '${group.memberCount} 位成员'
                  : '群聊资料占位';

          return GroupListItemV2(
            title: title,
            subtitle: subtitle,
            onTap: targetId == null
                ? () {}
                : () {
                    imGroupFlowLog('groups_tap_chat', <String, Object?>{
                      'sourceApi': '/group/my-groups -> GroupDTO',
                      'sourceModel': 'GroupDTO',
                      'group.id': group.id?.toString() ?? 'null',
                      'group.groupCode': group.groupCode ?? 'null',
                      'chatTargetId': targetId.toString(),
                      'ownerId': group.ownerId?.toString() ?? 'null',
                      'chatType': '2',
                    });
                    imChatEntryLog(
                      'groups_list',
                      targetId: targetId,
                      type: 2,
                      title: title,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GroupDetailV2Page(
                          groupId: targetId,
                          initialGroup: group,
                        ),
                      ),
                    );
                  },
          );
        },
      );
    }

    return SecondaryPageScaffoldV2(
      title: '群组',
      child: child,
    );
  }
}
