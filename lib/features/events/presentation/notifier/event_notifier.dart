import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urban_match_assignment/features/events/domain/repositories/event_repository.dart';
import 'package:urban_match_assignment/locator.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/get_events.dart';

sealed class EventState {
  const EventState();
  factory EventState.initial() = Initial;
  factory EventState.loading() = Loading;
  factory EventState.loaded(List<Event> events) = Loaded;
  factory EventState.error(String message) = Error;
}

class Initial extends EventState {}

class Loading extends EventState {}

class Loaded extends EventState {
  final List<Event> events;
  Loaded(this.events);
}

class Error extends EventState {
  final String message;
  Error(this.message);
}

class EventNotifier extends StateNotifier<EventState> {
  final GetEventsUseCase _getEvents;
  EventNotifier(this._getEvents) : super(EventState.initial());

  Future<void> fetch() async {
    state = EventState.loading();
    final result = await _getEvents();
    result.fold((err) {
      if (err is NoInternetException) {
        state = EventState.error('No Internet connection');
      } else {
        state = EventState.error('Failed to load events');
      }
    }, (events) => state = EventState.loaded(events));
  }
}

final eventNotifierProvider = StateNotifierProvider<EventNotifier, EventState>((
  ref,
) {
  return EventNotifier(getIt<GetEventsUseCase>());
});
