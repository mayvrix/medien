// lib/screens/groups/group_message_page.dart
// ─────────────────────────────────────────────────────────────────────────────
// GroupMessagePage
// - Full-featured group chat page with text + doodle messages, sender name
//   labels on every message, date headers, time overlay, delete, copy,
//   live doodle preview, auto-scroll, group info sheet, etc.
// - Integrates with your GroupChatService (unchanged createGroup()).
// - Styling follows your app conventions (S size helper, appColors, POP font).
//
// NOTE: Adjust asset paths / user fields ("name", "profile", "photoUrl")
//       according to your Firestore schema if needed.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';

import 'package:medien/core/size.dart';
import 'package:medien/core/theme_colors.dart';
import 'package:medien/services/auth/auth_service.dart';
import 'package:medien/services/chats/group_chat_service.dart';
import 'package:medien/widgets/doodle_dialogs.dart';


// ─────────────────────────────────────────────────────────────────────────────
// SECTION: Small data helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight representation of a user for labels & avatars in chat.
class DisplayUser {
  final String uid;
  final String name;
  final int? profileIndex; // local asset like assets/image/pf{n}.png
  final String? photoUrl;  // remote photo if you have one

  const DisplayUser({
    required this.uid,
    required this.name,
    this.profileIndex,
    this.photoUrl,
  });
}

/// Message type discriminator used in UI (maps to "type" field in Firestore).
enum GroupMessageType { text, doodle, unknown }

extension on GroupMessageType {
  static GroupMessageType fromString(String? v) {
    switch (v) {
      case 'text':
        return GroupMessageType.text;
      case 'doodle':
        return GroupMessageType.doodle;
      default:
        return GroupMessageType.unknown;
    }
  }
}

/// Simple LRU-ish in-memory cache for user briefs (keeps things smooth)
class _UserBriefCache {
  final int maxEntries;
  final _map = <String, DisplayUser>{};
  final _queue = <String>[];

  _UserBriefCache({this.maxEntries = 100});

  DisplayUser? get(String uid) {
    final u = _map[uid];
    if (u != null) {
      _touch(uid);
    }
    return u;
  }

  void put(DisplayUser user) {
    _map[user.uid] = user;
    _touch(user.uid);
    _evictIfNeeded();
  }

  void _touch(String uid) {
    _queue.remove(uid);
    _queue.add(uid);
  }

  void _evictIfNeeded() {
    while (_queue.length > maxEntries) {
      final oldest = _queue.removeAt(0);
      _map.remove(oldest);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: User directory (fetch members / names / photos)
// ─────────────────────────────────────────────────────────────────────────────

class GroupUserDirectory {
  final FirebaseFirestore _firestore;
  GroupUserDirectory(this._firestore);

  /// Fetch one user brief from "Users/{uid}" and map to DisplayUser.
  Future<DisplayUser?> fetchUserBrief(String uid) async {
    try {
      final snap = await _firestore.collection('Users').doc(uid).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      final name = (data['name'] ?? data['username'] ?? data['email'] ?? 'User') as String;
      final profileIndex = (data['profileNumber'] is num) ? (data['profileNumber'] as num).toInt() : null;
      final photo = data['photoUrl'] as String?;
      return DisplayUser(uid: uid, name: name, profileIndex: profileIndex, photoUrl: photo);
    } catch (_) {
      return null;
    }
  }

  /// Load brief info for all group members (best-effort, non-fatal).
  Future<Map<String, DisplayUser>> loadMembersBriefs(List<String> memberIds) async {
    final out = <String, DisplayUser>{};
    for (final uid in memberIds) {
      final u = await fetchUserBrief(uid);
      if (u != null) out[uid] = u;
    }
    return out;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: GroupMessagePage
// ─────────────────────────────────────────────────────────────────────────────

class GroupMessagePage extends StatefulWidget {
  final String groupId;
  final String groupName;

  /// Optional: provide memberIds if you already have them; otherwise they’re
  /// read from the group doc for the info sheet.
  final List<String>? memberIds;

  const GroupMessagePage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.memberIds,
  });

  @override
  State<GroupMessagePage> createState() => _GroupMessagePageState();
}

class _GroupMessagePageState extends State<GroupMessagePage> {
  // Services
  final _authService = AuthService();
  final _groupService = GroupChatService();
  final _firestore = FirebaseFirestore.instance;
  late final GroupUserDirectory _directory;

  // Input + scroll
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _msgFocus = FocusNode();

  // Formatting (doodle)
  bool _showFormattingOptions = false;
  String _selectedFont = "POP";
  double _selectedFontSize = 28.0;
  String _selectedColor = "#000000";

  // UI state
  String get _currentUid => _authService.getCurrentUser()!.uid;
  bool _isAdmin = false;
  String? _adminId;
  List<String> _members = [];

  // Name/time overlays
  final Set<String> _timeVisible = {};
  final _userCache = _UserBriefCache(maxEntries: 150);

  // Scroll-to-bottom affordance
  bool _showJumpToBottom = false;
  StreamSubscription<QuerySnapshot>? _messageStreamSub;

  // ───────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _directory = GroupUserDirectory(_firestore);
    _bindGroupMeta();
    _listenMessagesForAutoScroll();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void dispose() {
    _msgFocus.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _messageStreamSub?.cancel();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Group meta (admin / members)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _bindGroupMeta() async {
    final docRef = _firestore.collection('groups').doc(widget.groupId);
    docRef.snapshots().listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data()!;
      _adminId = data['adminId'] as String?;
      final members = (data['members'] as List?)?.cast<String>() ?? <String>[];
      setState(() {
        _members = members;
        _isAdmin = (_adminId == _currentUid);
      });
      // Prime user cache with member briefs (non-blocking)
      unawaited(_primeMembersCache(members));
    });
  }

  Future<void> _primeMembersCache(List<String> uids) async {
    final fetched = await _directory.loadMembersBriefs(uids);
    for (final u in fetched.values) {
      _userCache.put(u);
    }
    if (mounted) setState(() {});
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Message stream + auto-scroll behavior
  // ───────────────────────────────────────────────────────────────────────────

  void _listenMessagesForAutoScroll() {
    _messageStreamSub = _groupService.getMessages(widget.groupId).listen((_) {
      // If user is near the bottom, auto-jump when new messages arrive.
      if (_isNearBottom()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
      } else {
        // Show "jump to bottom" button when new content out of view
        if (mounted) {
          setState(() => _showJumpToBottom = true);
        }
      }
    });
  }

  void _onScroll() {
    final shouldShow = !_isNearBottom();
    if (shouldShow != _showJumpToBottom && mounted) {
      setState(() => _showJumpToBottom = shouldShow);
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) < 120;
    // threshold tweakable
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _animateToBottom() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Send handlers
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_showFormattingOptions) {
      await _groupService.sendDoodleMessage(
        groupId: widget.groupId,
        text: text,
        font: _selectedFont,
        fontSize: _selectedFontSize,
        colorHex: _selectedColor,
      );
    } else {
      await _groupService.sendMessage(widget.groupId, text);
    }

    _textController.clear();
    setState(() {});
    await _animateToBottom();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI: build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: s.hp(0.008)),
            _buildHeader(context),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _timeVisible.clear()),
                child: Stack(
                  children: [
                    _buildMessageStream(context),
                    if (_showFormattingOptions && _textController.text.trim().isNotEmpty)
                      _LiveDoodlePreview(
                        text: _textController.text.trim(),
                        font: _selectedFont,
                        fontSize: _selectedFontSize,
                        color: _parseHexColor(_selectedColor) ?? palette.text,
                      ),
                    if (_showJumpToBottom)
                      Positioned(
                        right: s.wp(0.03),
                        bottom: s.hp(0.17), // above input
                        child: _JumpToBottomButton(onTap: _animateToBottom),
                      ),
                  ],
                ),
              ),
            ),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: s.wp(0.03),
        vertical: s.hp(0.01),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          InkWell(
            onTap: () {
              _textController.clear();
              Navigator.pop(context);
            },
            child: Container(
              width: s.w * 0.2,
              padding: EdgeInsets.all(s.pad(0.0099)),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(s.rad(0.09)),
              ),
              child: Icon(
                Icons.arrow_back,
                color: palette.card,
                size: s.sp(0.04),
              ),
            ),
          ),

          // Group name pill (center)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: s.wp(0.05),
              vertical: s.hp(0.010),
            ),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(s.rad(0.1)),
            ),
            child: widget.groupName.length <= 14
    ? Text(
        widget.groupName,
        style: TextStyle(
          fontFamily: "SSEC",
          fontSize: s.sp(0.045),
          color: palette.text,
          letterSpacing: 0.3,
        ),
      )
    :SizedBox(
  height: s.hp(0.05),
  width: s.wp(0.39),
  child: Center( // 👈 centers marquee inside SizedBox
    child: Transform.translate(
      offset: Offset(0, s.h*0.001),
      child: Marquee(
        text: widget.groupName,
        style: TextStyle(
          fontFamily: "SSEC",
          fontSize: s.sp(0.040),
          color: palette.text,
          letterSpacing: 0.3,
        ),
        velocity: 30.0,
        blankSpace: 40.0,
        pauseAfterRound: Duration(seconds: 1),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center, // 👈 also center vertically
        startPadding: 10.0,
      ),
    ),
  ),
),

          ),

          // Settings (opens group info sheet)
          InkWell(
            onTap: _openGroupInfo,
            child: Container(
              width: s.w * 0.2,
              padding: EdgeInsets.all(s.pad(0.0099)),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(s.rad(0.09)),
              ),
              child: Icon(
                Icons.settings,
                color: palette.primary,
                size: s.sp(0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Messages
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildMessageStream(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);

    return Container(
      margin: EdgeInsets.all(s.pad(0.015)),
      padding: EdgeInsets.all(s.pad(0.018)),
      decoration: BoxDecoration(
        color: palette.onPrimary,
        borderRadius: BorderRadius.circular(s.rad(0.04)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _groupService.getMessages(widget.groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const _EmptyState();
          }

          // Hard jump to bottom after layout
          WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());

          return ListView.builder(
            controller: _scrollController,
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final message = docs[i].data() as Map<String, dynamic>;
              final messageId = docs[i].id;

              final senderId = message['senderId'] ?? message['senderID'] ?? '';
              final isMe = senderId == _currentUid;

final type = GroupMessageTypeX.fromString(message['type'] as String?);
              final Timestamp ts = message['timestamp'] as Timestamp? ?? Timestamp.now();
              final DateTime msgDate = ts.toDate();
              final String timeLabel = _fmtTime(msgDate);

              // Date header
              final showHeader = _shouldShowDateHeader(i, docs);
              final dateLabel = _labelForDate(msgDate);

              // Build content
              final Widget content = (type == GroupMessageType.doodle)
                  ? _buildDoodleContent(message, isMe)
                  : _buildTextContent(message, isMe);

              // Bubble margin handling when time is visible
              final hasDoodle = (type == GroupMessageType.doodle);
              final bubbleMargin = _timeVisible.contains(messageId)
                  ? EdgeInsets.only(
                      right: isMe ? s.pad(0.06) : s.pad(0.01),
                      left: isMe ? s.pad(0.01) : s.pad(0.06),
                      top: hasDoodle ? s.hp(0.0002) : s.hp(0.005),
                      bottom: hasDoodle ? s.hp(0.0002) : s.hp(0.005),
                    )
                  : hasDoodle
                      ? EdgeInsets.symmetric(
                          vertical: s.hp(0.0002),
                          horizontal: s.pad(0.004),
                        )
                      : EdgeInsets.symmetric(
                          vertical: s.hp(0.005),
                          horizontal: s.pad(0.01),
                        );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showHeader) _DateChip(label: dateLabel),
                  // Sender label (always shown)
                  FutureBuilder<DisplayUser?>(
                    future: _getUserBrief(senderId),
                    builder: (context, snap) {
                      final u = snap.data;
                      final name = isMe ? "you" : (u?.name ?? "user");
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isMe ? s.pad(0.02) : s.pad(0.01),
                            right: isMe ? s.pad(0.01) : s.pad(0.02),
                            top: s.hp(0.004),
                            bottom: s.hp(0.002),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: isMe ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              _SenderAvatar(user: u, fallbackIndex: u?.profileIndex, value: 1,), // *************************
                              SizedBox(width: s.wp(0.01)),
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: "POP",
                                  fontWeight: FontWeight.w600,
                                  fontSize: s.sp(0.02),
                                  color: context.appColors.text.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Message bubble + time overlay
                  GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        if (_timeVisible.contains(messageId)) {
                          _timeVisible.remove(messageId);
                        } else {
                          _timeVisible
                            ..clear()
                            ..add(messageId);
                        }
                      });
                    },
                    onLongPress: () => _onLongPressMessage(messageId, message),
                    child: Stack(
                      children: [
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: bubbleMargin,
                            padding: hasDoodle
                                ? EdgeInsets.all(s.pad(0.013))
                                : EdgeInsets.symmetric(
                                    horizontal: s.pad(0.024),
                                    vertical: s.pad(0.019),
                                  ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: hasDoodle
                                  ? Colors.transparent
                                  : (isMe ? context.appColors.primary : context.appColors.secondary),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isMe ? s.rad(0.04) : s.rad(0.01)),
                                topRight: Radius.circular(isMe ? s.rad(0.01) : s.rad(0.04)),
                                bottomLeft: Radius.circular(s.rad(0.04)),
                                bottomRight: Radius.circular(s.rad(0.04)),
                              ),
                            ),
                            child: content,
                          ),
                        ),
                        if (_timeVisible.contains(messageId))
                          Positioned(
                            bottom: 2,
                            right: isMe ? 6 : null,
                            left: isMe ? null : 6,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: 1.0,
                              child: Text(
                                timeLabel,
                                style: TextStyle(
                                  fontSize: s.w * 0.028,
                                  color: context.appColors.text,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _shouldShowDateHeader(int index, List<DocumentSnapshot> docs) {
    if (index == 0) return true;
    final prev = (docs[index - 1].data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
    final cur = (docs[index].data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
    final p = (prev ?? Timestamp.now()).toDate();
    final c = (cur ?? Timestamp.now()).toDate();
    return !(p.year == c.year && p.month == c.month && p.day == c.day);
  }

  String _labelForDate(DateTime dt) {
    final now = DateTime.now();
    final yest = now.subtract(const Duration(days: 1));
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "Today";
    }
    if (dt.year == yest.year && dt.month == yest.month && dt.day == yest.day) {
      return "Yesterday";
    }
    return "${dt.day} ${_monthName(dt.month)} ${dt.year}";
  }

  String _fmtTime(DateTime t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Future<DisplayUser?> _getUserBrief(String uid) async {
    final cached = _userCache.get(uid);
    if (cached != null) return cached;
    final fetched = await _directory.fetchUserBrief(uid);
    if (fetched != null) _userCache.put(fetched);
    return fetched;
  }

  // Text content builder
  Widget _buildTextContent(Map<String, dynamic> msg, bool isMe) {
    final s = S.of(context);
    final palette = context.appColors;
    final text = (msg['message'] ?? msg['text'] ?? '') as String;
    return Text(
      text,
      style: TextStyle(
        fontSize: s.sp(0.027),
        fontFamily: "POP",
        fontWeight: FontWeight.w500,
        color: isMe ? palette.onPrimary : palette.text,
      ),
    );
  }

  // Doodle content builder
  Widget _buildDoodleContent(Map<String, dynamic> msg, bool isMe) {
    final palette = context.appColors;
    final doodle = (msg['doodleContent'] as Map?)?.cast<String, dynamic>() ?? {};
    final text = (doodle["text"] ?? "") as String;
    final font = (doodle["font"] ?? "POP") as String;
    final fontSize = (doodle["fontSize"] is num) ? (doodle["fontSize"] as num).toDouble() : 24.0;
    final colorHex = doodle["color"] as String?;
    final color = _parseHexColor(colorHex) ?? (isMe ? palette.onPrimary : palette.text);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        textAlign: isMe ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontFamily: font,
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
          height: 0.7,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Input Area
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildInputArea(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);

    return Container(
      margin: EdgeInsets.all(s.pad(0.02)),
      padding: EdgeInsets.symmetric(
        horizontal: s.wp(0.04),
        vertical: s.hp(0.012),
      ),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(s.rad(0.06)),
      ),
      child: Column(
        children: [
          if (_showFormattingOptions)
            Padding(
              padding: EdgeInsets.only(bottom: s.hp(0.01)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      await SystemChannels.textInput.invokeMethod('TextInput.hide');
                      final font = await showFontDialog(context);
                      if (font != null) setState(() => _selectedFont = font);
                    },
                    child: _optionButton(context, "fonts"),
                  ),
                  GestureDetector(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      await SystemChannels.textInput.invokeMethod('TextInput.hide');
                      final size = await showSizeDialog(context, _selectedFont);
                      if (size != null) setState(() => _selectedFontSize = size);
                    },
                    child: _optionButton(context, "size"),
                  ),
                  GestureDetector(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      await SystemChannels.textInput.invokeMethod('TextInput.hide');
                      final color = await showColorDialog(context);
                      if (color != null) setState(() => _selectedColor = color);
                    },
                    child: _optionButton(context, "color"),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // IconButton(
              //   onPressed: () {/* your image picker, disabled in spec */},
              //   icon: Icon(Icons.image, color: palette.text, size: s.w * 0.07),
              // ),
              IconButton(
                onPressed: () {
                  setState(() => _showFormattingOptions = !_showFormattingOptions);
                  if (_showFormattingOptions) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                  }
                },
                icon: Icon(Icons.edit, color: palette.text, size: s.w * 0.07),
              ),
              SizedBox(width: s.w * 0.02),
              Expanded(
                child: Container(
                  height: s.w * 0.14,
                  padding: EdgeInsets.symmetric(horizontal: s.wp(0.02)),
                  decoration: BoxDecoration(
                    color: palette.onPrimary,
                    borderRadius: BorderRadius.circular(s.rad(0.1)),
                  ),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _textController,
                        focusNode: _msgFocus,
                        readOnly: _showFormattingOptions,
                        onSubmitted: (_) => _handleSend(),
                        decoration: InputDecoration(
                          hintText: "Message",
                          hintStyle: TextStyle(
                            fontFamily: "POP",
                            fontSize: s.sp(0.025),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            left: 12,
                            right: s.w * 0.15 + 12,
                            top: 14,
                            bottom: 14,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          width: s.w * 0.15,
                          height: s.h * 0.04,
                          decoration: BoxDecoration(
                            color: palette.secondary,
                            borderRadius: BorderRadius.circular(s.rad(0.09)),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: palette.text, size: s.w * 0.05),
                            onPressed: _handleSend,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionButton(BuildContext context, String label) {
    final s = S.of(context);
    final palette = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(vertical: s.hp(0.006), horizontal: s.wp(0.08)),
      margin: EdgeInsets.only(bottom: s.hp(0.002)),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(s.rad(0.025)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.text,
          fontSize: s.sp(0.03),
          fontFamily: "POP",
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Message long-press: copy / delete
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _onLongPressMessage(String messageId, Map<String, dynamic> msg) async {
final isText = msg['type'] == 'text';
    final senderId = msg['senderId'] ?? msg['senderID'] ?? '';
    final canDelete = _isAdmin || senderId == _currentUid;

    final action = await showModalBottomSheet<_MsgAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ActionSheet(
          canCopy: isText,
          canDelete: canDelete,
        );
      },
    );

    if (action == null) return;

    if (action == _MsgAction.copy && isText) {
      final text = (msg['message'] ?? msg['text'] ?? '') as String;
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied')),
        );
      }
      return;
    }

    if (action == _MsgAction.delete && canDelete) {
      await _confirmDelete(messageId);
    }
  }

  Future<void> _confirmDelete(String messageId) async {
    final palette = context.appColors;
    final s = S.of(context);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (ctx, a1, a2) {
        final size = MediaQuery.of(context).size;
        return Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.onPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Delete Message?",
                    style: TextStyle(
                      fontFamily: "POP",
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Are you sure you want to delete this message?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "POP",
                      color: palette.text.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          "No",
                          style: TextStyle(
                            fontFamily: "POP",
                            color: palette.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          await _groupService.deleteMessage(widget.groupId, messageId);
                          if (mounted) Navigator.pop(ctx);
                        },
                        child: const Text(
                          "Yes",
                          style: TextStyle(
                            fontFamily: "POP",
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Group Info / Settings Bottom Sheet
  // ───────────────────────────────────────────────────────────────────────────

  void _openGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
  barrierColor: Colors.transparent,
      builder: (ctx) {
        return _GroupInfoSheet(
          groupId: widget.groupId,
          groupName: widget.groupName,
          isAdmin: _isAdmin,
          adminId: _adminId,
          members: _members,
          fetchBrief: _getUserBrief,
          onRename: (newName) async {
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .update({"name": newName});
          },
          onLeaveGroup: () async {
            // await _groupService.removeMember(widget.groupId, _currentUid);
            // if (mounted) Navigator.pop(context); // close sheet
            // if (mounted) Navigator.pop(context); // leave page
          },
          onAddMember: (uid) async {
            await _groupService.addMember(widget.groupId, uid);
          },
          onRemoveMember: (uid) async {
            await _groupService.removeMember(widget.groupId, uid);
          },
          onMakeAdmin: (uid) async {
            // await _groupService.makeAdmin(widget.groupId, uid); 
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.toUpperCase().replaceAll('#', '');
    if (value.length == 6) value = 'FF$value'; // add opacity
    if (value.length != 8) return null;
    try {
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _monthName(int m) {
    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC"
    ];
    return months[m - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS: Isolated UI building blocks
// ─────────────────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.hp(0.01)),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: s.pad(0.02),
            vertical: s.pad(0.008),
          ),
          decoration: BoxDecoration(
            color: palette.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(s.rad(0.02)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: s.w * 0.03,
              color: palette.text.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontFamily: "POP",
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDoodlePreview extends StatelessWidget {
  final String text;
  final String font;
  final double fontSize;
  final Color color;

  const _LiveDoodlePreview({
    required this.text,
    required this.font,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = context.appColors;
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Opacity(
        opacity: 0.85,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: s.hp(0.006),
              horizontal: s.pad(0.02),
            ),
            padding: EdgeInsets.all(s.pad(0.02)),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: palette.onPrimary,
              borderRadius: BorderRadius.circular(s.rad(0.01)),
            ),
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: font,
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w600,
                height: 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = context.appColors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.pad(0.04)),
        child: Text(
          "No messages yet",
          style: TextStyle(
            fontFamily: "POP",
            color: palette.text.withOpacity(0.6),
            fontSize: s.sp(0.028),
          ),
        ),
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  final DisplayUser? user;
  final int? fallbackIndex;
  final int? value;

  const _SenderAvatar({this.user, this.fallbackIndex, this.value});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // final photo = user?.photoUrl;
    final idx = user?.profileIndex ?? fallbackIndex ?? 1;
    final asset = "assets/image/pf$idx.png";

    final double radius = value == 2 ? s.rad(.055) : s.rad(.015);
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(asset),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION SHEET for message long-press
// ─────────────────────────────────────────────────────────────────────────────

enum _MsgAction { copy, delete }

class _ActionSheet extends StatelessWidget {
  final bool canCopy;
  final bool canDelete;

  const _ActionSheet({
    required this.canCopy,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + s.hp(0.02),
      ),
      decoration: BoxDecoration(
        color: palette.onPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(s.rad(0.04)),
          topRight: Radius.circular(s.rad(0.04)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: s.hp(0.01)),
            Container(
              width: s.w * 0.12,
              height: 5,
              decoration: BoxDecoration(
                color: palette.text.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: s.hp(0.016)),
            if (canCopy)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copy"),
                onTap: () => Navigator.pop(context, _MsgAction.copy),
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete"),
                onTap: () => Navigator.pop(context, _MsgAction.delete),
              ),
            SizedBox(height: s.hp(0.01)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Jump-to-bottom floating button
// ─────────────────────────────────────────────────────────────────────────────

class _JumpToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _JumpToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = context.appColors;
    return Material(
      color: palette.secondary,
      borderRadius: BorderRadius.circular(100),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(s.pad(0.012)),
          child: const Icon(Icons.arrow_downward),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group Info Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _GroupInfoSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isAdmin;
  final String? adminId;
  final List<String> members;

  final Future<DisplayUser?> Function(String uid) fetchBrief;

  final Future<void> Function(String newName) onRename;
  final Future<void> Function() onLeaveGroup;

  final Future<void> Function(String userId) onAddMember;
  final Future<void> Function(String userId) onRemoveMember;
  final Future<void> Function(String userId) onMakeAdmin;

  const _GroupInfoSheet({
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
    required this.adminId,
    required this.members,
    required this.fetchBrief,
    required this.onRename,
    required this.onLeaveGroup,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onMakeAdmin,
  });

  @override
  State<_GroupInfoSheet> createState() => _GroupInfoSheetState();
}

class _GroupInfoSheetState extends State<_GroupInfoSheet> {
  late TextEditingController _nameCtl;
  final _addedController = TextEditingController(); // input for add-member by uid
  final _cache = _UserBriefCache(maxEntries: 200);
   final _groupService = GroupChatService();

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.groupName);
    _primeMembers();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _addedController.dispose();
    super.dispose();
  }

  Future<void> _primeMembers() async {
    for (final uid in widget.members) {
      final v = await widget.fetchBrief(uid);
      if (v != null) {
        _cache.put(v);
        if (mounted) setState(() {});
      }
    }
  }

  Future<DisplayUser?> _getCached(String uid) async {
    final c = _cache.get(uid);
    if (c != null) return c;
    final v = await widget.fetchBrief(uid);
    if (v != null) {
      _cache.put(v);
      return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: s.hp(0.012),
      ),
      decoration: BoxDecoration(
        color: palette.onPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(s.rad(0.04)),
          topRight: Radius.circular(s.rad(0.04)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.wp(0.045)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: s.w * 0.12,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.text.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(height: s.hp(0.02)),

                // Title row + rename (admin)
              Row(
  children: [
    Expanded(
      child: TextField(
        controller: _nameCtl,
        readOnly: !widget.isAdmin,
        style: TextStyle(
          fontFamily: "POP",
          color: palette.text, // 👈 typed text style
        ),
        decoration: InputDecoration(
          labelText: "Group name",
          labelStyle: TextStyle(
            fontFamily: "SSEC", // 👈 label style
            color: palette.text,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // 👈 full curvy
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // 👈 full curvy
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // 👈 full curvy
          ),
        ),
      ),
    ),
    if (widget.isAdmin) ...[
      SizedBox(width: s.wp(0.02)),
      SizedBox(
  height: s.h*0.065, // 👈 match TextField height
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: palette.primary, // 👈 button color
      foregroundColor: palette.text,    // 👈 text/icon color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // 👈 curvy button
      ),
    ),
    onPressed: () async {
      final newName = _nameCtl.text.trim();
      if (newName.isEmpty) return;
      await widget.onRename(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group renamed")),
        );
      }
    },
    child:  Text("Save", style: TextStyle(fontFamily: "POP", color: palette.onPrimary, fontSize: s.sp(0.03),),),
  ),
),
    ],
  ],
),
                SizedBox(height: s.hp(0.02)),

                // Members list
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Members",
                    style: TextStyle(
                      fontFamily: "SSEC",
                      fontSize: s.sp(0.05),
                      color: palette.secondary 
                    ),
                  ),
                ),
                SizedBox(height: s.hp(0.01)),
                ...widget.members.map((uid) {
                  return FutureBuilder<DisplayUser?>(
                    future: _getCached(uid),
                    builder: (context, snap) {
                      final user = snap.data;
                      final isAdminUser = uid == widget.adminId;
                      return Padding(
                          padding: EdgeInsets.only(bottom: s.h * 0.009),
                        child: Transform.translate(
                          offset: Offset(-s.w*0.05, 0),
                          child: ListTile(
                            leading: _SenderAvatar(user: user, fallbackIndex: user?.profileIndex, value: 2),
                            title: Text(user?.name ?? uid, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: "RSO", color: palette.primary, fontSize: s.w*0.07, height: 0.9),),
                            subtitle: isAdminUser ?  Text("[admin]", style: TextStyle(fontFamily: "POP", fontSize: s.w*0.035, height: 0.6, color: palette.secondary), ) : null,
                            // trailing: _buildMemberTrailing(uid, isAdminUser),
                          ),
                        ),
                      );
                    },
                  );
                }),

                SizedBox(height: s.hp(0.015)),

               

                // SizedBox(height: s.hp(0.032)),

                // Leave group
                // Align(
                //   alignment: Alignment.centerLeft,
                //   child: OutlinedButton.icon(
                //     icon: const Icon(Icons.logout),
                //     label: const Text("Leave Group"),
                //     onPressed: () async {
                //       await widget.onLeaveGroup();
                //     },
                //   ),
                // ),

                if (widget.isAdmin) ...[
  SizedBox(height: s.hp(0.02)),
  SizedBox(
    width: double.infinity, // 👈 full width
    height: s.hp(0.065),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // 👈 delete = red
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: () async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // force explicit Yes/No
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: size.width * 0.03),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.onPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), // shadow color
                blurRadius: 12,                        // softness of the shadow
                spreadRadius: 2,                       // how much the shadow spreads
                offset: const Offset(0, 6),            // shadow position (x, y)
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Delete Group?",
                  style: TextStyle(
                    fontFamily: "POP",
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to delete this group?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "POP",
                    color: palette.text.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        "No",
                        style: TextStyle(
                          fontFamily: "POP",
                          color: palette.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        "Yes",
                        style: TextStyle(
                          fontFamily: "POP",
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (confirm != true) return;

  try {
    await _groupService.deleteGroup(widget.groupId);
    if (mounted) {
      Navigator.of(context).pop(); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group deleted")),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
},
      child: Text(
        "Delete Group",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "POP",
          fontSize: s.sp(0.04),
          color: palette.onPrimary, // text contrast
        ),
      ),
    ),
  ),

],
SizedBox(height: s.hp(0.02)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget? _buildMemberTrailing(String uid, bool isAdminUser) {
  //   if (!widget.isAdmin) return null;

  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       if (!isAdminUser)
  //         IconButton(
  //           tooltip: "Make admin",
  //           icon: const Icon(Icons.verified_user),
  //           onPressed: () => widget.onMakeAdmin(uid),
  //         ),
  //       if (!isAdminUser)
  //         IconButton(
  //           tooltip: "Remove",
  //           icon: const Icon(Icons.person_remove_alt_1),
  //           onPressed: () => widget.onRemoveMember(uid),
  //         ),
  //     ],
  //   );
  // }
}

extension GroupMessageTypeX on GroupMessageType {
  static GroupMessageType fromString(String? value) {
    return GroupMessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GroupMessageType.text,
    );
  }
}
