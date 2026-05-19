import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../theme.dart';

class ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onBook;
  /// Optional callback when the user taps the map icon on this card.
  final VoidCallback? onViewMap;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.onBook,
    this.onViewMap,
  });

  IconData _getCategoryIcon(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('plumb'))    return Icons.plumbing_rounded;
    if (type.contains('electr'))   return Icons.electrical_services_rounded;
    if (type.contains('tutor') || type.contains('teach')) return Icons.school_rounded;
    if (type.contains('clean'))    return Icons.cleaning_services_rounded;
    if (type.contains('ac'))       return Icons.ac_unit_rounded;
    return Icons.build_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMapLocation = provider.resolvedLatLng != null;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? SahulatTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ─────────────────────────────────────────────
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SahulatTheme.primaryColor.withValues(alpha: 0.85),
                    SahulatTheme.primaryColor.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(provider.serviceType),
                      size: 44,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  // Availability badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: provider.availability
                            ? const Color(0xFF22C55E).withValues(alpha: 0.9)
                            : const Color(0xFFEF4444).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.availability ? 'Available' : 'Busy',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Map icon button (top left) — only show if location is resolvable
                  if (hasMapLocation && onViewMap != null)
                    Positioned(
                      top: 8,
                      left: 10,
                      child: GestureDetector(
                        onTap: onViewMap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.star_rounded,
                          color: const Color(0xFFF59E0B), size: 15),
                      const SizedBox(width: 2),
                      Text(
                        provider.rating.toStringAsFixed(1),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    provider.serviceType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SahulatTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Distance + price
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${provider.distance} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Rs.${provider.pricePerHour}/hr',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SahulatTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action row: Map + Book
                  Row(
                    children: [
                      // View on Map button (only if location resolvable)
                      if (hasMapLocation && onViewMap != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onViewMap,
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SahulatTheme.primaryColor,
                              side: BorderSide(
                                color: SahulatTheme.primaryColor.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _BookButton(onBook: onBook, available: provider.availability),
                        ),
                      ] else
                        Expanded(
                          child: _BookButton(onBook: onBook, available: provider.availability),
                        ),
                    ],
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

class _BookButton extends StatelessWidget {
  final VoidCallback onBook;
  final bool available;
  const _BookButton({required this.onBook, required this.available});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: available ? onBook : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: SahulatTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        elevation: 0,
      ),
      child: Text(
        available ? 'Book Now' : 'Unavailable',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
