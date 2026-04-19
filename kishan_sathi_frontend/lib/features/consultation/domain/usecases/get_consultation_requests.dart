import '../entities/consultation_request_entity.dart';
import '../repositories/consultation_request_repository.dart';

class GetConsultationRequests {
  final ConsultationRequestRepository repository;

  GetConsultationRequests({required this.repository});

  Future<List<ConsultationRequestEntity>> call({required String token}) {
    return repository.getConsultationRequests(token: token);
  }
}
