import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medien/services/auth/auth_service.dart';
import 'package:medien/services/chats/chat_service.dart';
import 'package:medien/services/chats/group_chat_service.dart';
import '../../core/size.dart';
import '../../core/theme_colors.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final GroupChatService _groupChatService = GroupChatService();

  final Set<String> _selectedUids = {}; // selected members
  final List<Map<String, dynamic>> _selectedProfiles = []; // selected profiles

  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGroup() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      _showSnack("Not logged in");
      return;
    }

    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      _showSnack("Please set a group name");
      return;
    }

    // Must have 2 others + me = 3 total
    if (_selectedUids.length < 2) {
      _showSnack("Select at least 2 members");
      return;
    }

    final memberIds = <String>{..._selectedUids, currentUid}.toList();

    setState(() => _isCreating = true);
    try {
      final groupId = await _groupChatService.createGroup(
        groupName: name,
        memberIds: memberIds,
      );
      _showSnack("Group created");
      if (mounted) {
        Navigator.pop(context, groupId); // return groupId
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  bool get _canCreateGroup {
    return _groupNameController.text.trim().isNotEmpty &&
        _selectedUids.length >= 2 &&
        !_isCreating;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.appColors;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.pad(0.02)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capsule Back Button
              _CapsuleButton(
                onTap: () => Navigator.pop(context),
                icon: Icons.arrow_back,
                color: c.primary,
              ),
              SizedBox(height: s.hp(0.045)),

              // Group Name Input
              Container(
                padding: EdgeInsets.symmetric(horizontal: s.wp(0.03)),
                decoration: BoxDecoration(
                  border: Border.all(color: c.primary, width: 2),
                  borderRadius: BorderRadius.circular(s.rad(0.06)),
                ),
                child: TextField(
                  controller: _groupNameController,
                  style: TextStyle(
                    fontSize: s.sp(0.06),
                    fontFamily: "SSEC",
                    color: c.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: " set group name",
                    hintStyle: TextStyle(
                      fontSize: s.sp(0.06),
                      fontFamily: "SSEC",
                      color: c.primary,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(height: s.hp(0.012)),

              // Selected Profiles Preview
              Container(
                padding: EdgeInsets.all(s.w * 0.02),
                height: s.hp(0.13),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: c.primary, width: 2),
                  borderRadius: BorderRadius.circular(s.rad(0.06)),
                ),
                alignment: Alignment.center,
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _authService.getProfile(
                      FirebaseAuth.instance.currentUser?.uid ?? ""),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final profile = snapshot.data ?? {};
                    final currentUserProfileNumber =
                        profile["profileNumber"] ?? 1;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 👤 Always show current user first
                          CircleAvatar(
                            radius: s.rad(0.065),
                            backgroundImage: AssetImage(
                              "assets/image/pf$currentUserProfileNumber.png",
                            ),
                          ),
                          ..._selectedProfiles.map((profile) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: s.w * 0.01),
                              child: CircleAvatar(
                                radius: s.rad(0.065),
                                backgroundImage: AssetImage(
                                  "assets/image/pf${profile['profileNumber'] ?? 1}.png",
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: s.hp(0.012)),

              // Members List Section
              Container(
                height: s.hp(0.45),
                width: double.infinity,
                padding: EdgeInsets.all(s.pad(0.015)),
                decoration: BoxDecoration(
                  border: Border.all(color: c.primary, width: 2),
                  borderRadius: BorderRadius.circular(s.rad(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      " select members",
                      style: TextStyle(
                        fontSize: s.sp(0.06),
                        fontFamily: "SSEC",
                        color: c.primary,
                      ),
                    ),
                    SizedBox(height: s.hp(0.01)),

                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _chatService.getUserStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("No users found"));
                          }

                          final users = snapshot.data!;
                          final currentEmail =
                              FirebaseAuth.instance.currentUser?.email;
                          final filtered = users
                              .where((u) => u['email'] != currentEmail)
                              .toList();

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final u = filtered[index];
                              final uid = u['uid'];
                              final isSelected = _selectedUids.contains(uid);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedUids.remove(uid);
                                      _selectedProfiles
                                          .removeWhere((p) => p['uid'] == uid);
                                    } else {
                                      _selectedUids.add(uid);
                                      _selectedProfiles.add(u);
                                    }
                                  });
                                },
                                child: Container(
                                  margin:
                                      EdgeInsets.only(bottom: s.hp(0.012)),
                                  padding: EdgeInsets.all(s.pad(0.012)),
                                  decoration: BoxDecoration(
                                    color: c.secondary.withOpacity(0.7),
                                    border: Border.all(
                                      color: isSelected
                                          ? c.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        s.rad(0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: s.rad(0.07),
                                        backgroundImage: AssetImage(
                                          "assets/image/pf${u['profileNumber'] ?? 1}.png",
                                        ),
                                      ),
                                      SizedBox(width: s.wp(0.03)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              u['username'] ?? "username",
                                              style: TextStyle(
                                                fontSize: s.sp(0.05),
                                                fontFamily: "RSO",
                                                color: c.primary,
                                                height: 1.1,
                                              ),
                                            ),
                                            Text(
                                              u['email'] ?? "email",
                                              style: TextStyle(
                                                fontSize: s.sp(0.044),
                                                fontFamily: "SSEC",
                                                color: c.primary,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Arrow Button
              GestureDetector(
                onTap: _canCreateGroup ? _handleCreateGroup : null,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: s.hp(0.019)),
                  decoration: BoxDecoration(
                    color: _canCreateGroup
                        ? c.primary
                        : c.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(s.rad(0.07)),
                  ),
                  child: Center(
                    child: _isCreating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.arrow_forward,
                            color: c.onPrimary,
                            size: s.sp(0.06),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Capsule Back Button
class _CapsuleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _CapsuleButton({
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s.w * 0.25,
        padding: EdgeInsets.all(s.pad(0.018)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(s.rad(0.08)),
        ),
        child: Icon(
          icon,
          size: s.sp(0.05),
          color: color,
        ),
      ),
    );
  }
}
