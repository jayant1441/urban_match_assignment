import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:urban_match_assignment/features/events/presentation/notifier/event_notifier.dart';

class MapWithBottomSheetScreen extends ConsumerStatefulWidget {
  const MapWithBottomSheetScreen({super.key});

  @override
  ConsumerState<MapWithBottomSheetScreen> createState() =>
      _MapWithBottomSheetScreenState();
}

class _MapWithBottomSheetScreenState
    extends ConsumerState<MapWithBottomSheetScreen> {
  final MapController _mapController = MapController();
  late final StreamSubscription<List<ConnectivityResult>> _connSub;
  int? _selectedIndex;
  bool _showUpcoming = true;
  Key _mapKey = UniqueKey();

  static const _markerPoints = [
    LatLng(28.6139, 77.2090),
    LatLng(28.6239, 77.2190),
    LatLng(28.6039, 77.1990),
    LatLng(28.6139, 77.2290),
  ];

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((c) {
      if (c.contains(ConnectivityResult.wifi) ||
          c.contains(ConnectivityResult.mobile)) {
        ref.read(eventNotifierProvider.notifier).fetch();
      }
    });

    _connSub = Connectivity().onConnectivityChanged.listen((c) {
      if (c.contains(ConnectivityResult.wifi) ||
          c.contains(ConnectivityResult.mobile)) {
        ref.read(eventNotifierProvider.notifier).fetch();

        setState(() {
          // force FlutterMap to rebuild & re-request tiles
          _mapKey = UniqueKey();
        });
      }
    });
  }

  @override
  void dispose() {
    _connSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventNotifierProvider);

    final markers = List<Marker>.generate(_markerPoints.length, (i) {
      final selected = i == _selectedIndex;
      return Marker(
        point: _markerPoints[i],
        width: selected ? 100 : 60,
        height: selected ? 100 : 60,
        child: Icon(
          Icons.whatshot,
          color: selected ? Colors.orange : Colors.orange.shade200,
          size: selected ? 40 : 28,
        ),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // Dark map
          Positioned.fill(
            child: FlutterMap(
              key: _mapKey,
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _markerPoints[0],
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: ClipOval(
              child: Material(
                color: Colors.black54, // semi-transparent background
                child: InkWell(
                  splashColor: Colors.orange.withValues(alpha: 0.5),
                  onTap: () {
                    _mapController.rotate(0);
                    _mapController.move(LatLng(28.6139, 77.2090), 13);
                  },
                  child: const SizedBox(
                    width: 60,
                    height: 60,
                    child: Icon(
                      Icons.explore, // compass-style icon
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom sheet with filters + list
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.5,
            builder: (ctx, sc) => Container(
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Upcoming'),
                          selected: _showUpcoming,
                          selectedColor: Colors.orange,
                          backgroundColor: Colors.grey[800]!,
                          labelStyle: TextStyle(
                            color: _showUpcoming
                                ? Colors.white
                                : Colors.white70,
                          ),
                          onSelected: (_) => setState(() {
                            _showUpcoming = true;
                            _selectedIndex = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Past'),
                          selected: !_showUpcoming,
                          selectedColor: Colors.orange,
                          backgroundColor: Colors.grey[800]!,
                          labelStyle: TextStyle(
                            color: !_showUpcoming
                                ? Colors.white
                                : Colors.white70,
                          ),
                          onSelected: (_) => setState(() {
                            _showUpcoming = false;
                            _selectedIndex = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 1),

                  // Event list
                  Expanded(child: _buildList(state, sc)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(EventState state, ScrollController sc) {
    final now = DateTime.now();

    if (state is LoadingState) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (state is ErrorState) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load events',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(eventNotifierProvider.notifier).fetch(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (state is LoadedState) {
      final filtered = state.events
          .where(
            (e) => _showUpcoming ? e.time.isAfter(now) : e.time.isBefore(now),
          )
          .toList();

      if (filtered.isEmpty) {
        return const Center(
          child: Text(
            'No events found',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView.builder(
        controller: sc,
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final e = filtered[i];
          final origIdx = state.events.indexOf(e);
          final selected = origIdx == _selectedIndex;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = origIdx;
                _mapController.move(_markerPoints[origIdx], 15);
              });
            },
            child: Container(
              color: selected ? Colors.orange.withOpacity(0.2) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.whatshot,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d • h:mm a').format(e.time),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
