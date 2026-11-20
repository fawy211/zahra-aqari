import 'package:aqari_app/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ownerId = 'owner-1';
  const buyerId = 'buyer-1';

  final propertiesById = <String, Map<String, dynamic>>{
    'property-1': {'id': 'property-1', 'owner_id': ownerId, 'title': 'عقار'},
  };

  group('ChatService.isChatOfUser', () {
    test('keeps a chat on a property the user owns', () {
      final chat = {'id': 'chat-1', 'property_id': 'property-1'};

      expect(
        ChatService.isChatOfUser(chat, propertiesById, <String>{}, ownerId),
        isTrue,
      );
    });

    test('keeps a chat that holds a message the user sent', () {
      final chat = {'id': 'chat-1', 'property_id': 'property-1'};

      expect(
        ChatService.isChatOfUser(
          chat,
          propertiesById,
          <String>{'chat-1'},
          buyerId,
        ),
        isTrue,
      );
    });

    test('drops a chat on another owner property with no message from the user',
        () {
      final chat = {'id': 'chat-2', 'property_id': 'property-1'};

      expect(
        ChatService.isChatOfUser(chat, propertiesById, <String>{}, buyerId),
        isFalse,
      );
    });

    test('drops a chat whose property is unknown', () {
      final chat = {'id': 'chat-3', 'property_id': null};

      expect(
        ChatService.isChatOfUser(chat, propertiesById, <String>{}, buyerId),
        isFalse,
      );
    });
  });

  group('ChatService.newestMessageByChat', () {
    test('keeps the newest row of each chat', () {
      final rows = <Map<String, dynamic>>[
        {'chat_id': 'chat-1', 'content': 'newest', 'created_at': '2026-11-09'},
        {'chat_id': 'chat-2', 'content': 'other', 'created_at': '2026-11-08'},
        {'chat_id': 'chat-1', 'content': 'older', 'created_at': '2026-11-07'},
      ];

      final newest = ChatService.newestMessageByChat(rows);

      expect(newest['chat-1']!['content'], 'newest');
      expect(newest['chat-2']!['content'], 'other');
      expect(newest.length, 2);
    });

    test('returns nothing for no rows', () {
      expect(
          ChatService.newestMessageByChat(<Map<String, dynamic>>[]), isEmpty);
    });
  });
}
