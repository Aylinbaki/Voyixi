import '../models/trip_plan_model.dart';
 
class TripPlanService {
  Future<String> generatePlan(TripPlanModel plan) async {
    return 'Plan oluşturuldu: ${plan.city}, ${plan.days} gün';
  }
}
 