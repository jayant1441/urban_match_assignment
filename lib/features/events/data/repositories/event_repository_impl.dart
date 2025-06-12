import 'package:dartz/dartz.dart';
import 'package:retry/retry.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';
import '../../../../core/network/network_info.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remote;
  final NetworkInfo networkInfo;
  EventRepositoryImpl({required this.remote, required this.networkInfo});

  @override
  Future<Either<Exception, List<Event>>> getEvents() async {
    if (!await networkInfo.isConnected) {
      return left(NoInternetException());
    }

    final r = RetryOptions(maxAttempts: 3);
    try {
      final models = await r.retry(
        () => remote.fetchEvents(),
        retryIf: (e) => e is Exception,
      );
      return right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return left(ServerException());
    }
  }
}
