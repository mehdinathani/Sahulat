import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/provider.dart';
import '../services/map_service.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import 'booking_summary.dart';

/// Full-screen Google Maps view showing service providers as category-coloured
/// markers. Tapping a marker slides up a bottom card with provider details and
/// a "Book Now" CTA.
class ProvidersMapScreen extends StatefulWidget {
  final List<ServiceProvider> providers;
  /// If set, the map zooms directly to this provider on open.
  final ServiceProvider? focusedProvider;

  const ProvidersMapScreen({
    super.key,
    required this.providers,
    this.focusedProvider,
  });

  @override
  State<ProvidersMapScreen> createState() => _ProvidersMapScreenState();
}

class _ProvidersMapScreenState extends State<ProvidersMapScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  Set<Marker> _markers = {};
  LatLng _initialCenter = MapService.kDefaultCenter;
  ServiceProvider? _selectedProvider;
  bool _locationLoaded = false;

  // Bottom card animation
  late AnimationController _cardAnim;
  late Animation<Offset> _cardSlide;

  // Category filter — null means 'all'
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));

    _initLocation();
    _buildMarkers();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final userLoc = await MapService.getUserLocation();
    if (!mounted) return;
    if (userLoc != null) {
      setState(() {
        _initialCenter = userLoc;
        _locationLoaded = true;
      });
    } else {
      // Fall back to first provider's position or default Karachi
      final first = widget.providers
          .map((p) => p.resolvedLatLng)
          .whereType<LatLng>()
          .firstOrNull;
      if (first != null) setState(() => _initialCenter = first);
    }

    // If a focused provider is set, animate camera there after map is ready
    if (widget.focusedProvider != null) {
      final focusPos = widget.focusedProvider!.resolvedLatLng;
      if (focusPos != null) {
        final controller = await _controllerCompleter.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: focusPos, zoom: 16),
          ),
        );
        _selectProvider(widget.focusedProvider!);
      }
    } else {
      _fitAllProviders();
    }
  }

  void _buildMarkers() {
    final filtered = _activeFilter == null
        ? widget.providers
        : widget.providers
            .where((p) => p.serviceType.toLowerCase() == _activeFilter)
            .toList();

    setState(() {
      _markers = MapService.buildProviderMarkers(filtered, _selectProvider);
    });
  }

  Future<void> _fitAllProviders() async {
    final bounds = MapService.computeBounds(widget.providers);
    if (bounds == null) return;
    final controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _goToMyLocation() async {
    final loc = await MapService.getUserLocation();
    if (loc == null) return;
    final controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: loc, zoom: 15),
    ));
  }

  void _selectProvider(ServiceProvider provider) {
    setState(() => _selectedProvider = provider);
    _cardAnim.forward();
  }

  void _dismissCard() {
    _cardAnim.reverse().then((_) {
      if (mounted) setState(() => _selectedProvider = null);
    });
  }

  Future<void> _applyMapStyle(GoogleMapController controller) async {
    final settings = context.read<SettingsProvider>();
    final style = await MapService.loadMapStyle(settings.themeMode, context);
    // ignore: deprecated_member_use
    controller.setMapStyle(style);
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
    _applyMapStyle(controller);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = widget.providers
        .map((p) => p.serviceType.toLowerCase())
        .toSet()
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: _locationLoaded,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onTap: (_) => _dismissCard(),
          ),

          // ── Top header bar ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + title pill
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _GlassPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.providers.length} Provider${widget.providers.length != 1 ? 's' : ''} Nearby',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Fit all FAB
                      _GlassPill(
                        onTap: _fitAllProviders,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fit_screen_rounded, size: 18,
                                color: SahulatTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text('Fit All',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: SahulatTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Category filter chips
                if (categories.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _activeFilter == null,
                          onTap: () {
                            setState(() => _activeFilter = null);
                            _buildMarkers();
                          },
                        ),
                        ...categories.map((cat) => _FilterChip(
                          label: MapService.categoryLabel(cat),
                          selected: _activeFilter == cat,
                          onTap: () {
                            setState(() => _activeFilter = cat);
                            _buildMarkers();
                          },
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── My Location FAB ───────────────────────────────────────────────
          Positioned(
            bottom: _selectedProvider != null ? 300 : 32,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: FloatingActionButton(
                heroTag: 'map_location_fab',
                mini: true,
                backgroundColor: SahulatTheme.primaryColor,
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // ── Provider bottom card ──────────────────────────────────────────
          if (_selectedProvider != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _cardSlide,
                child: _ProviderBottomCard(
                  provider: _selectedProvider!,
                  isDark: isDark,
                  onDismiss: _dismissCard,
                  onBook: () {
                    _dismissCard();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingSummaryScreen(
                          provider: _selectedProvider!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Glassmorphic pill container ─────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _GlassPill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? SahulatTheme.primaryColor
              : (isDark
                  ? Colors.black.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.88)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? SahulatTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Provider bottom card ─────────────────────────────────────────────────────

class _ProviderBottomCard extends StatelessWidget {
  final ServiceProvider provider;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onBook;

  const _ProviderBottomCard({
    required this.provider,
    required this.isDark,
    required this.onDismiss,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? SahulatTheme.darkSurface : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SahulatTheme.primaryColor.withValues(alpha: 0.8),
                      SahulatTheme.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconFor(provider.serviceType),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MapService.categoryLabel(provider.serviceType),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: SahulatTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _Stat(icon: Icons.star_rounded, value: provider.rating.toStringAsFixed(1), color: const Color(0xFFF59E0B)),
              const SizedBox(width: 20),
              _Stat(icon: Icons.location_on_rounded, value: '${provider.distance} km', color: SahulatTheme.primaryColor),
              const SizedBox(width: 20),
              _Stat(icon: Icons.payments_rounded, value: 'Rs.${provider.pricePerHour}/hr', color: SahulatTheme.secondaryColor),
              const SizedBox(width: 20),
              _Stat(
                icon: provider.availability ? Icons.check_circle_rounded : Icons.cancel_rounded,
                value: provider.availability ? 'Available' : 'Busy',
                color: provider.availability ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Location text
          Row(
            children: [
              Icon(Icons.place_outlined, size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 4),
              Text(
                provider.location,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Book Now button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: provider.availability ? onBook : null,
              icon: const Icon(Icons.calendar_month_rounded, size: 20),
              label: Text(
                provider.availability ? 'Book Now' : 'Not Available',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SahulatTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'electrician': return Icons.electrical_services_rounded;
      case 'plumber':     return Icons.plumbing_rounded;
      case 'ac_repair':
      case 'ac repair':  return Icons.ac_unit_rounded;
      case 'tutor':       return Icons.school_rounded;
      case 'cleaning':    return Icons.cleaning_services_rounded;
      default:            return Icons.build_rounded;
    }
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Stat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}
