import 'package:http/http.dart' as http;

import '../../../../services/consultation_service.dart';
import '../../domain/entities/consultation_request_entity.dart';
import '../../domain/repositories/consultation_request_repository.dart';

class ConsultationRequestRepositoryImpl
    implements ConsultationRequestRepository {
  final ConsultationService _service;

  ConsultationRequestRepositoryImpl({ConsultationService? service})
      : _service = service ?? ConsultationService(client: http.Client());

  @override
  Future<List<ConsultationRequestEntity>> getConsultationRequests({
    required String token,
  }) async {
    final requests = await _service.getMyRequests(token);
    return requests.map(_mapRequest).toList();
  }

  @override
  Future<ConsultationRequestEntity> approveConsultationRequest({
    required String token,
    required int requestId,
  }) async {
    final request = await _service.approveRequest(token, requestId);
    return _mapRequest(request);
  }

  @override
  Future<ConsultationRequestEntity> rejectConsultationRequest({
    required String token,
    required int requestId,
  }) async {
    final request = await _service.rejectRequest(token, requestId);
    return _mapRequest(request);
  }

  ConsultationRequestEntity _mapRequest(ConsultationRequest request) {
    return ConsultationRequestEntity(
      id: request.id,
      status: request.status,
      message: request.message,
      chatRoomId: request.chatRoomId,
      createdAt: request.createdAt,
      approvedAt: request.approvedAt,
      farmer: request.farmer == null ? null : _mapParticipant(request.farmer!),
    );
  }

  ConsultationParticipantEntity _mapParticipant(Doctor participant) {
    return ConsultationParticipantEntity(
      id: participant.id,
      fullName: participant.fullName,
      phoneNumber: participant.phoneNumber,
    );
  }
}
