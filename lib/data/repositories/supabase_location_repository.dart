import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/remote/supabase_location_datasource.dart';
import 'package:todo_app/domain/entities/location_setting.dart';
import 'package:todo_app/domain/repositories/location_repository.dart';

class SupabaseLocationRepository implements LocationRepository {
  final SupabaseLocationDataSource dataSource;

  SupabaseLocationRepository(this.dataSource);

  @override
  Future<Either<Failure, LocationSetting?>> getLocationSetting(int todoId) async {
    try {
      final setting = await dataSource.getLocationSetting(todoId);
      return Right(setting);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LocationSetting>>> getUserLocationSettings() async {
    try {
      final settings = await dataSource.getUserLocationSettings();
      return Right(settings);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LocationSetting>>> getActiveLocationSettings() async {
    try {
      final settings = await dataSource.getActiveLocationSettings();
      return Right(settings);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createLocationSetting(
    int todoId,
    double latitude,
    double longitude,
    int radius, {
    String? locationName,
  }) async {
    try {
      final id = await dataSource.createLocationSetting(
        todoId,
        latitude,
        longitude,
        radius,
        locationName: locationName,
      );
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateLocationSetting(LocationSetting setting) async {
    try {
      await dataSource.updateLocationSetting(setting);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLocationSetting(int id) async {
    try {
      await dataSource.deleteLocationSetting(id);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateGeofenceState(
    int id,
    String newState, {
    bool shouldTriggerNotification = false,
  }) async {
    try {
      await dataSource.updateGeofenceState(id, newState);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTriggeredAt(
    int id,
    DateTime triggeredTime,
  ) async {
    try {
      await dataSource.updateTriggeredAt(id, triggeredTime);
      return right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
