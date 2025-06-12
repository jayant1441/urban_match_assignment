import 'package:dio/dio.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> fetchEvents();
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final Dio dio;
  EventRemoteDataSourceImpl(this.dio);

  @override
  Future<List<EventModel>> fetchEvents() async {
    final response = await dio.get(
      'https://6847d529ec44b9f3493e5f06.mockapi.io/api/v1/events',
    );
    final data = response.data as List;
    return data.map((e) => EventModel.fromJson(e)).toList();
  }
}
