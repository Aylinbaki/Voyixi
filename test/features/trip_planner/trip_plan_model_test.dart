import 'package:flutter_test/flutter_test.dart';
import 'package:voyixi/features/trip_planner/trip_plan_model.dart';

void main() {
  group('TripPlanModel Tests', () {
    test('should initialize with default values', () {
      final model = TripPlanModel();
      
      expect(model.city, '');
      expect(model.days, 3);
      expect(model.preferences, const []);
      expect(model.budget, '');
    });

    test('toMap should return a valid map', () {
      final model = TripPlanModel(
        city: 'Paris',
        days: 5,
        preferences: ['Museums', 'Food'],
        budget: 'Medium',
      );

      final map = model.toMap();

      expect(map['city'], 'Paris');
      expect(map['days'], 5);
      expect(map['preferences'], ['Museums', 'Food']);
      expect(map['budget'], 'Medium');
    });

    test('toString should return a formatted string', () {
      final model = TripPlanModel(city: 'London', days: 2);
      final expectedString = 'TripPlan(city: London, days: 2, preferences: [], budget: )';
      
      expect(model.toString(), expectedString);
    });
  });
}
