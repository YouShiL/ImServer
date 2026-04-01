import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';

import '../support/provider_test_fakes.dart';

void main() {
  group('GroupProvider', () {
    test('loadGroups should populate groups on success', () async {
      final api = FakeGroupApi()
        ..getMyGroupsHandler = () async => ResponseDTO<List<GroupDTO>>(
              code: 200,
              message: 'ok',
              data: <GroupDTO>[
                GroupDTO(id: 1, groupId: '8888888888', groupName: 'Test Group'),
              ],
            );
      final provider = GroupProvider(api: api);

      await provider.loadGroups();

      expect(provider.groups.length, 1);
      expect(provider.groups.first.groupName, 'Test Group');
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('setGroupMute should update local group state', () async {
      final api = FakeGroupApi();
      api.getMyGroupsHandler = () async => ResponseDTO<List<GroupDTO>>(
            code: 200,
            message: 'ok',
            data: <GroupDTO>[
              GroupDTO(
                id: 1,
                groupId: '8888888888',
                groupName: 'Test Group',
                isMute: false,
              ),
            ],
          );
      api.setGroupMuteHandler = (int groupId, bool isMute) async =>
          ResponseDTO<String>(code: 200, message: 'ok', data: 'done');
      final provider = GroupProvider(api: api);

      await provider.loadGroups();
      final result = await provider.setGroupMute(1, true);

      expect(result, isTrue);
      expect(provider.groups.first.isMute, isTrue);
    });

    test('loadMyJoinRequests should populate request list', () async {
      final api = FakeGroupApi()
        ..getMyJoinRequestsHandler =
            () async => ResponseDTO<List<GroupJoinRequestDTO>>(
                  code: 200,
                  message: 'ok',
                  data: <GroupJoinRequestDTO>[
                    GroupJoinRequestDTO(
                      id: 1,
                      groupId: 9,
                      userId: 100,
                      status: 0,
                    ),
                  ],
                );
      final provider = GroupProvider(api: api);

      await provider.loadMyJoinRequests();

      expect(provider.myJoinRequests.length, 1);
      expect(provider.myJoinRequests.first.id, 1);
    });

    test('withdrawJoinRequest should update local status to withdrawn', () async {
      final api = FakeGroupApi();
      api.getMyJoinRequestsHandler =
          () async => ResponseDTO<List<GroupJoinRequestDTO>>(
                code: 200,
                message: 'ok',
                data: <GroupJoinRequestDTO>[
                  GroupJoinRequestDTO(
                    id: 1,
                    groupId: 9,
                    userId: 100,
                    status: 0,
                  ),
                ],
              );
      api.withdrawJoinRequestHandler = (int requestId) async =>
          ResponseDTO<String>(code: 200, message: 'ok', data: 'withdrawn');
      final provider = GroupProvider(api: api);

      await provider.loadMyJoinRequests();
      final result = await provider.withdrawJoinRequest(1);

      expect(result, isTrue);
      expect(provider.myJoinRequests.first.status, 3);
    });
  });
}
