import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/request_thread.dart';
import '../models/request_message.dart';

class RequestThreadProvider with ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  final Map<String, List<RequestMessage>> _messagesByThread = {};
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Timer> _pollers = {};
  bool _isSending = false;

  bool get isSending => _isSending;
  List<RequestMessage> messages(String threadId) => _messagesByThread[threadId] ?? const [];

  Future<RequestThread> openOrCreateThread({
    required String toolId,
    required String ownerId,
    required String requesterId,
  }) async {
    // Reuse open thread if exists
    final existing = await _client
        .from('request_threads')
        .select()
        .eq('tool_id', toolId)
        .eq('owner_id', ownerId)
        .eq('requester_id', requesterId)
        .eq('status', 'open')
        .maybeSingle();

    final threadMap = existing ?? await _client
        .from('request_threads')
        .insert({
          'tool_id': toolId,
          'owner_id': ownerId,
          'requester_id': requesterId,
          'status': 'open',
        })
        .select()
        .single();

    final thread = RequestThread.fromMap(threadMap);
    await _subscribeToThread(thread.id);
    await loadMessages(thread.id);
    return thread;
  }

  Future<void> loadMessages(String threadId) async {
    final res = await _client
        .from('request_messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at');
    _messagesByThread[threadId] = (res as List).map((e) => RequestMessage.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> sendMessage({required String threadId, required String senderId, required String text}) async {
    if (text.trim().isEmpty) return;
    _isSending = true;
    notifyListeners();
    try {
      final map = await _client
          .from('request_messages')
          .insert({
            'thread_id': threadId,
            'sender_id': senderId,
            'text': text.trim(),
            'is_system': false,
          })
          .select()
          .single();
      final msg = RequestMessage.fromMap(map);
      _messagesByThread.putIfAbsent(threadId, () => []);
      _messagesByThread[threadId]!.add(msg);
      notifyListeners();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeToThread(String threadId) async {
    if (_channels.containsKey(threadId)) return;
    final channel = _client.channel('rq_thread_$threadId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'request_messages',
      callback: (payload) {
        final row = payload.newRecord;
        if (row['thread_id'] == threadId) {
          final msg = RequestMessage.fromMap(row);
          _messagesByThread.putIfAbsent(threadId, () => []);
          _messagesByThread[threadId]!.add(msg);
          notifyListeners();
        }
      },
    );
    channel.subscribe();
    _channels[threadId] = channel;

    // Fallback polling for projects without realtime publication on free tier
    _pollers[threadId]?.cancel();
    _pollers[threadId] = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        await loadMessages(threadId);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    for (final c in _channels.values) {
      c.unsubscribe();
    }
    for (final t in _pollers.values) {
      t.cancel();
    }
    super.dispose();
  }
}


