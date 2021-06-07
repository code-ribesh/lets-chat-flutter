import 'package:letschat/data/datasources/data_source_contract.dart';
import 'package:letschat/models/Local_Message.dart';
import 'package:letschat/models/Chat.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class SqfliteDatasource implements IDatasource {
  final Database _db;

  const SqfliteDatasource(this._db);

  @override
  Future<void> addChat(Chat chat) async {
    await _db.insert('chats', chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addMessage(LocalMessage message) async {
    await _db.insert('messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final batch = _db.batch();
    batch.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
    batch.delete('chats', where: 'id = ?', whereArgs: [chatId]);
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Chat>> findAllChats() {
    return _db.transaction((txn) async {
      final chatsWithLatestMessage =
          await txn.rawQuery('''  SELECT messages.* FROM 
        (SELECT 
          chat_id, MAX(created_at) AS created_at
          FROM messages
          GROUP BY chat_id
        ) AS lastest_messages
        INNER JOIN messages
        ON messages.chat_id = lastest_messages.chat_id
        AND messages.created_at = lastest_messages.created_at           
        ''');

      if (chatsWithLatestMessage.isEmpty) return [];

      final chatsWithUnreadMessages =
          await txn.rawQuery(''' SELECT chat_id, count(*) as unread 
          FROM Messages
          WHERE receipt = ?
          GROUP BY chat_id
           ''', ['deleivered']);

      return chatsWithLatestMessage.map<Chat>((row) {
        final int unread = int.tryParse(chatsWithUnreadMessages.firstWhere(
            (element) => row['chat_id'] == element['chat_id'],
            orElse: () => {'unread': 0})['unread']);
        final chat = Chat.fromMap(row);

        chat.unread = unread;
        chat.mostRecent = LocalMessage.fromMap(row);
        return chat;
      }).toList();
    });
  }

  @override
  Future<Chat> findChat(String chatId) async {
    return await _db.transaction((txn) async {
      final listOfChatMaps =
          await txn.query('chats', where: 'id = ?', whereArgs: [chatId]);

      if (listOfChatMaps.isEmpty) return null;

      final unread = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM MESSAGES WHERE chat_id = ? AND receipt = ? ',
          [chatId, 'deleivered']));
      final mostRecentMessage = await txn.query('messages',
          where: 'chat_id = ?',
          whereArgs: [chatId],
          orderBy: 'created_at DESC',
          limit: 1);
      final chat = Chat.fromMap(listOfChatMaps.first);
      chat.unread = unread;
      chat.mostRecent = LocalMessage.fromMap(mostRecentMessage.first);
      return chat;
    });
  }

  @override
  Future<List<LocalMessage>> findMessages(String chatId) async {
    final listOfMaps = await _db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    return listOfMaps
        .map<LocalMessage>((map) => LocalMessage.fromMap(map))
        .toList();
  }

  @override
  Future<void> updateMessage(LocalMessage message) async {
    await _db.update('messages', message.toMap(),
        where: 'id = ?',
        whereArgs: [message.message.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
