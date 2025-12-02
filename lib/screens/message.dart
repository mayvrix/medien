import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medien/core/size.dart';
import 'package:medien/core/theme_colors.dart';
import 'package:medien/services/auth/auth_service.dart';
import 'package:medien/services/chats/chat_service.dart';
import 'package:medien/widgets/doodle_dialogs.dart';
import 'package:flutter/services.dart'; // for SystemChannels.textInput.hide


class MessagePage extends StatefulWidget {
  final String partner;
  final String partnerID;
  final int? profile;

  const MessagePage({
    super.key,
    required this.partner,
    required this.partnerID,
    required this.profile
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool showFormattingOptions = false;
  String _selectedFont = "POP";
  double _selectedFontSize = 24.0;
  String _selectedColor = "#000000";

  String get senderID => _authService.getCurrentUser()!.uid;

  Set<String> _showTime = {};


 void _showDeleteDialog(BuildContext context, String partnerId, String msgId) {
  final palette = context.appColors;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "",
    barrierColor: Colors.transparent, // no dark overlay
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim1, anim2) {
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
                        await _chatService.deleteMessage(partnerId, msgId);
                        Navigator.pop(ctx);
                      },
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
}



  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
final FocusNode _msgFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (showFormattingOptions) {
      // send doodle
      await _chatService.sendDoodleMessage(
        reciverId: widget.partnerID,
        text: text,
        font: _selectedFont,
        fontSize: _selectedFontSize,
        colorHex: _selectedColor,
      );
    } else {
      // send normal text
      await _chatService.sendMessage(widget.partnerID, text);
    }

    _textController.clear();
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
     _msgFocus.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _textController.clear();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final s = S.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: s.hp(0.008)),

              // ===== TOP BAR =====
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: s.wp(0.03),
                  vertical: s.hp(0.01),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s.rad(0.04)),
                        color: palette.primary,
                      ),
                      padding: EdgeInsets.all(s.pad(0.01)),
                      child: CircleAvatar(
                        radius: s.rad(.069),
                        backgroundImage: AssetImage("assets/image/pf${widget.profile ?? 1}.png"),
                      ),
                    ),
                    Container(
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
                  ],
                ),
              ),


// ===== CHAT AREA =====
Expanded(
  child: GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      // hide timestamps if tap outside
      setState(() => _showTime.clear());
    },
    child: Stack(
      children: [
        // ==== CHAT MESSAGES ====
        Container(
          margin: EdgeInsets.all(s.pad(0.015)),
          padding: EdgeInsets.all(s.pad(0.018)),
          decoration: BoxDecoration(
            color: palette.onPrimary,
            borderRadius: BorderRadius.circular(s.rad(0.04)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getMessages(senderID, widget.partnerID),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("No messages yet"));

              // auto-scroll to bottom
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final msg = docs[i].data() as Map<String, dynamic>;
                  final msgId = docs[i].id;
                  final isMe = msg["senderID"] == senderID;

                  final hasDoodle = msg.containsKey("doodleContent");
                  final Widget messageContent = hasDoodle
                      ? _buildDoodleMessage(msg["doodleContent"], isMe)
                      : _buildTextMessage(msg["message"], isMe);

                  final Timestamp ts = msg["timestamp"];
                  final DateTime msgDate = ts.toDate();
                  final String timeLabel =
                      "${msgDate.hour.toString().padLeft(2, '0')}:${msgDate.minute.toString().padLeft(2, '0')}";

                  // Date label
                  String dateLabel = "";
                  final now = DateTime.now();
                  final yesterday = now.subtract(const Duration(days: 1));
                  if (msgDate.year == now.year &&
                      msgDate.month == now.month &&
                      msgDate.day == now.day) {
                    dateLabel = "Today";
                  } else if (msgDate.year == yesterday.year &&
                      msgDate.month == yesterday.month &&
                      msgDate.day == yesterday.day) {
                    dateLabel = "Yesterday";
                  } else {
                    dateLabel =
                        "${msgDate.day} ${_monthName(msgDate.month)} ${msgDate.year}";
                  }

                  bool showDateHeader = true;
                  if (i > 0) {
                    final prev =
                        (docs[i - 1].data() as Map)["timestamp"] as Timestamp;
                    final prevDate = prev.toDate();
                    if (prevDate.year == msgDate.year &&
                        prevDate.month == msgDate.month &&
                        prevDate.day == msgDate.day) {
                      showDateHeader = false;
                    }
                  }

                  // margin adjustment when timestamp is visible
                  final bubbleMargin = _showTime.contains(msgId)
                      ? EdgeInsets.only(
                          right: isMe ? s.pad(0.06) : s.pad(0.01),
                          left: isMe ? s.pad(0.01) : s.pad(0.06),
                          top: hasDoodle ? s.hp(0.0002) : s.hp(0.005),
                          bottom: hasDoodle ? s.hp(0.0002) : s.hp(0.005),
                        )
                      : hasDoodle
                          ? EdgeInsets.symmetric(
                              vertical: s.hp(0.0002), horizontal: s.pad(0.004))
                          : EdgeInsets.symmetric(
                              vertical: s.hp(0.005), horizontal: s.pad(0.01));

                  return Column(
                    children: [
                      if (showDateHeader)
                        Padding(
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
                                dateLabel,
                                style: TextStyle(
                                  fontSize: s.w * 0.03,
                                  color: palette.text.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "POP",
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ==== message bubble with timestamp overlay ====
                      GestureDetector(
                        onDoubleTap: () {
                          setState(() {
                            if (_showTime.contains(msgId)) {
                              _showTime.remove(msgId);
                            } else {
                              _showTime.clear();
                              _showTime.add(msgId);
                            }
                          });
                        },
                        onLongPress: () {
                          if (isMe) {
                            _showDeleteDialog(context, widget.partnerID, msgId);
                          }
                        },
                        child: Stack(
                          children: [
                            Align(
                              alignment:
                                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: bubbleMargin,
                                padding: hasDoodle
                                    ? EdgeInsets.all(s.pad(0.013))
                                    : EdgeInsets.symmetric(
                                        horizontal: s.pad(0.024),
                                        vertical: s.pad(0.019),
                                      ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: hasDoodle
                                      ? Colors.transparent
                                      : (isMe ? palette.primary : palette.secondary),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        isMe ? s.rad(0.04) : s.rad(0.01)),
                                    topRight: Radius.circular(
                                        isMe ? s.rad(0.01) : s.rad(0.04)),
                                    bottomLeft: Radius.circular(s.rad(0.04)),
                                    bottomRight: Radius.circular(s.rad(0.04)),
                                  ),
                                ),
                                child: messageContent,
                              ),
                            ),

                            // timestamp overlay
                            if (_showTime.contains(msgId))
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
                                      color: palette.text,
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
        ),

        // ==== LIVE PREVIEW DOODLE ====
        if (showFormattingOptions && _textController.text.trim().isNotEmpty)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Opacity(
              opacity: 0.8,
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
                    _textController.text.trim(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: _selectedFont,
                      fontSize: _selectedFontSize,
                      color: _hexToColor(_selectedColor) ?? palette.text,
                      fontWeight: FontWeight.w600,
                      height: 0.7,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  ),
),

// ===== INPUT AREA =====
Container(
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
      if (showFormattingOptions)
        Padding(
          padding: EdgeInsets.only(bottom: s.hp(0.01)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () async {
                  // 🔒 prevent keyboard from reopening
                  FocusManager.instance.primaryFocus?.unfocus();
                  await SystemChannels.textInput.invokeMethod('TextInput.hide');

                  final font = await showFontDialog(context);
                  if (font != null) {
                    setState(() => _selectedFont = font);
                  }
                },
                child: _optionButton(context, "fonts"),
              ),
              GestureDetector(
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await SystemChannels.textInput.invokeMethod('TextInput.hide');

                  final size = await showSizeDialog(context, _selectedFont);
                  if (size != null) {
                    setState(() => _selectedFontSize = size);
                  }
                },
                child: _optionButton(context, "size"),
              ),
              GestureDetector(
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await SystemChannels.textInput.invokeMethod('TextInput.hide');

                  final color = await showColorDialog(context);
                  if (color != null) {
                    setState(() => _selectedColor = color);
                  }
                },
                child: _optionButton(context, "color"),
              ),
            ],
          ),
        ),
      Row(
        children: [
          IconButton(
            onPressed: () {
              // image picker disabled
            },
            icon: Icon(Icons.image, color: palette.text, size: s.w * 0.07),
          ),
          IconButton(
            onPressed: () {
              setState(() => showFormattingOptions = !showFormattingOptions);
              if (showFormattingOptions) {
                // entering formatting mode: ensure keyboard is closed
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
          readOnly: showFormattingOptions,
          onSubmitted: (_) => _sendMessage(),
          decoration: InputDecoration(
            hintText: "Message",
            hintStyle: TextStyle(
              fontFamily: "POP",
              fontSize: s.sp(0.025),
            ),
            border: InputBorder.none,
            // 👇 add right padding so text avoids send button
            contentPadding: EdgeInsets.only(
              left: 12,
              right: s.w * 0.15 + 12,  // enough space for the send button
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
              icon: Icon(
                Icons.send,
                color: palette.text,
                size: s.w * 0.05,
              ),
              onPressed: _sendMessage,
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
),


            ],
          ),
        ),
      ),
    );
  }

  // --- helpers ---
  Widget _buildTextMessage(String text, bool isMe) {
    final palette = context.appColors;
    final s = S.of(context);
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
Widget _buildDoodleMessage(Map<String, dynamic> doodle, bool isMe) {
  final palette = context.appColors;

  final text = (doodle["text"] ?? "") as String;
  final font = (doodle["font"] ?? "POP") as String;

  // safely parse fontSize
  final fontSize = (doodle["fontSize"] is num)
      ? (doodle["fontSize"] as num).toDouble()
      : 24.0;

  final colorHex = doodle["color"] as String?;
  final color =
      _hexToColor(colorHex) ?? (isMe ? palette.onPrimary : palette.text);

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(
      text,
      textAlign: isMe ? TextAlign.right : TextAlign.left, // ✅ fixed alignment
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



 Color? _hexToColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var value = hex.toUpperCase().replaceAll('#', '');
  if (value.length == 6) value = 'FF$value'; // add opacity
  if (value.length != 8) return null;

  try {
    return Color(int.parse(value, radix: 16));
  } catch (_) {
    return null; // fallback on parsing error
  }
}


  Widget _optionButton(BuildContext context, String label) {
    final s = S.of(context);
    final palette = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: s.hp(0.006),
        horizontal: s.wp(0.08),
      ),
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
}

String _monthName(int m) {
  const months = [
    "JAN","FEB","MAR","APR","MAY","JUN",
    "JUL","AUG","SEP","OCT","NOV","DEC"
  ];
  return months[m - 1];
}



