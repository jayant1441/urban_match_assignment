import 'package:dartz/dartz.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase {
  final EventRepository _repo;
  GetEventsUseCase(this._repo);

  Future<Either<Exception, List<Event>>> call() {
    return _repo.getEvents();
  }
}
