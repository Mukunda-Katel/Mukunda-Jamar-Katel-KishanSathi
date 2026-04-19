import 'package:equatable/equatable.dart';

abstract class ConsultationRequestsEvent extends Equatable {
  const ConsultationRequestsEvent();

  @override
  List<Object?> get props => [];
}

class ConsultationRequestsFetchRequested extends ConsultationRequestsEvent {
  final String token;

  const ConsultationRequestsFetchRequested({required this.token});

  @override
  List<Object?> get props => [token];
}

class ConsultationRequestApproveRequested extends ConsultationRequestsEvent {
  final String token;
  final int requestId;

  const ConsultationRequestApproveRequested({
    required this.token,
    required this.requestId,
  });

  @override
  List<Object?> get props => [token, requestId];
}

class ConsultationRequestRejectRequested extends ConsultationRequestsEvent {
  final String token;
  final int requestId;

  const ConsultationRequestRejectRequested({
    required this.token,
    required this.requestId,
  });

  @override
  List<Object?> get props => [token, requestId];
}

class ConsultationRequestsFeedbackCleared extends ConsultationRequestsEvent {
  const ConsultationRequestsFeedbackCleared();
}
