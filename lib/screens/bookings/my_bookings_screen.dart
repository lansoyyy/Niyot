import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../core/booking_attention_counts.dart';
import '../../core/booking_policy.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../services/booking_service.dart';
import '../../services/booking_view_tracker.dart';
import '../../services/user_service.dart';
import '../../widgets/bookings/booking_action_summary_row.dart';
import '../../widgets/bookings/booking_list_card.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stream<List<BookingModel>>? _bookingsStream;
  bool _isPhotographer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initStream();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      BookingViewTracker.instance.init(uid);
    }
    BookingViewTracker.instance.addListener(_onViewTrackerChanged);
  }

  void _onViewTrackerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BookingViewTracker.instance.removeListener(_onViewTrackerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _initStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final cached = UserService().cachedUser;
    if (cached != null) {
      _isPhotographer = cached.isPhotographer;
      _setStream(uid, cached);
    } else {
      UserService().fetchCurrentUser().then((user) {
        if (!mounted || user == null) return;
        setState(() {
          _isPhotographer = user.isPhotographer;
          _setStream(uid, user);
        });
      });
    }
  }

  void _setStream(String uid, UserModel user) {
    _bookingsStream = user.isPhotographer
        ? BookingService().photographerBookingsStream(uid)
        : BookingService().clientBookingsStream(uid);
  }

  void _goToTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BookingViewTracker.instance,
      builder: (context, _) {
        return StreamBuilder<List<BookingModel>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

            final requested = all.where((b) {
              if (b.status == BookingStatus.paymentPending) return true;
              if (BookingPolicy.canRespondToReschedule(b, uid)) return true;
              return b.status == BookingStatus.requested &&
                  !b.isReschedulePending;
            }).toList()
              ..sort(
                (a, b) => a.scheduledSessionStart.compareTo(
                  b.scheduledSessionStart,
                ),
              );
            final upcoming = all.where((b) => b.isUpcoming).toList()
              ..sort(
                (a, b) => a.scheduledSessionStart.compareTo(
                  b.scheduledSessionStart,
                ),
              );
            final active = all.where((b) => b.isActive).toList()
              ..sort(
                (a, b) => a.scheduledSessionStart.compareTo(
                  b.scheduledSessionStart,
                ),
              );
            final past = all.where((b) => b.isPast).toList()
              ..sort(
                (a, b) => b.scheduledSessionStart.compareTo(
                  a.scheduledSessionStart,
                ),
              );

            final attention = _isPhotographer
                ? BookingAttentionCounts.forPhotographer(all, uid)
                : BookingAttentionCounts.forClient(all, uid);

            return Scaffold(
              backgroundColor: AppColors.gray50,
              body: SafeArea(
                child: Column(
                  children: [
                    _Header(
                      tabController: _tabController,
                      isPhotographer: _isPhotographer,
                      attention: attention,
                      requestedCount: requested.length,
                      upcomingCount: upcoming.length,
                      activeCount: active.length,
                      onSummaryTap: _goToTab,
                    ),
                    Expanded(
                      child: snapshot.connectionState ==
                              ConnectionState.waiting
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _TabList(
                                  bookings: requested,
                                  emptyLabel: 'No pending requests',
                                  emptyIcon: Icons.hourglass_empty_rounded,
                                  isPhotographer: _isPhotographer,
                                ),
                                _TabList(
                                  bookings: upcoming,
                                  emptyLabel: 'No upcoming sessions',
                                  emptyIcon: Icons.event_outlined,
                                  isPhotographer: _isPhotographer,
                                ),
                                _TabList(
                                  bookings: active,
                                  emptyLabel: 'No active sessions',
                                  emptyIcon: Icons.camera_enhance_outlined,
                                  isPhotographer: _isPhotographer,
                                ),
                                _TabList(
                                  bookings: past,
                                  emptyLabel: 'No past bookings',
                                  emptyIcon: Icons.history_rounded,
                                  isPhotographer: _isPhotographer,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tabController,
    required this.isPhotographer,
    required this.attention,
    required this.requestedCount,
    required this.upcomingCount,
    required this.activeCount,
    required this.onSummaryTap,
  });

  final TabController tabController;
  final bool isPhotographer;
  final BookingAttentionCounts attention;
  final int requestedCount;
  final int upcomingCount;
  final int activeCount;
  final void Function(int tabIndex) onSummaryTap;

  List<BookingActionSummaryItem> _summaryItems() {
    if (isPhotographer) {
      final items = <BookingActionSummaryItem>[];
      if (attention.bookingRequest > 0) {
        items.add(
          BookingActionSummaryItem(
            icon: Icons.calendar_month_rounded,
            iconBg: AppColors.warningLight,
            iconColor: AppColors.warning,
            count: attention.bookingRequest,
            label: 'Booking request',
            highlighted: true,
            onTap: () => onSummaryTap(0),
          ),
        );
      }
      if (attention.reschedule > 0) {
        items.add(
          BookingActionSummaryItem(
            icon: Icons.update_rounded,
            iconBg: AppColors.infoLight,
            iconColor: AppColors.info,
            count: attention.reschedule,
            label: 'Reschedule',
            highlighted: true,
            onTap: () => onSummaryTap(0),
          ),
        );
      }
      if (attention.cancel > 0) {
        items.add(
          BookingActionSummaryItem(
            icon: Icons.cancel_rounded,
            iconBg: AppColors.errorLight,
            iconColor: AppColors.error,
            count: attention.cancel,
            label: 'Cancel',
            highlighted: true,
            onTap: () => onSummaryTap(3),
          ),
        );
      }
      return items;
    }

    final items = <BookingActionSummaryItem>[];
    if (attention.pending > 0) {
      items.add(
        BookingActionSummaryItem(
          icon: Icons.hourglass_top_rounded,
          iconBg: AppColors.warningLight,
          iconColor: AppColors.warning,
          count: attention.pending,
          label: 'Pending',
          highlighted: attention.pending > 0,
          onTap: () => onSummaryTap(0),
        ),
      );
    }
    if (attention.reschedule > 0) {
      items.add(
        BookingActionSummaryItem(
          icon: Icons.update_rounded,
          iconBg: AppColors.infoLight,
          iconColor: AppColors.info,
          count: attention.reschedule,
          label: 'Reschedule',
          highlighted: true,
          onTap: () => onSummaryTap(0),
        ),
      );
    }
    if (attention.delivered > 0) {
      items.add(
        BookingActionSummaryItem(
          icon: Icons.download_rounded,
          iconBg: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF7B1FA2),
          count: attention.delivered,
          label: 'Delivered',
          highlighted: true,
          onTap: () => onSummaryTap(2),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final summaryItems = _summaryItems();

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Bookings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (summaryItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            BookingActionSummaryRow(items: summaryItems),
          ],
          const SizedBox(height: 14),
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.gray400,
            labelStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(
                text: requestedCount > 0
                    ? 'Requested ($requestedCount)'
                    : 'Requested',
              ),
              Tab(
                text: upcomingCount > 0
                    ? 'Upcoming ($upcomingCount)'
                    : 'Upcoming',
              ),
              Tab(
                text: activeCount > 0 ? 'Active ($activeCount)' : 'Active',
              ),
              const Tab(text: 'Past'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabList extends StatelessWidget {
  const _TabList({
    required this.bookings,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.isPhotographer,
  });

  final List<BookingModel> bookings;
  final String emptyLabel;
  final IconData emptyIcon;
  final bool isPhotographer;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: bookings.length,
      itemBuilder: (context, index) => BookingListCard(
        booking: bookings[index],
        isPhotographer: isPhotographer,
      ),
    );
  }
}
