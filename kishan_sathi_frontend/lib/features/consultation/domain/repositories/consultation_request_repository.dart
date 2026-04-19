import '../entities/consultation_request_entity.dart';

abstract class ConsultationRequestRepository {
  Future<List<ConsultationRequestEntity>> getConsultationRequests({
    required String token,
  });

  Future<ConsultationRequestEntity> approveConsultationRequest({
    required String token,
    required int requestId,
  });

  Future<ConsultationRequestEntity> rejectConsultationRequest({
    required String token,
    required int requestId,
  });
}
