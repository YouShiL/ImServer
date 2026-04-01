import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/models/file_upload_result_dto.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/models/group_join_request_dto.dart';
import 'package:hailiao_flutter/models/group_member_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/register_request_dto.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/models/user_session_dto.dart';

void main() {
  group('UserDTO', () {
    test('fromJson should parse privacy and status fields', () {
      final user = UserDTO.fromJson(<String, dynamic>{
        'id': 1,
        'userId': '10001',
        'phone': '13800138000',
        'nickname': 'Alice',
        'onlineStatus': 1,
        'deviceLock': true,
        'showOnlineStatus': false,
        'showLastOnline': true,
        'allowSearchByPhone': false,
        'needFriendVerification': true,
        'status': 1,
      });

      expect(user.id, 1);
      expect(user.userId, '10001');
      expect(user.nickname, 'Alice');
      expect(user.onlineStatus, 1);
      expect(user.deviceLock, isTrue);
      expect(user.showOnlineStatus, isFalse);
      expect(user.showLastOnline, isTrue);
      expect(user.allowSearchByPhone, isFalse);
      expect(user.needFriendVerification, isTrue);
      expect(user.status, 1);
    });
  });

  group('MessageDTO', () {
    test('fromJson should parse nested fromUserInfo', () {
      final message = MessageDTO.fromJson(<String, dynamic>{
        'id': 11,
        'msgId': 'msg-11',
        'fromUserId': 1,
        'toUserId': 2,
        'content': 'hello',
        'msgType': 1,
        'isRead': true,
        'isRecalled': false,
        'isEdited': false,
        'replyToMsgId': 7,
        'forwardFromMsgId': 6,
        'forwardFromUserId': 5,
        'status': 1,
        'createdAt': '2026-03-31T10:00:00',
        'fromUserInfo': <String, dynamic>{
          'id': 1,
          'userId': '10001',
          'nickname': 'Alice',
        },
      });

      expect(message.id, 11);
      expect(message.msgId, 'msg-11');
      expect(message.content, 'hello');
      expect(message.replyToMsgId, 7);
      expect(message.forwardFromMsgId, 6);
      expect(message.forwardFromUserId, 5);
      expect(message.fromUserInfo, isNotNull);
      expect(message.fromUserInfo!.nickname, 'Alice');
    });

    test('copyWith should only replace provided mutable fields', () {
      final original = MessageDTO(
        id: 1,
        msgId: 'msg-1',
        fromUserId: 1,
        toUserId: 2,
        content: 'before',
        msgType: 1,
        isRecalled: false,
        isEdited: false,
        status: 1,
      );

      final updated = original.copyWith(
        content: 'after',
        isRecalled: true,
      );

      expect(updated.id, 1);
      expect(updated.msgId, 'msg-1');
      expect(updated.content, 'after');
      expect(updated.isRecalled, isTrue);
      expect(updated.isEdited, isFalse);
    });
  });

  group('ConversationDTO', () {
    test('toJson should keep draft and mute metadata', () {
      final dto = ConversationDTO(
        id: 2,
        userId: 10,
        targetId: 20,
        type: 1,
        name: 'Bob',
        lastMessage: 'latest',
        unreadCount: 3,
        isTop: true,
        isMute: false,
        draft: 'draft text',
        isDeleted: false,
      );

      final json = dto.toJson();

      expect(json['id'], 2);
      expect(json['targetId'], 20);
      expect(json['name'], 'Bob');
      expect(json['draft'], 'draft text');
      expect(json['isTop'], isTrue);
      expect(json['isMute'], isFalse);
    });
  });

  group('GroupDTO', () {
    test('fromJson should parse invite and join rule fields', () {
      final group = GroupDTO.fromJson(<String, dynamic>{
        'id': 9,
        'groupId': '8888888888',
        'groupName': 'Test Group',
        'ownerId': 1,
        'memberCount': 50,
        'maxMembers': 500,
        'needVerify': true,
        'allowMemberInvite': false,
        'joinType': 1,
        'isMute': true,
        'status': 1,
      });

      expect(group.id, 9);
      expect(group.groupId, '8888888888');
      expect(group.groupName, 'Test Group');
      expect(group.memberCount, 50);
      expect(group.maxMembers, 500);
      expect(group.needVerify, isTrue);
      expect(group.allowMemberInvite, isFalse);
      expect(group.joinType, 1);
      expect(group.isMute, isTrue);
      expect(group.status, 1);
    });
  });

  group('GroupMemberDTO', () {
    test('fromJson should parse member role and nested user info', () {
      final member = GroupMemberDTO.fromJson(<String, dynamic>{
        'id': 3,
        'groupId': 9,
        'userId': 100,
        'nickname': '管理员',
        'role': 2,
        'isMute': false,
        'joinedAt': '2026-03-31T10:00:00',
        'userInfo': <String, dynamic>{
          'id': 100,
          'userId': '100100',
          'nickname': '管理员',
        },
      });

      expect(member.id, 3);
      expect(member.groupId, 9);
      expect(member.userId, 100);
      expect(member.role, 2);
      expect(member.isMute, isFalse);
      expect(member.userInfo, isNotNull);
      expect(member.userInfo!.userId, '100100');
    });
  });

  group('GroupJoinRequestDTO', () {
    test('fromJson should parse nested user and group info', () {
      final request = GroupJoinRequestDTO.fromJson(<String, dynamic>{
        'id': 8,
        'groupId': 9,
        'userId': 100,
        'message': '想加入群聊',
        'status': 0,
        'handledBy': 1,
        'handledAt': '2026-03-31T11:00:00',
        'createdAt': '2026-03-31T10:00:00',
        'userInfo': <String, dynamic>{
          'id': 100,
          'userId': '100100',
          'nickname': 'Alice',
        },
        'groupInfo': <String, dynamic>{
          'id': 9,
          'groupId': '8888888888',
          'groupName': '测试群',
          'allowMemberInvite': true,
          'joinType': 1,
        },
      });

      expect(request.id, 8);
      expect(request.groupId, 9);
      expect(request.userId, 100);
      expect(request.message, '想加入群聊');
      expect(request.status, 0);
      expect(request.userInfo, isNotNull);
      expect(request.userInfo!.nickname, 'Alice');
      expect(request.groupInfo, isNotNull);
      expect(request.groupInfo!.groupName, '测试群');
    });
  });

  group('UserSessionDTO', () {
    test('fromJson should parse device session metadata', () {
      final session = UserSessionDTO.fromJson(<String, dynamic>{
        'sessionId': 'session-1',
        'deviceId': 'device-1',
        'deviceName': 'iPhone 16',
        'deviceType': 'ios',
        'loginIp': '127.0.0.1',
        'active': true,
        'currentSession': true,
        'createdAt': '2026-03-31T09:00:00',
        'lastActiveAt': '2026-03-31T10:00:00',
      });

      expect(session.sessionId, 'session-1');
      expect(session.deviceId, 'device-1');
      expect(session.deviceName, 'iPhone 16');
      expect(session.deviceType, 'ios');
      expect(session.loginIp, '127.0.0.1');
      expect(session.active, isTrue);
      expect(session.currentSession, isTrue);
    });
  });

  group('FileUploadResultDTO', () {
    test('toJson should keep upload metadata', () {
      final dto = FileUploadResultDTO(
        filename: 'file.png',
        originalFilename: 'origin.png',
        fileUrl: 'https://cdn.example.com/file.png',
        filePath: 'hailiao/image/1/file.png',
        fileSize: 1024,
        mimeType: 'image/png',
        extension: 'png',
        uploadTime: '2026-03-31T12:00:00',
      );

      final json = dto.toJson();

      expect(json['filename'], 'file.png');
      expect(json['originalFilename'], 'origin.png');
      expect(json['fileUrl'], 'https://cdn.example.com/file.png');
      expect(json['fileSize'], 1024);
      expect(json['mimeType'], 'image/png');
      expect(json['extension'], 'png');
    });
  });

  group('FriendDTO', () {
    test('fromJson should parse nested friend user info', () {
      final dto = FriendDTO.fromJson(<String, dynamic>{
        'id': 1,
        'userId': 100,
        'friendId': 200,
        'remark': '老同学',
        'groupName': '默认分组',
        'status': 1,
        'friendUserInfo': <String, dynamic>{
          'id': 200,
          'userId': '100200',
          'nickname': 'Bob',
        },
      });

      expect(dto.id, 1);
      expect(dto.userId, 100);
      expect(dto.friendId, 200);
      expect(dto.remark, '老同学');
      expect(dto.friendUserInfo, isNotNull);
      expect(dto.friendUserInfo!.nickname, 'Bob');
    });
  });

  group('FriendRequestDTO', () {
    test('fromJson should parse both request users', () {
      final dto = FriendRequestDTO.fromJson(<String, dynamic>{
        'id': 7,
        'fromUserId': 100,
        'toUserId': 200,
        'remark': '备注',
        'message': '加个好友',
        'status': 0,
        'fromUserInfo': <String, dynamic>{
          'id': 100,
          'userId': '100100',
          'nickname': 'Alice',
        },
        'toUserInfo': <String, dynamic>{
          'id': 200,
          'userId': '100200',
          'nickname': 'Bob',
        },
      });

      expect(dto.id, 7);
      expect(dto.fromUserId, 100);
      expect(dto.toUserId, 200);
      expect(dto.message, '加个好友');
      expect(dto.fromUserInfo, isNotNull);
      expect(dto.fromUserInfo!.nickname, 'Alice');
      expect(dto.toUserInfo, isNotNull);
      expect(dto.toUserInfo!.nickname, 'Bob');
    });
  });

  group('BlacklistDTO', () {
    test('toJson should keep blocked user metadata', () {
      final dto = BlacklistDTO(
        id: 9,
        userId: 100,
        blockedUserId: 200,
        createdAt: '2026-03-31T12:00:00',
        blockedUserInfo: UserDTO(
          id: 200,
          userId: '100200',
          nickname: 'Bob',
        ),
      );

      final json = dto.toJson();

      expect(json['id'], 9);
      expect(json['userId'], 100);
      expect(json['blockedUserId'], 200);
      expect(json['blockedUserInfo'], isNotNull);
    });
  });

  group('ReportDTO', () {
    test('fromJson should parse target and status labels', () {
      final dto = ReportDTO.fromJson(<String, dynamic>{
        'id': 3,
        'reporterId': 100,
        'targetId': 200,
        'targetType': 2,
        'targetTypeLabel': '群组',
        'reason': '违规内容',
        'evidence': '截图',
        'status': 1,
        'statusLabel': '已处理',
        'handlerId': 1,
        'handleResult': '已封禁',
      });

      expect(dto.id, 3);
      expect(dto.targetType, 2);
      expect(dto.targetTypeLabel, '群组');
      expect(dto.status, 1);
      expect(dto.statusLabel, '已处理');
      expect(dto.handleResult, '已封禁');
    });
  });

  group('ContentAuditDTO', () {
    test('fromJson should parse audit labels and final result', () {
      final dto = ContentAuditDTO.fromJson(<String, dynamic>{
        'id': 5,
        'contentType': 2,
        'contentTypeLabel': '图片',
        'targetId': 88,
        'content': 'https://cdn.example.com/a.png',
        'userId': 100,
        'aiResult': 1,
        'aiResultLabel': '疑似违规',
        'aiScore': 92,
        'manualResult': 2,
        'manualResultLabel': '驳回',
        'handlerId': 1,
        'handleNote': '误判',
        'status': 1,
        'statusLabel': '已审核',
        'finalResultLabel': '人工驳回',
      });

      expect(dto.id, 5);
      expect(dto.contentTypeLabel, '图片');
      expect(dto.aiResultLabel, '疑似违规');
      expect(dto.manualResultLabel, '驳回');
      expect(dto.statusLabel, '已审核');
      expect(dto.finalResultLabel, '人工驳回');
    });
  });

  group('ResponseDTO', () {
    test('fromJson should support generic payload parsing', () {
      final response = ResponseDTO<UserDTO>.fromJson(
        <String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'id': 1,
            'userId': '10001',
            'nickname': 'Alice',
          },
        },
        (Object? json) => UserDTO.fromJson(json! as Map<String, dynamic>),
      );

      expect(response.code, 200);
      expect(response.message, 'ok');
      expect(response.isSuccess, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.nickname, 'Alice');
    });

    test('fromJson should support list payload parsing', () {
      final response = ResponseDTO<List<UserDTO>>.fromJson(
        <String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'userId': '10001', 'nickname': 'Alice'},
            <String, dynamic>{'id': 2, 'userId': '10002', 'nickname': 'Bob'},
          ],
        },
        (Object? json) => (json! as List<dynamic>)
            .map((dynamic item) => UserDTO.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      expect(response.isSuccess, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.length, 2);
      expect(response.data!.first.nickname, 'Alice');
      expect(response.data!.last.nickname, 'Bob');
    });
  });

  group('AuthResponseDTO', () {
    test('fromJson should parse login notice and session metadata', () {
      final response = AuthResponseDTO.fromJson(<String, dynamic>{
        'user': <String, dynamic>{
          'id': 2,
          'userId': '10002',
          'nickname': 'Bob',
          'deviceLock': true,
        },
        'token': 'token-123',
        'sessionId': 'session-abc',
        'loginNotice': '异地登录提醒',
        'deviceLock': true,
      });

      expect(response.token, 'token-123');
      expect(response.sessionId, 'session-abc');
      expect(response.loginNotice, '异地登录提醒');
      expect(response.deviceLock, isTrue);
      expect(response.user.nickname, 'Bob');
      expect(response.user.deviceLock, isTrue);
    });

    test('toJson should keep token and session metadata', () {
      final response = AuthResponseDTO(
        user: UserDTO(
          id: 2,
          userId: '10002',
          nickname: 'Bob',
        ),
        token: 'token-123',
        sessionId: 'session-abc',
        loginNotice: 'notice',
        deviceLock: true,
      );

      final json = response.toJson();

      expect(json['token'], 'token-123');
      expect(json['sessionId'], 'session-abc');
      expect(json['loginNotice'], 'notice');
      expect(json['deviceLock'], isTrue);
      expect(json['user'], isNotNull);
    });
  });

  group('LoginRequestDTO', () {
    test('fromJson should parse replacement flag and device metadata', () {
      final dto = LoginRequestDTO.fromJson(<String, dynamic>{
        'phone': '13800138000',
        'password': '123456',
        'deviceId': 'device-1',
        'deviceName': 'iPhone 16',
        'deviceType': 'ios',
        'replaceExistingSession': true,
      });

      expect(dto.phone, '13800138000');
      expect(dto.password, '123456');
      expect(dto.deviceId, 'device-1');
      expect(dto.deviceName, 'iPhone 16');
      expect(dto.deviceType, 'ios');
      expect(dto.replaceExistingSession, isTrue);
    });

    test('toJson should include device replacement intent', () {
      final dto = LoginRequestDTO(
        phone: '13800138000',
        password: '123456',
        deviceId: 'device-1',
        deviceName: 'iPhone 16',
        deviceType: 'ios',
        replaceExistingSession: true,
      );

      final json = dto.toJson();

      expect(json['phone'], '13800138000');
      expect(json['password'], '123456');
      expect(json['deviceId'], 'device-1');
      expect(json['deviceName'], 'iPhone 16');
      expect(json['deviceType'], 'ios');
      expect(json['replaceExistingSession'], isTrue);
    });
  });

  group('RegisterRequestDTO', () {
    test('fromJson should parse nickname and credentials', () {
      final dto = RegisterRequestDTO.fromJson(<String, dynamic>{
        'phone': '13800138000',
        'password': '123456',
        'nickname': 'Alice',
      });

      expect(dto.phone, '13800138000');
      expect(dto.password, '123456');
      expect(dto.nickname, 'Alice');
    });

    test('toJson should keep nickname and credentials', () {
      final dto = RegisterRequestDTO(
        phone: '13800138000',
        password: '123456',
        nickname: 'Alice',
      );

      final json = dto.toJson();

      expect(json['phone'], '13800138000');
      expect(json['password'], '123456');
      expect(json['nickname'], 'Alice');
    });
  });

  group('EmojiList', () {
    test('replacePlaceholders should replace known placeholders with emoji code', () {
      final firstEmoji = EmojiList.emojis.first;
      final text = 'Hello ${firstEmoji.placeholder}';

      final replaced = EmojiList.replacePlaceholders(text);

      expect(replaced, 'Hello ${firstEmoji.code}');
    });

    test('replaceEmojisWithPlaceholders should restore placeholder text', () {
      final firstEmoji = EmojiList.emojis.first;
      final text = 'Hello ${firstEmoji.code}';

      final replaced = EmojiList.replaceEmojisWithPlaceholders(text);

      expect(replaced, 'Hello ${firstEmoji.placeholder}');
    });
  });
}
