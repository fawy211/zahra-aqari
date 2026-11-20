import 'package:supabase_flutter/supabase_flutter.dart';

/// A chat room as the chat list shows it.
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.title,
    required this.lastMessage,
    this.updatedAt,
  });

  /// Primary key of the row in the chats table.
  final String chatId;

  /// Name shown for the room, taken from the property the room belongs to.
  final String title;

  /// Content of the newest message in the room, empty when the room is new.
  final String lastMessage;

  /// Value of chats.updated_at, used to order the list.
  final DateTime? updatedAt;
}

/// Reads and writes the chat tables that the Supabase project really has.
///
/// The project has no participant, last-message, or timestamp-alias columns.
/// A room belongs to one property, and a message belongs to one room:
///
///   chats(id, property_id, created_at, updated_at)
///   messages(id, chat_id, sender_id, content, created_at)
class ChatService {
  ChatService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Returns the chats.id of the room for [propertyId] and creates the room
  /// when the property has none yet.
  Future<String> openChatForProperty(String propertyId) async {
    final existing = await _supabase
        .from('chats')
        .select('id')
        .eq('property_id', propertyId)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final created = await _supabase
        .from('chats')
        .insert({'property_id': propertyId})
        .select('id')
        .single();

    return created['id'] as String;
  }

  /// Writes [content] into room [chatId] as [senderId], then records the new
  /// room activity time in chats.updated_at.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
    });

    await _supabase.from('chats').update({
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', chatId);
  }

  /// The rooms [userId] takes part in, newest activity first.
  Future<List<ChatSummary>> chatsForUser(String userId) async {
    // chats has no participant column, so membership comes from two real
    // sources: the user owns the property of the room, or the user sent a
    // message in the room.
    final sentRows = await _supabase
        .from('messages')
        .select('chat_id')
        .eq('sender_id', userId);
    final sentChatIds =
        sentRows.map((row) => row['chat_id']).whereType<String>().toSet();

    final chatRows = await _supabase
        .from('chats')
        .select('id, property_id, created_at, updated_at');

    final propertyIds = chatRows
        .map((row) => row['property_id'])
        .whereType<String>()
        .toSet()
        .toList();
    final propertyRows = propertyIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _supabase
            .from('properties')
            .select('id, title, owner_id')
            .inFilter('id', propertyIds);
    final propertiesById = {
      for (final row in propertyRows) row['id'] as String: row,
    };

    final myChats = chatRows
        .where(
            (chat) => isChatOfUser(chat, propertiesById, sentChatIds, userId))
        .toList();
    final myChatIds = myChats.map((chat) => chat['id'] as String).toList();
    if (myChatIds.isEmpty) return [];

    final messageRows = await _supabase
        .from('messages')
        .select('chat_id, content, created_at')
        .inFilter('chat_id', myChatIds)
        .order('created_at', ascending: false);
    final lastMessageByChat = newestMessageByChat(messageRows);

    final summaries = myChats.map((chat) {
      final chatId = chat['id'] as String;
      final property = propertiesById[chat['property_id']];
      return ChatSummary(
        chatId: chatId,
        title: property?['title']?.toString() ?? 'محادثة',
        lastMessage: lastMessageByChat[chatId]?['content']?.toString() ?? '',
        updatedAt: DateTime.tryParse(chat['updated_at']?.toString() ?? ''),
      );
    }).toList()
      ..sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return summaries;
  }

  /// True when [chat] belongs to [userId]: the user owns the property of the
  /// room, or one of the user's messages is in the room.
  static bool isChatOfUser(
    Map<String, dynamic> chat,
    Map<String, Map<String, dynamic>> propertiesById,
    Set<String> sentChatIds,
    String userId,
  ) {
    if (sentChatIds.contains(chat['id'])) return true;

    final property = propertiesById[chat['property_id']];
    return property != null && property['owner_id'] == userId;
  }

  /// Keeps the newest row for each chat from rows ordered newest first.
  static Map<String, Map<String, dynamic>> newestMessageByChat(
    List<Map<String, dynamic>> rowsNewestFirst,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final row in rowsNewestFirst) {
      final chatId = row['chat_id'];
      if (chatId is String) result.putIfAbsent(chatId, () => row);
    }
    return result;
  }
}
