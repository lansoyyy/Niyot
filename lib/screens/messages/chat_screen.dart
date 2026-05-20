import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_avatar_colors.dart';
import '../../core/offer_expiration.dart';
import '../../models/user_model.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/currency/peso_price_text.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/availability_model.dart';
import '../../models/booking_model.dart';
import '../../models/message_model.dart';
import '../../services/booking_service.dart';
import '../../services/messaging_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _currentUser = FirebaseAuth.instance.currentUser;

  bool _isSending = false;
  bool _isPhotographer = false;
  final Set<String> _processingOffers = <String>{};

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final cached = UserService().cachedUser;
    if (cached != null) {
      _isPhotographer = cached.isPhotographer;
    } else {
      UserService().fetchCurrentUser().then((user) {
        if (mounted && user != null) {
          setState(() => _isPhotographer = user.isPhotographer);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = _currentUser?.uid;
      if (uid != null) {
        await MessagingService().markConversationRead(
          widget.conversationId,
          uid,
        );
      }
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showCustomOfferDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomOfferSheet(
        onSend: (name, price, dateTime) async {
          final uid = _currentUser?.uid;
          if (uid == null) return;
          final senderName =
              UserService().cachedUser?.name ??
              _currentUser?.displayName ??
              'Photographer';
          setState(() => _isSending = true);
          try {
            await MessagingService().sendCustomOffer(
              conversationId: widget.conversationId,
              senderId: uid,
              senderName: senderName,
              offerName: name,
              offerPrice: price,
              offerDateTime: dateTime,
            );
            _scrollToBottom();
          } finally {
            if (mounted) setState(() => _isSending = false);
          }
        },
      ),
    );
  }

  Future<void> _respondToOffer(MessageModel msg, String status) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    if (_processingOffers.contains(msg.id)) return;

    setState(() => _processingOffers.add(msg.id));
    try {
      if (status == 'accepted') {
        final cachedClient = UserService().cachedUser;
        final clientName =
            cachedClient?.name ?? _currentUser?.displayName ?? 'Client';
        final dateTime =
            msg.offerDateTime ?? DateTime.now().add(const Duration(days: 1));
        final scheduledTime =
            AvailabilityModel.snapDateTimeToGridSlotLabel(dateTime);
        final scheduledDate =
            DateTime(dateTime.year, dateTime.month, dateTime.day);
        final slotFree = await BookingService().isTimeSlotAvailable(
          photographerId: msg.senderId,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
        );
        if (!slotFree) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'That time slot is already booked. Ask the photographer for another time.',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                backgroundColor: const Color(0xFFC62828),
              ),
            );
          }
          return;
        }

        final booking = BookingModel(
          id: '',
          clientId: uid,
          clientName: clientName,
          clientPhotoUrl: cachedClient?.photoUrl,
          photographerId: msg.senderId,
          photographerName: widget.otherUserName,
          photographerPhotoUrl: null,
          packageName: msg.offerName ?? 'Custom Package',
          packagePrice: msg.offerPrice ?? 0,
          packageDuration: '',
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          location: '',
          notes: 'Booked via custom offer in chat.',
          status: BookingStatus.requested,
          createdAt: DateTime.now(),
        );
        final bookingId =
            await BookingService().createBookingFromAcceptedOffer(booking);
        await MessagingService().updateOfferStatus(
          conversationId: widget.conversationId,
          messageId: msg.id,
          status: 'accepted',
          bookingId: bookingId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Offer accepted! Your request was sent to the photographer for approval.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        await MessagingService().respondToOffer(
          conversationId: widget.conversationId,
          messageId: msg.id,
          status: status,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Offer declined.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: const Color(0xFF6B7280),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not ${status == 'accepted' ? 'accept' : 'decline'} the offer: $e',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingOffers.remove(msg.id));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final uid = _currentUser?.uid;
    if (text.isEmpty || uid == null || _isSending) return;

    final senderName =
        UserService().cachedUser?.name ??
        _currentUser?.displayName ??
        _currentUser?.email ??
        'User';

    setState(() => _isSending = true);
    try {
      await MessagingService().sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderName: senderName,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final uid = _currentUser?.uid;
    if (uid == null || _isSending) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final senderName =
        UserService().cachedUser?.name ??
        _currentUser?.displayName ??
        _currentUser?.email ??
        'User';
    final caption = _messageController.text.trim();
    final extension = pickedFile.path.contains('.')
        ? pickedFile.path.split('.').last
        : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$uid.$extension';

    setState(() => _isSending = true);
    try {
      final imageUrl = await StorageService().uploadChatAttachment(
        widget.conversationId,
        fileName,
        File(pickedFile.path),
      );

      await MessagingService().sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderName: senderName,
        text: caption,
        mediaUrl: imageUrl,
        mediaType: 'image',
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send image right now.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF374151),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: StreamBuilder<UserModel?>(
          stream: UserService().userStream(widget.otherUserId),
          builder: (context, snap) {
            final u = snap.data;
            final name = (u?.name.trim().isNotEmpty ?? false)
                ? u!.name
                : widget.otherUserName;
            final photoUrl = u?.photoUrl;
            return Row(
              children: [
                AppProfileAvatar(
                  displayName: name,
                  photoUrl: photoUrl,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Conversation',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: MessagingService().messagesStream(widget.conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <MessageModel>[];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC62828)),
                  );
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  );
                }

                final uid = _currentUser?.uid ?? '';
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  _scrollToBottom();
                  if (uid.isNotEmpty) {
                    await MessagingService().markConversationRead(
                      widget.conversationId,
                      uid,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.isSentBy(uid);
                    final showDayLabel =
                        index == 0 ||
                        !_isSameDay(
                          message.timestamp,
                          messages[index - 1].timestamp,
                        );

                    return Column(
                      children: [
                        if (showDayLabel)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _dayLabel(message.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFFBDBDBD),
                              ),
                            ),
                          ),
                        if (message.isCustomOffer)
                          _OfferCard(
                            message: message,
                            isMe: isMe,
                            canRespond: !isMe && message.isOfferPending,
                            isProcessing: _processingOffers.contains(message.id),
                            onAccept: () =>
                                _respondToOffer(message, 'accepted'),
                            onDecline: () =>
                                _respondToOffer(message, 'declined'),
                          )
                        else
                          _MessageBubble(
                            text: message.text,
                            mediaUrl: message.mediaUrl,
                            mediaType: message.mediaType,
                            time: _formatTime(message.timestamp),
                            isMe: isMe,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickAndSendImage,
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: Color(0xFF9E9E9E),
                    size: 22,
                  ),
                ),
                if (_isPhotographer)
                  IconButton(
                    onPressed: _isSending ? null : _showCustomOfferDialog,
                    tooltip: 'Send custom offer',
                    icon: const Icon(
                      Icons.local_offer_rounded,
                      color: Color(0xFFC62828),
                      size: 22,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFFBDBDBD),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? const Color(0xFFBDBDBD)
                          : const Color(0xFFC62828),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSending
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.message,
    required this.isMe,
    required this.canRespond,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
  });

  final MessageModel message;
  final bool isMe;
  final bool canRespond;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  Timer? _expiryTicker;

  @override
  void initState() {
    super.initState();
    if (widget.message.offerExpiresAt != null &&
        widget.message.offerStatus == null &&
        !widget.message.isOfferExpired) {
      _expiryTicker = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _expiryTicker?.cancel();
    super.dispose();
  }

  String _formatOfferDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  •  $displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final status = message.offerStatus;
    final expired = message.isOfferExpired;
    Color statusColor;
    String statusLabel;
    if (status == 'accepted') {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'Accepted';
    } else if (status == 'declined') {
      statusColor = const Color(0xFFC62828);
      statusLabel = 'Declined';
    } else if (expired) {
      statusColor = const Color(0xFF9E9E9E);
      statusLabel = 'Expired';
    } else {
      statusColor = const Color(0xFFFF8F00);
      statusLabel = 'Pending';
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppAvatarColors.profileHeaderBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Custom Offer',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.offerName ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  PesoPriceText(
                    message.offerPrice ?? 0,
                    freeLabel: 'Free',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                  if (message.offerDateTime != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatOfferDate(message.offerDateTime!),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF7A7A7A),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (message.offerExpiresAt != null &&
                      status == null &&
                      !expired) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: Color(0xFFFF8F00),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          OfferExpiration.hoursRemainingLabel(
                            message.offerExpiresAt!,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFFF8F00),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.canRespond) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.isProcessing
                                ? null
                                : widget.onDecline,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFBDBDBD)),
                              foregroundColor: const Color(0xFF6B7280),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.isProcessing
                                ? null
                                : widget.onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE5BDBD),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: widget.isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Accept',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (status != null || expired)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          status == 'accepted'
                              ? 'You accepted this offer'
                              : status == 'declined'
                              ? 'You declined this offer'
                              : 'This offer has expired',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomOfferSheet extends StatefulWidget {
  const _CustomOfferSheet({required this.onSend});

  final Future<void> Function(String name, int price, DateTime dateTime) onSend;

  @override
  State<_CustomOfferSheet> createState() => _CustomOfferSheetState();
}

class _CustomOfferSheetState extends State<_CustomOfferSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: Color(0xFFC62828)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: Color(0xFFC62828)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    if (name.isEmpty || priceText.isEmpty) return;
    final price = int.tryParse(priceText);
    if (price == null || price <= 0) return;

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSending = true);
    await widget.onSend(name, price, dt);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Send Custom Offer',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Client will see this as a card with Accept / Decline options.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 20),
            _sheetLabel('Offer Name'),
            const SizedBox(height: 8),
            _sheetField(
              controller: _nameController,
              hint: 'e.g. Wedding Premium Package',
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),
            _sheetLabel('Price (PHP)'),
            const SizedBox(height: 8),
            _sheetField(
              controller: _priceController,
              hint: '500',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _sheetLabel('Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(_selectedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedTime.format(context),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Send Offer',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF374151),
    ),
  );

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFFBDBDBD),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFC62828) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (mediaType == 'image' && mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaUrl!,
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 180,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: isMe ? Colors.white : const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ),
              if (text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (text.isNotEmpty)
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isMe ? Colors.white : const Color(0xFF374151),
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
