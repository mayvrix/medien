import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medien/core/size.dart';
import 'package:medien/core/theme_colors.dart';
import 'package:medien/screens/groups/group_message.dart';
import 'package:medien/services/chats/group_chat_service.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final GroupChatService _groupService = GroupChatService();
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.appColors;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Top bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: s.wp(0.04),
                vertical: s.hp(0.015),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CapsuleButton(
                    onTap: () => Navigator.pop(context),
                    icon: Icons.arrow_back,
                    color: c.primary,
                  ),
                 
                ],
              ),
            ),

            // 🔹 Groups list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _groupService.getUserGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: c.primary));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text("No groups yet",
                          style: TextStyle(color: c.primary)),
                    );
                  }

                  final groups = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.all(s.wp(0.04)),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final groupId = group["groupId"];
                      final isSelected = _selectedGroupId == groupId;

                      return GestureDetector(
                        onTap: () {
                          if (_selectedGroupId == null) {
                            // ✅ Open group chat with full UI
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupMessagePage(
                                  groupId: groupId,
                                  groupName: group["name"] ?? "Unnamed Group",
                                ),
                              ),
                            );
                          } else {
                            // ✅ Exit selection mode
                            setState(() => _selectedGroupId = null);
                          }
                        },
                        child: Opacity(
                          opacity: isSelected ? 0.5 : 1,
                          child: Container(
                            margin: EdgeInsets.only(bottom: s.hp(0.02)),
                            padding: EdgeInsets.symmetric(
                              vertical: s.hp(0.025),
                              horizontal: s.wp(0.06),
                            ),
                            decoration: BoxDecoration(
                              color: c.secondary,
                              borderRadius: BorderRadius.circular(s.rad(0.03)),
                            ),
                            child: Column(
                              children: [
                                // Group name
                                Text(
                                  group["name"] ?? "Unnamed Group",
                                  style: TextStyle(
                                    fontSize: s.sp(0.09),
                                    fontFamily: "SSEC",
                                    color: c.primary,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: s.hp(0.015)),

                                // Member avatars
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: (group["members"] as List)
                                      .take(5)
                                      .map<Widget>((userId) {
                                    return _MemberAvatar(userId: userId);
                                  }).toList(),
                                ),
                              ],
                            ),
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
    );
  }

}

/// 🔹 Widget that fetches and shows a user’s profileNumber as avatar
class _MemberAvatar extends StatelessWidget {
  final String userId;
  const _MemberAvatar({required this.userId});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return FutureBuilder<DocumentSnapshot>(
      // 🔹 FIX: must match Firestore collection name exactly ("Users")
      future: FirebaseFirestore.instance.collection("Users").doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: s.wp(0.01)),
            child: CircleAvatar(
              radius: s.wp(0.045),
              backgroundColor: Colors.grey.shade300,
            ),
          );
        }

        int profileNumber = 1; // default
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          profileNumber = data["profileNumber"] ?? 1;
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: s.wp(0.01)),
          child: CircleAvatar(
            radius: s.wp(0.045),
            backgroundImage: AssetImage("assets/image/pf$profileNumber.png"),
          ),
        );
      },
    );
  }
}

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
        padding: EdgeInsets.all(s.pad(0.015)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(s.rad(0.04)),
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

/// 🔹 Simple Chat Screen for a group
class GroupChatScreen extends StatelessWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        backgroundColor: c.primary,
      ),
      body: Center(
        child: Text("Chat for group: $groupName (id: $groupId)"),
      ),
    );
  }
}
