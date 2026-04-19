import 'package:equatable/equatable.dart';

class ConsultationParticipantEntity extends Equatable {
  final int id;
  final String fullName;
  final String? phoneNumber;

  const ConsultationParticipantEntity({
    required this.id,
    required this.fullName,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [id, fullName, phoneNumber];
}

class ConsultationRequestEntity extends Equatable {
  final int id;
  final String status;
  final String? message;
  final int? chatRoomId;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final ConsultationParticipantEntity? farmer;

  const ConsultationRequestEntity({
    required this.id,
    required this.status,
    this.message,
    this.chatRoomId,
    required this.createdAt,
    this.approvedAt,
    this.farmer,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  @override
  List<Object?> get props => [
        id,
        status,
        message,
        chatRoomId,
        createdAt,
        approvedAt,
        farmer,
      ];
}
