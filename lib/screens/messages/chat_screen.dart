import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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

  static const _gradients = [
    [Color(0xFF6B0000), Color(0xFFC62828)],
    [Color(0xFF4A0000), Color(0xFF880E0E)],
    [Color(0xFF1A237E), Color(0xFF3949AB)],
    [Color(0xFF1B5E20), Color(0xFF388E3C)],
    [Color(0xFF004D40), Color(0xFF00897B)],
    [Color(0xFFBF360C), Color(0xFFE64A19)],
    [Color(0xFF4A148C), Color(0xFF7B1FA2)],
  ];

  List<Color> _otherGradient(String userId) {
    final index =
        userId.codeUnits.fold<int>(0, (sum, c) => sum + c) % _gradients.length;
    return _gradients[index].cast<Color>();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime date) {
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
    _isPhotographer = UserService().cachedUser?.isPhotographer ?? false;
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
      if (mounted) setState(() => _isSending = false);
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
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showSendOfferDialog() async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
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
                    const SizedBox(height: 20),
                    _OfferTextField(
                      controller: titleController,
                      label: 'Package / Service Name',
                      hint: 'e.g. Wedding Package',
                      icon: Icons.work_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _OfferTextField(
                      controller: durationController,
                      label: 'Duration',
                      hint: 'e.g. 4 hours',
                      icon: Icons.schedule_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _OfferTextField(
                      controller: priceController,
                      label: 'Price (₱)',
                      hint: 'e.g. 500',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null)
                          return 'Enter a valid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _OfferTextField(
                      controller: locationController,
                      label: 'Location',
                      hint: 'e.g. Manila, Metro Manila',
                      icon: Icons.location_on_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFC62828),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      child: _OfferPickerTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: _formatDate(selectedDate),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Time picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFC62828),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      child: _OfferPickerTile(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: selectedTime.format(ctx),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final senderName =
                              UserService().cachedUser?.name ??
                              _currentUser?.displayName ??
                              'Photographer';
                          final timeStr = selectedTime.format(ctx);
                          Navigator.of(ctx).pop();
                          setState(() => _isSending = true);
                          try {
                            await MessagingService().sendCustomOffer(
                              conversationId: widget.conversationId,
                              senderId: uid,
                              senderName: senderName,
                              offerData: {
                                'title': titleController.text.trim(),
                                'description': durationController.text.trim(),
                                'price': int.parse(priceController.text.trim()),
                                'date': selectedDate.toIso8601String(),
                                'time': timeStr,
                                'location': locationController.text.trim(),
                                'photographerId': uid,
                                'photographerName': senderName,
                                'clientId': widget.otherUserId,
                                'clientName': widget.otherUserName,
                              },
                            );
                            _scrollToBottom();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to send offer: $e'),
                                backgroundColor: const Color(0xFFC62828),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isSending = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
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
            ),
          ),
        ),
      ),
    );

    titleController.dispose();
    durationController.dispose();
    priceController.dispose();
    locationController.dispose();
  }

  Future<void> _acceptOffer(MessageModel message) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    final offerData = message.offerData!;
    setState(() => _isSending = true);
    try {
      // Create confirmed booking
      final clientName =
          UserService().cachedUser?.name ??
          _currentUser?.displayName ??
          offerData['clientName'] as String? ??
          'Client';
      final booking = BookingModel(
        id: '',
        clientId: uid,
        clientName: clientName,
        clientPhotoUrl: UserService().cachedUser?.photoUrl,
        photographerId: offerData['photographerId'] as String? ?? '',
        photographerName: offerData['photographerName'] as String? ?? '',
        photographerPhotoUrl: null,
        packageName: offerData['title'] as String? ?? 'Custom Package',
        packagePrice: (offerData['price'] as num?)?.toInt() ?? 0,
        packageDuration: offerData['description'] as String? ?? '',
        scheduledDate:
            DateTime.tryParse(offerData['date'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 1)),
        scheduledTime: offerData['time'] as String? ?? '',
        location: offerData['location'] as String? ?? '',
        notes: 'Booked via custom offer in chat.',
        status: BookingStatus.confirmed,
        createdAt: DateTime.now(),
      );

      final bookingId = await BookingService().createDirectBooking(booking);
      await MessagingService().updateOfferStatus(
        conversationId: widget.conversationId,
        messageId: message.id,
        status: 'accepted',
        bookingId: bookingId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Offer accepted! Booking added to your upcoming.',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept offer: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _declineOffer(MessageModel message) async {
    await MessagingService().updateOfferStatus(
      conversationId: widget.conversationId,
      messageId: message.id,
      status: 'declined',
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _otherGradient(widget.otherUserId);

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
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(widget.otherUserName),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
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
                          _OfferBubble(
                            message: message,
                            isMe: isMe,
                            isClient: !_isPhotographer,
                            time: _formatTime(message.timestamp),
                            onAccept: () => _acceptOffer(message),
                            onDecline: () => _declineOffer(message),
                          )
                        else
                          _MessageBubble(
                            text: message.text,
                            mediaUrl: message.mediaUrl,
                            mediaType: message.mediaType,
                            time: _formatTime(message.timestamp),
                            isMe: isMe,
                            gradient: gradient,
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
                if (_isPhotographer) ...[
                  IconButton(
                    onPressed: _isSending ? null : _showSendOfferDialog,
                    icon: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFFC62828),
                      size: 22,
                    ),
                    tooltip: 'Send Custom Offer',
                  ),
                ],
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
                      gradient: LinearGradient(
                        colors: _isSending
                            ? const [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]
                            : const [Color(0xFF6B0000), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1))))
      return 'Yesterday';
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

// ─── Offer Bubble ─────────────────────────────────────────────────────────────

class _OfferBubble extends StatelessWidget {
  const _OfferBubble({
    required this.message,
    required this.isMe,
    required this.isClient,
    required this.time,
    required this.onAccept,
    required this.onDecline,
  });

  final MessageModel message;
  final bool isMe;
  final bool isClient;
  final String time;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  String _formatOfferDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
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

  @override
  Widget build(BuildContext context) {
    final offer = message.offerData ?? {};
    final status = message.offerStatus ?? 'pending';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAccepted
                ? const Color(0xFF2E7D32)
                : isPending
                ? const Color(0xFFC62828)
                : const Color(0xFFE5E7EB),
            width: isPending || isAccepted ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFFC62828),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Custom Offer',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isAccepted
                          ? const Color(0xFFE8F5E9)
                          : isPending
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAccepted
                          ? 'Accepted'
                          : isPending
                          ? 'Pending'
                          : 'Declined',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAccepted
                            ? const Color(0xFF2E7D32)
                            : isPending
                            ? const Color(0xFFFF8F00)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Offer details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title'] as String? ?? 'Custom Package',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OfferDetailRow(
                    icon: Icons.schedule_rounded,
                    text: offer['description'] as String? ?? '',
                  ),
                  const SizedBox(height: 6),
                  _OfferDetailRow(
                    icon: Icons.calendar_today_rounded,
                    text: _formatOfferDate(offer['date'] as String?),
                  ),
                  const SizedBox(height: 6),
                  _OfferDetailRow(
                    icon: Icons.access_time_rounded,
                    text: offer['time'] as String? ?? '',
                  ),
                  const SizedBox(height: 6),
                  _OfferDetailRow(
                    icon: Icons.location_on_rounded,
                    text: offer['location'] as String? ?? '',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '₱${offer['price'] ?? 0}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                  // Accept/Decline buttons - only for client and only when pending
                  if (isClient && isPending) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDecline,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFFBDBDBD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferDetailRow extends StatelessWidget {
  const _OfferDetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Offer Form Helpers ────────────────────────────────────────────────────────

class _OfferTextField extends StatelessWidget {
  const _OfferTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFFBDBDBD),
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828)),
        ),
      ),
    );
  }
}

class _OfferPickerTile extends StatelessWidget {
  const _OfferPickerTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9E9E9E),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─── Regular Message Bubble ────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.time,
    required this.isMe,
    required this.gradient,
  });

  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String time;
  final bool isMe;
  final List<Color> gradient;

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
          gradient: isMe
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : Colors.white,
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
