class TripPlanModel {
  String city;
  int days;
  List<String> preferences;
  String budget; 
 
  TripPlanModel({
    this.city = '',
    this.days = 3,
    this.preferences = const [],
    this.budget = '',
  });
  Map<String, dynamic> toMap() => {
        'city': city,
        'days': days,
        'preferences': preferences,
        'budget': budget,
      };
  @override
  String toString() => 'TripPlan(city: $city, days: $days, '
      'preferences: $preferences, budget: $budget)';
}
 