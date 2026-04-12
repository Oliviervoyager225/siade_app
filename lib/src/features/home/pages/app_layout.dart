import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siade2/src/core/services/call_service.dart';
import 'package:siade2/src/core/services/chat_service.dart';
import 'package:siade2/src/core/services/notification_service.dart';
import 'package:siade2/src/core/services/presence_service.dart';
import 'package:siade2/src/features/home/pages/call_page.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:siade2/src/theme/theme.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with WidgetsBindingObserver {
  int _currentIndex = 2;
  final _chat = ChatService();
  final _presence = PresenceService();
  final _callSvc = CallService();
  final _notifSvc = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presence.setOnline();
    // Quand une notif push arrive → ouvrir l'onglet Alertes
    NotificationService.onNavigateToAlerts = () {
      if (mounted) setState(() => _currentIndex = 3);
    };
    NotificationService.onNavigateToLive = (liveId, channelName, hostName, hostPhoto) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Live(
          liveId: liveId,
          channelName: channelName,
          hostName: hostName,
          hostPhotoUrl: hostPhoto,
        ),
      ));
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presence.setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _presence.setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _presence.setOffline();
    }
  }

  late final List<Widget> _pages = [
    CustomDrawer(onGoHome: () => setState(() => _currentIndex = 2)),
    ChatPage(),
    HomePage(),
    AlertPage(),
    ProfilePage(),
  ];

  final List<dynamic> icons = [
    Icons.newspaper_sharp,
    Icons.mark_as_unread_sharp,
    Icons.home_outlined,
    Icons.notifications_none,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (_currentIndex != 2) {
          setState(() => _currentIndex = 2);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Stack(
        children: [
          SafeArea(
            child: Scaffold(
          backgroundColor: isLight ? Colors.white : null,
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: Container(
          color: isLight ? const Color(0xFFEAEAEA) : Colors.black,
          padding: const EdgeInsets.only(left: 50.0, right: 50.0, top: 10),
          child: StreamBuilder<int>(
            stream: _chat.watchTotalUnreadStream(),
            initialData: 0,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return StreamBuilder<int>(
                stream: _notifSvc.watchUnreadCount(),
                initialData: 0,
                builder: (context, notifSnap) {
                  final unreadNotif = notifSnap.data ?? 0;
                  return NavigationBar(
                indicatorShape: CircleBorder(),
                backgroundColor: isLight ? const Color(0xFFEAEAEA) : Colors.black,
                elevation: 0,
                shadowColor: isLight ? Colors.black12 : null,
                selectedIndex: _currentIndex,
                destinations: icons.map((item) {
                  final index = icons.indexOf(item);
                  final isSelected = _currentIndex == index;
                  final isMsgIcon = index == 1;
                  final isBellIcon = index == 3;

                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    child: AnimatedContainer(
                      width: 60,
                      height: 60,
                      duration: Duration(milliseconds: 0),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isLight
                                    ? [Color(0xFF60438C), Colors.white]
                                    : [AppColors.primaryBlue, AppColors.primaryRed],
                              )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            item,
                            color: isSelected
                                ? Colors.white
                                : (isLight ? Color(0xFF60438C) : Colors.grey),
                            size: isSelected ? 30 : 24,
                          ),
                          // Badge messages non lus
                          if (isMsgIcon && unreadCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _Badge(count: unreadCount, bg: Colors.red, parentIsLight: isLight),
                            ),
                          // Badge notifications non lues
                          if (isBellIcon && unreadNotif > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _Badge(count: unreadNotif, bg: Colors.red, parentIsLight: isLight),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
                },
              );
            },
          ),
        ),
          ),
        ),
        // ── Overlay appel entrant ──────────────────────────────────────────
        StreamBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
          stream: _callSvc.watchIncomingCall(),
          builder: (ctx, snap) {
            final doc = snap.data;
            if (doc == null) return const SizedBox.shrink();
            final data = doc.data();
            final channelName = data['channelName'] as String? ?? '';
            final callerName = data['callerName'] as String? ?? '';
            final callerPhoto = data['callerPhoto'] as String? ?? '';
            final isVideo = data['type'] == 'video';
            return IncomingCallOverlay(
              callId: doc.id,
              channelName: channelName,
              callerName: callerName,
              callerPhoto: callerPhoto,
              isVideo: isVideo,
              onReject: () => _callSvc.rejectCall(doc.id),
              onAccept: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => CallPage(
                      callId: doc.id,
                      channelName: channelName,
                      isVideo: isVideo,
                      isCaller: false,
                      otherName: callerName,
                      otherPhoto: callerPhoto.isNotEmpty ? callerPhoto : null,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color bg;
  final bool parentIsLight;
  const _Badge(
      {required this.count,
      required this.bg,
      required this.parentIsLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: parentIsLight ? const Color(0xFFEAEAEA) : Colors.black,
            width: 1.5),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
