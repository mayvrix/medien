import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medien/screens/message.dart';
import 'package:medien/screens/settings.dart';
import 'package:medien/services/auth/auth_service.dart';
import 'package:medien/services/chats/chat_service.dart';
import '../../core/theme_colors.dart';
import '../../core/size.dart';

import '../../widgets/bottom_fab_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool expanded = false;
  late final AnimationController _controller;
  late final ScrollController _scrollController;

  Map<String, dynamic>? _profile;
  bool _loading = true;


  // reciver
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

   void _refreshHome() {
    setState(() {});
  }

 @override
void initState() {
  super.initState();
  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  _scrollController = ScrollController();
   _loadProfile();
}

Future<void> _loadProfile() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final data = await _authService.getProfile(uid); // 👈 here you can await
  setState(() {
    _profile = data;
    _loading = false;
  });
}

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      expanded = !expanded;
      if (expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.appColors;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: c.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: s.wp(.04)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: s.hp(.01)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: expanded
                        ? _expandedTopBar(context)
                        : _collapsedTopBar(context),
                  ),
                  expanded
                      ? SizedBox(height: s.hp(.022))
                      : SizedBox(height: s.hp(.015)),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: expanded ? 0.0 : 1.0,
                    child: expanded ? const SizedBox() : _userMiniCard(context),
                  ),
                  SizedBox(height: s.hp(.01)),
                  _nearbyExpandableCard(context),
                  SizedBox(height: s.hp(.02)),
                ],
              ),
            ),
          ),
          BottomFabBar(onPrimaryAction: () {}, onProfileUpdated: _refreshHome,),
        ],
      ),
    );
  }

  Widget _collapsedTopBar(BuildContext context) {
    final s = S.of(context);
    final c = context.appColors;
    return Row(
      key: const ValueKey('collapsedTop'),
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingScreen()),
                ),
          child: Container(
            width: s.wp(.22),
            height: s.wp(.22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.card,
              shape: BoxShape.circle,
             
            ),
            child: Icon(
              Icons.menu_rounded,
              size: s.sp(.033),
              color: c.accent,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: s.wp(.04),
              vertical: s.hp(.002),
            ),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(s.rad(.08)),
             
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'medien',
                style: TextStyle(
                  fontSize: s.sp(.07),
                  fontWeight: FontWeight.w400,
                  color: c.primary,
                  fontFamily: "KDM",
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

 Widget _expandedTopBar(BuildContext context) {
  final s = S.of(context);
  final c = context.appColors;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return const SizedBox.shrink();
  }

  return FutureBuilder<Map<String, dynamic>?>(
    future: _authService.getProfile(uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Padding(
          padding: EdgeInsets.all(s.wp(.02)),
          child: const CircularProgressIndicator(),
        );
      }
      if (!snapshot.hasData || snapshot.data == null) {
        return const Center(child: Text("No profile data"));
      }

      final profile = snapshot.data!;
      final profileNumber = profile["profileNumber"] ?? 1;

      return Column(
        children: [
          SizedBox(height: s.hp(.017)),
          Row(
            key: const ValueKey('expandedTop'),
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: s.wp(.05), vertical: s.hp(.005)),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(s.rad(.08)),
                ),
                child: Text(
                  'medien',
                  style: TextStyle(
                    fontSize: s.sp(.055),
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                    fontFamily: "SSEC",
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.card, width: 4),
                ),
                child: CircleAvatar(
                  radius: s.rad(.04),
                  backgroundImage: AssetImage("assets/image/pf$profileNumber.png"),
                ),
              ),
            ],
          ),
          SizedBox(height: s.hp(.017)),
        ],
      );
    },
  );
}


Widget _userMiniCard(BuildContext context) {
  final s = S.of(context);
  final c = context.appColors;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return const SizedBox.shrink();
  }

  final profile = _profile ?? {};
  final username = profile["username"] ?? "unknown";
  final profileNumber = profile["profileNumber"] ?? 1;
  final email = FirebaseAuth.instance.currentUser?.email ?? "no email";

  return Container(
    padding: EdgeInsets.all(s.pad(.017)),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(s.rad(.065)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: s.rad(.069),
          backgroundImage: AssetImage("assets/image/pf$profileNumber.png"),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _loading
                  ? SizedBox(
                      width: s.wp(.05),
                      height: s.wp(.05),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      username,
                      style: TextStyle(
                        color: c.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: s.sp(.05),
                        fontFamily: "RSO",
                        height: 1.1,
                      ),
                    ),
              Text(
                email.length > 23 ? "${email.substring(0, 23)}…" : email,
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: s.sp(.044),
                  fontFamily: "SSEC",
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}




  Widget _nearbyExpandableCard(BuildContext context) {
    final s = S.of(context);
    final c = context.appColors;
    final collapsedHeight = s.hp(.23);
    final expandedHeight = s.hp(.60);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      height: expanded ? expandedHeight : collapsedHeight,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(s.rad(.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!expanded)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: s.wp(.05),
                vertical: s.hp(.015),
              ),
              child: Row(
                children: [
                  Text(
                    'nearby people',
                    style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: s.sp(.044),
                      fontFamily: "POP",
                    ),
                  ),
                  const Spacer(),
                  _arrowButton(context, expanded, _toggleExpand),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: s.wp(.05),
                vertical: s.hp(.015),
              ),
              child: Center(
                child: Text(
                  'nearby people',
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: s.sp(.055),
                    fontFamily: "POP",
                  ),
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: expanded
                  ? _expandedList(context)
                  : _collapsedRow(context),
            ),
          ),
        ],
      ),
    );
  }

//default people
Widget _collapsedRow(BuildContext context) {
  final s = S.of(context);
  final c = context.appColors;
  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  return Padding(
    padding: EdgeInsets.only(
      left: s.wp(.04),
      right: s.wp(.04),
      top: s.hp(.01),
      bottom: s.hp(.02),
    ),
    child: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUserStream(), // 👈 your Firestore stream
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        // Filter out current user
        final users = snapshot.data!
            .where((u) => u['email'] != currentUserEmail)
            .take(3) // 👈 show only first 5
            .toList();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: users.map((u) {
            final profileNumber = u["profileNumber"] ?? 1;

            return Container(
              margin: EdgeInsets.only(right: s.wp(.01)),
              padding: EdgeInsets.all(s.pad(.01)),
              decoration: BoxDecoration(
                color: c.secondary,
                borderRadius: BorderRadius.circular(s.rad(.05)),
              ),
              child: GestureDetector(
                onTap: () {
                  // 👉 navigate to chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessagePage(
                        partner: u['email'],
                        partnerID: u["uid"],
                        profile: u['profileNumber']
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: s.rad(.071).toDouble(),
                  backgroundImage: AssetImage("assets/image/pf$profileNumber.png"),
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Expanded list widget to show all users from Firestore
Widget _expandedList(BuildContext context) {
  final s = S.of(context);
  final c = context.appColors;

  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  return Stack(
    children: [
      Padding(
        padding: EdgeInsets.only(
          left: s.wp(.04),
          right: s.wp(.04),
          bottom: s.hp(.08),
          top: s.wp(.01),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatService.getUserStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Text("Loading..."));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No users found"));
            }

            // ✅ filter out current logged in user
            final users = snapshot.data!
                .where((u) => u['email'] != currentUserEmail)
                .toList();

            if (users.isEmpty) {
              return const Center(child: Text("No other users found"));
            }

            return ListView(
              controller: _scrollController,
              children: users.map<Widget>((u) {
                return InkWell(
                  onTap: () {
                    // 👉 Navigate to chat page with this user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessagePage(
                          partner: u['email'],
                          partnerID: u["uid"],
                          profile: u['profileNumber']
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: s.hp(.007)),
                    padding: EdgeInsets.all(s.pad(.012)),
                    decoration: BoxDecoration(
                      color: c.secondary,
                      borderRadius: BorderRadius.circular(s.rad(.03)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: s.rad(.069),
                          backgroundImage:  AssetImage("assets/image/pf${u['profileNumber']}.png"),
                        ),
                        SizedBox(width: s.wp(.04)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                u['username'] ?? "User",
                                style: TextStyle(
                                  color: c.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: s.sp(.05),
                                  fontFamily: "RSO",
                                  height: 0.8,
                                ),
                              ),
                              SizedBox(height: s.hp(.012)),
                              Text(
                                u['email'] ?? "No Email",
                                style: TextStyle(
                                  color: c.card,
                                  fontWeight: FontWeight.w500,
                                  fontSize: s.sp(.04),
                                  fontFamily: "SSEC",
                                  height: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),

      // collapse button
      Positioned(
        left: 0,
        right: 0,
        bottom: s.w * 0.03,
        child: InkWell(
          onTap: _toggleExpand,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: s.wp(.27)),
            padding: EdgeInsets.symmetric(vertical: s.hp(.001)),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(s.rad(.09)),
            ),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: s.sp(.06),
              color: c.icon,
            ),
          ),
        ),
      ),
    ],
  );
}





  Widget _arrowButton(
      BuildContext context, bool expanded, VoidCallback onTap) {
    final s = S.of(context);
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s.rad(.02)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: s.wp(.03),
          vertical: s.hp(.001),
        ),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(s.rad(.15)),
        ),
        child: Icon(
          expanded
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: s.sp(.06),
          color: c.icon,
        ),
      ),
    );
  }
}
