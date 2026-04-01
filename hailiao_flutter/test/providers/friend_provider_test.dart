import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';

import '../support/provider_test_fakes.dart';

void main() {
  group('FriendProvider', () {
    test('loadFriends should populate list on success', () async {
      final provider = FriendProvider(
        api: FakeFriendApi(
          getFriendsHandler: () async => ResponseDTO<List<FriendDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendDTO>[
              FriendDTO(id: 1, userId: 100, friendId: 200, remark: 'Bob'),
            ],
          ),
        ),
      );

      await provider.loadFriends();

      expect(provider.friends.length, 1);
      expect(provider.friends.first.friendId, 200);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadFriendRequests should populate received and sent lists', () async {
      final provider = FriendProvider(
        api: FakeFriendApi(
          getReceivedHandler: () async => ResponseDTO<List<FriendRequestDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendRequestDTO>[
              FriendRequestDTO(id: 1, fromUserId: 200, toUserId: 100, status: 0),
            ],
          ),
          getSentHandler: () async => ResponseDTO<List<FriendRequestDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendRequestDTO>[
              FriendRequestDTO(id: 2, fromUserId: 100, toUserId: 300, status: 0),
            ],
          ),
        ),
      );

      await provider.loadFriendRequests();

      expect(provider.receivedRequests.length, 1);
      expect(provider.sentRequests.length, 1);
      expect(provider.receivedRequests.first.id, 1);
      expect(provider.sentRequests.first.id, 2);
    });

    test('acceptFriendRequest should refresh friends and requests', () async {
      final provider = FriendProvider(
        api: FakeFriendApi(
          getFriendsHandler: () async => ResponseDTO<List<FriendDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendDTO>[
              FriendDTO(id: 1, userId: 100, friendId: 200, remark: 'Bob'),
            ],
          ),
          getReceivedHandler: () async => ResponseDTO<List<FriendRequestDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendRequestDTO>[],
          ),
          getSentHandler: () async => ResponseDTO<List<FriendRequestDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendRequestDTO>[],
          ),
          acceptRequestHandler: (int requestId) async =>
              ResponseDTO<String>(code: 200, message: 'ok', data: 'accepted'),
        ),
      );

      await provider.loadFriendRequests();
      provider.receivedRequests.add(
        FriendRequestDTO(id: 9, fromUserId: 200, toUserId: 100),
      );
      final result = await provider.acceptFriendRequest(9);

      expect(result, isTrue);
      expect(provider.friends.length, 1);
      expect(provider.receivedRequests, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('deleteFriend should remove matching friend on success', () async {
      final provider = FriendProvider(
        api: FakeFriendApi(
          getFriendsHandler: () async => ResponseDTO<List<FriendDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendDTO>[
              FriendDTO(id: 1, userId: 100, friendId: 200, remark: 'Bob'),
              FriendDTO(id: 2, userId: 100, friendId: 300, remark: 'Alice'),
            ],
          ),
          deleteFriendHandler: (int friendId) async =>
              ResponseDTO<String>(code: 200, message: 'ok', data: 'deleted'),
        ),
      );

      await provider.loadFriends();
      final result = await provider.deleteFriend(200);

      expect(result, isTrue);
      expect(provider.friends.length, 1);
      expect(provider.friends.first.friendId, 300);
    });

    test('updateFriendRemark should replace matching friend dto', () async {
      final provider = FriendProvider(
        api: FakeFriendApi(
          getFriendsHandler: () async => ResponseDTO<List<FriendDTO>>(
            code: 200,
            message: 'ok',
            data: <FriendDTO>[
              FriendDTO(id: 1, userId: 100, friendId: 200, remark: 'Old note'),
            ],
          ),
          updateRemarkHandler: (int friendId, String remark) async =>
              ResponseDTO<FriendDTO>(
                code: 200,
                message: 'ok',
                data: FriendDTO(
                  id: 1,
                  userId: 100,
                  friendId: friendId,
                  remark: remark,
                ),
              ),
        ),
      );

      await provider.loadFriends();
      final result = await provider.updateFriendRemark(200, 'New note');

      expect(result, isTrue);
      expect(provider.friends.first.remark, 'New note');
    });
  });
}
