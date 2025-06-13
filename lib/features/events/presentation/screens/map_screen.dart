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

  // Sample marker coords around Delhi
  final _markerPoints = const [
    LatLng(28.6139, 77.2090),
    LatLng(28.6239, 77.2190),
    LatLng(28.6039, 77.1990),
    LatLng(28.6139, 77.2290),
  ];

  @override
  void initState() {
    super.initState();

    // 1️⃣ Initial load if already online
    Connectivity().checkConnectivity().then((status) {
      if (status.contains(ConnectivityResult.wifi) ||
          status.contains(ConnectivityResult.mobile)) {
        ref.read(eventNotifierProvider.notifier).fetch();
      }
    });

    // 2️⃣ Listen for connectivity changes
    _connSub = Connectivity().onConnectivityChanged.listen((status) {
      if (status.contains(ConnectivityResult.wifi) ||
          status.contains(ConnectivityResult.mobile)) {
        ref.read(eventNotifierProvider.notifier).fetch();
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

    // Build markers, highlight selected
    final markers = List<Marker>.generate(_markerPoints.length, (i) {
      final isSelected = i == _selectedIndex;
      return Marker(
        point: _markerPoints[i],
        width: isSelected ? 100 : 60,
        height: isSelected ? 100 : 60,
        child: Icon(
          Icons.location_on,
          color: isSelected ? Colors.orange : Colors.red,
          size: isSelected ? 48 : 32,
        ),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // ► Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _markerPoints[0],
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          // ► Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.5,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: Column(
                children: [
                  // ■ Drag handle
                  Container(
                    width: 40,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // ■ Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Upcoming'),
                          selected: _showUpcoming,
                          onSelected: (_) {
                            setState(() {
                              _showUpcoming = true;
                              _selectedIndex = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Past'),
                          selected: !_showUpcoming,
                          onSelected: (_) {
                            setState(() {
                              _showUpcoming = false;
                              _selectedIndex = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // ■ Animated content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeIn,
                      child: _buildListContent(state, scrollController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(EventState state, ScrollController sc) {
    final now = DateTime.now();

    if (state is Loading) {
      return Container(
        key: const ValueKey('loading'),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (state is Loaded) {
      final filtered = state.events
          .asMap()
          .entries
          .where(
            (e) => _showUpcoming
                ? e.value.time.isAfter(now)
                : e.value.time.isBefore(now),
          )
          .toList();

      if (filtered.isEmpty) {
        return Container(
          key: const ValueKey('empty'),
          alignment: Alignment.center,
          child: const Text('No events found'),
        );
      }

      return Container(
        key: const ValueKey('loaded'),
        child: ListView.builder(
          controller: sc,
          itemCount: filtered.length,
          itemBuilder: (ctx, idx) {
            final origIdx = filtered[idx].key;
            final e = filtered[idx].value;
            final selected = origIdx == _selectedIndex;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = origIdx;
                  _mapController.move(_markerPoints[origIdx], 15.0);
                });
              },
              child: Container(
                color: selected ? Colors.orange.withOpacity(0.2) : null,
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(e.name),
                  subtitle: Text(DateFormat.yMMMd().add_jm().format(e.time)),
                ),
              ),
            );
          },
        ),
      );
    }

    if (state is Error) {
      return Container(
        key: const ValueKey('error'),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load events'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.read(eventNotifierProvider.notifier).fetch();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return const SizedBox(key: ValueKey('initial'));
  }
}
