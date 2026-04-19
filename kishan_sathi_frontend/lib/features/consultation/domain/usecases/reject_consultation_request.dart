import '../entities/consultation_request_entity.dart';
import '../repositories/consultation_request_repository.dart';

class RejectConsultationRequest {
  final ConsultationRequestRepository repository;

  RejectConsultationRequest({required this.repository});

  Future<ConsultationRequestEntity> call({
    required String token,
    required int requestId,
  }) {
    return repository.rejectConsultationRequest(
      token: token,
      requestId: requestId,
    );
  }
}
