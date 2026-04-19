import '../entities/consultation_request_entity.dart';
import '../repositories/consultation_request_repository.dart';

class ApproveConsultationRequest {
  final ConsultationRequestRepository repository;

  ApproveConsultationRequest({required this.repository});

  Future<ConsultationRequestEntity> call({
    required String token,
    required int requestId,
  }) {
    return repository.approveConsultationRequest(
      token: token,
      requestId: requestId,
    );
  }
}
