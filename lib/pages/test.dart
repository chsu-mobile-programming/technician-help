// lib/nearby_test_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/client.dart'; // <-- your uploaded file (Teacher / Technician / NearbyPayload)

enum NearbyRole { teacher, technician }

/// Test harness for the Teacher / Technician networking classes.
/// Push it anywhere:  Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyTestPage()));
class NearbyTestPage extends StatefulWidget {
  const NearbyTestPage({super.key});

  @override
  State<NearbyTestPage> createState() => _NearbyTestPageState();
}

class _NearbyTestPageState extends State<NearbyTestPage> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _listCtrl = ScrollController();

  NearbyRole _role = NearbyRole.teacher;
  Teacher? _teacher;
  Technician? _technician;

  bool _running = false;
  bool _busy = false;

  /// endpointId -> human name (from discovery / incoming payload 'from')
  final Map<String, String> _knownNames = {};

  /// currently connected peers, polled from the client classes
  Map<String, String> _peers = {};

  /// technician only: who the answer goes to
  String? _replyTo;

  final List<_Msg> _messages = [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = 'Node-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  @override
  void dispose() {
    _poll?.cancel();
    _shutdown(); // fire & forget, we are going away
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- lifecycle

  Future<void> _start() async {
    if (_running || _busy) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Give this device a name first.');
      return;
    }

    setState(() => _busy = true);

    if (!await _ensurePermissions()) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    try {
      if (_role == NearbyRole.teacher) {
        final teacher = Teacher(name: name);

        teacher.onTechnicianFound = (id, peerName) {
          if (!mounted) return;
          _knownNames[id] = peerName;
          _sys('Found technician "$peerName" ($id) — connecting…');
        };

        teacher.onTechnicianLost = (id) {
          if (!mounted) return;
          _sys('Technician "${_knownNames[id] ?? id}" lost');
          _refreshPeers();
        };

        teacher.onAnswerRecieved = (answer, fromId) {
          if (!mounted) return;
          final from = (answer['from'] as String?) ?? _knownNames[fromId] ?? fromId;
          setState(() {
            _knownNames[fromId] = from;
            _messages.add(_Msg(
              kind: _MsgKind.incoming,
              text: '${answer['text'] ?? answer}',
              from: from,
              peerId: fromId,
              raw: answer,
            ));
          });
          _refreshPeers();
          _scrollToEnd();
        };

        if (!await teacher.start()) {
          throw Exception('startDiscovery() returned false');
        }
        _teacher = teacher;
        _sys('Teacher "$name" is discovering…');
      } else {
        final tech = Technician(name: name);

        tech.onTicketRecieved = (ticket, fromId) {
          if (!mounted) return;
          final from = (ticket['from'] as String?) ?? _knownNames[fromId] ?? fromId;
          setState(() {
            _knownNames[fromId] = from;
            _replyTo = fromId; // answer the teacher that just wrote to us
            _messages.add(_Msg(
              kind: _MsgKind.incoming,
              text: '${ticket['text'] ?? ticket}',
              from: from,
              peerId: fromId,
              raw: ticket,
            ));
          });
          _refreshPeers();
          _scrollToEnd();
        };

        tech.onTeacherDisconnected = (id) {
          if (!mounted) return;
          _sys('Teacher "${_knownNames[id] ?? id}" disconnected');
          _refreshPeers();
        };

        if (!await tech.start()) {
          throw Exception('startAdvertising() returned false');
        }
        _technician = tech;
        _sys('Technician "$name" is advertising…');
      }

      // Neither class exposes an "onConnected" callback -> poll the peer maps.
      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refreshPeers());
      _refreshPeers();
      if (!mounted) return;
      setState(() => _running = true);
    } catch (e) {
      _sys('Start failed: $e');
      _snack('Start failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _shutdown();
    _sys('Stopped.');
    if (!mounted) return;
    setState(() {
      _running = false;
      _busy = false;
    });
  }

  Future<void> _shutdown() async {
    _poll?.cancel();
    _poll = null;
    try {
      await _teacher?.stop();
    } catch (e) {
      debugPrint('teacher.stop(): $e');
    }
    try {
      await _technician?.stop();
    } catch (e) {
      debugPrint('technician.stop(): $e');
    }
    _teacher = null;
    _technician = null;
    _peers = {};
    _replyTo = null;
  }

  /// The client classes have no connection callback, so mirror their maps here.
  void _refreshPeers() {
    if (!mounted) return;
    final raw = _role == NearbyRole.teacher
        ? (_teacher?.connectedTechnicians ?? const <String, String>{})
        : (_technician?.connectedTeachers ?? const <String, String>{});

    final next = <String, String>{
      for (final e in raw.entries) e.key: _knownNames[e.key] ?? e.value,
    };

    var reply = _replyTo;
    if (_role == NearbyRole.technician) {
      if (reply == null || !next.containsKey(reply)) {
        reply = next.isEmpty ? null : next.keys.first;
      }
    } else {
      reply = null;
    }

    if (mapEquals(next, _peers) && reply == _replyTo) return;
    setState(() {
      _peers = next;
      _replyTo = reply;
    });
  }

  // ------------------------------------------------------------------ sending

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || !_running || _busy) return;

    final payload = <String, dynamic>{
      'text': text,
      'sentAt': DateTime.now().toIso8601String(),
    };

    var delivered = false;
    var target = '';
    String? peerId;

    if (_role == NearbyRole.teacher) {
      final count = await _teacher?.sendTicket(payload) ?? 0;
      delivered = count > 0;
      target = count == 0 ? 'nobody — no technician connected' : '$count technician(s)';
    } else {
      peerId = _replyTo;
      if (peerId == null) {
        _snack('No connected teacher to answer to.');
        return;
      }
      delivered = await _technician?.sendAnswer(payload, toEndpointId: peerId) ?? false;
      target = _peers[peerId] ?? peerId;
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(
        kind: _MsgKind.outgoing,
        text: text,
        from: target,
        peerId: peerId,
        raw: payload,
        failed: !delivered,
      ));
      if (delivered) _msgCtrl.clear();
    });
    _scrollToEnd();
  }

  // -------------------------------------------------------------- permissions

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true; // Nearby Connections plugin is Android
    try {
      final statuses = await <Permission>[
        Permission.locationWhenInUse,
        Permission.bluetoothScan,       // Android 12+
        Permission.bluetoothAdvertise,  // Android 12+
        Permission.bluetoothConnect,    // Android 12+
        Permission.nearbyWifiDevices,   // Android 13+
      ].request();

      if (!(statuses[Permission.locationWhenInUse]?.isGranted ?? false)) {
        _snack('Location permission is required by Nearby Connections.');
        return false;
      }

      final blocked = statuses.entries
          .where((e) => e.value.isPermanentlyDenied)
          .map((e) => e.key.toString().split('.').last)
          .join(', ');
      if (blocked.isNotEmpty) {
        _sys('Permanently denied: $blocked — open app settings if peers never appear.');
      }

      final serviceOn =
          (await Permission.locationWhenInUse.serviceStatus) == ServiceStatus.enabled;
      if (!serviceOn) {
        _snack('Turn ON Location/GPS in system settings, otherwise discovery finds nothing.');
      }
      return true;
    } catch (e) {
      _sys('Permission request failed: $e');
      return true; // let the plugin try anyway
    }
  }

  // ------------------------------------------------------------------- helpers

  void _sys(String text) {
    if (!mounted) return;
    setState(() => _messages.add(_Msg(kind: _MsgKind.system, text: text)));
    _scrollToEnd();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listCtrl.hasClients) return;
      _listCtrl.animateTo(
        _listCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  String _hhmmss(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  void _showRaw(_Msg m) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Raw payload'),
        content: SingleChildScrollView(
          child: SelectableText(const JsonEncoder.withIndent('  ').convert(m.raw)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby test bench'),
        actions: [
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => setState(_messages.clear),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _config(theme),
            const Divider(height: 1),
            _peersBar(theme),
            const Divider(height: 1),
            Expanded(child: _messageList(theme)),
            _composer(theme),
          ],
        ),
      ),
    );
  }

  Widget _config(ThemeData theme) {
    final locked = _running || _busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<NearbyRole>(
            segments: const [
              ButtonSegment(
                value: NearbyRole.teacher,
                label: Text('Teacher'),
                icon: Icon(Icons.school_outlined),
              ),
              ButtonSegment(
                value: NearbyRole.technician,
                label: Text('Technician'),
                icon: Icon(Icons.build_outlined),
              ),
            ],
            selected: {_role},
            onSelectionChanged: locked
                ? null
                : (s) => setState(() {
                      _role = s.first;
                      _peers = {};
                      _replyTo = null;
                      _knownNames.clear();
                    }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  enabled: !locked,
                  decoration: const InputDecoration(
                    labelText: 'Device name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy ? null : (_running ? _stop : _start),
                icon: _busy
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_running ? Icons.stop : Icons.play_arrow),
                label: Text(_running ? 'Stop' : 'Start'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            !_running
                ? 'Stopped — Teacher discovers & broadcasts tickets, Technician advertises & answers.'
                : _role == NearbyRole.teacher
                    ? 'Discovering technicians… messages are broadcast to all connected peers.'
                    : 'Advertising… tap a teacher chip below to pick who receives your answer.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _peersBar(ThemeData theme) {
    final isTeacher = _role == NearbyRole.teacher;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(
            isTeacher
                ? 'Connected technicians (${_peers.length}) — broadcast'
                : 'Connected teachers (${_peers.length}) — tap to select reply target',
            style: theme.textTheme.labelMedium,
          ),
        ),
        SizedBox(
          height: 54,
          child: _peers.isEmpty
              ? Center(
                  child: Text(
                    _running ? 'Waiting for peers…' : 'Not running',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _peers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final id = _peers.keys.elementAt(i);
                    final name = _peers[id]!;
                    if (isTeacher) {
                      return Chip(
                        avatar: const Icon(Icons.circle, size: 10, color: Colors.green),
                        label: Text(name),
                      );
                    }
                    return ChoiceChip(
                      avatar: const Icon(Icons.circle, size: 10, color: Colors.green),
                      label: Text(name),
                      selected: _replyTo == id,
                      onSelected: (_) => setState(() => _replyTo = id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _messageList(ThemeData theme) {
    if (_messages.isEmpty) {
      return Center(
        child: Text('No messages yet',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
      );
    }
    return ListView.builder(
      controller: _listCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i], theme),
    );
  }

  Widget _bubble(_Msg m, ThemeData theme) {
    final cs = theme.colorScheme;

    if (m.kind == _MsgKind.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        child: Text(
          '${_hhmmss(m.time)}  •  ${m.text}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
        ),
      );
    }

    final out = m.kind == _MsgKind.outgoing;
    return Align(
      alignment: out ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: m.raw == null ? null : () => _showRaw(m),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: m.failed
                ? cs.errorContainer
                : out
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                out ? '→ ${m.from ?? ''}' : (m.from ?? m.peerId ?? '?'),
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(m.text, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '${_hhmmss(m.time)}'
                '${m.peerId != null ? '  •  ${m.peerId}' : ''}'
                '${m.failed ? '  •  NOT DELIVERED' : ''}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: m.failed ? cs.error : cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(ThemeData theme) {
    final isTeacher = _role == NearbyRole.teacher;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              enabled: _running,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: isTeacher
                    ? 'Ticket message (to all technicians)'
                    : 'Answer to ${_replyTo == null ? '—' : (_peers[_replyTo] ?? _replyTo)}',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _running ? _send : null,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- models

enum _MsgKind { incoming, outgoing, system }

class _Msg {
  _Msg({
    required this.kind,
    required this.text,
    this.from,
    this.peerId,
    this.raw,
    this.failed = false,
  }) : time = DateTime.now();

  final _MsgKind kind;
  final String text;
  final String? from;
  final String? peerId;
  final Map<String, dynamic>? raw;
  final bool failed;
  final DateTime time;
}