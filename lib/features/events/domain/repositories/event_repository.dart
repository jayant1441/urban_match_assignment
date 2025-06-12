import '../entities/event.dart';
import 'package:dartz/dartz.dart';

/// Error types
class NoInternetException implements Exception {}

class ServerException implements Exception {}

abstract class EventRepository {
  /// Returns Either<Exception, List<Event>>
  Future<Either<Exception, List<Event>>> getEvents();
}
