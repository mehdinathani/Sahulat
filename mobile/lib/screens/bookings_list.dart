import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Lightweight date formatter — avoids the intl package dependency.
String _formatDate(DateTime dt) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m $ampm';
}

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final bookings = await _apiService.getBookings();
      // Sort bookings by creation date descending
      bookings.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'BOOKED':
        return colorScheme.primary;
      case 'REMINDED':
      case 'ON_THE_WAY':
        return SahulatTheme.warningColor;
      case 'COMPLETED':
      case 'DONE':
        return SahulatTheme.successColor;
      default:
        return SahulatTheme.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Failed to load bookings', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_error!, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchBookings,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? Center(
                      child: Text(
                        'No bookings found.',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final providerId = booking['providerId'] ?? 'Unknown Provider';
                          final status = booking['status'] ?? 'UNKNOWN';
                          final dateStr = booking['createdAt'] ?? booking['scheduledTime'];
                          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
                          final formattedDate = date != null ? _formatDate(date.toLocal()) : 'Unknown date';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          providerId,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status, theme.colorScheme).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getStatusColor(status, theme.colorScheme),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(status, theme.colorScheme),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                      const SizedBox(width: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  if (booking['latest_notification'] != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: SahulatTheme.warningColor.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: SahulatTheme.warningColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.notifications_active, color: SahulatTheme.warningColor, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              booking['latest_notification'],
                                              style: const TextStyle(fontSize: 13, color: SahulatTheme.warningColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
