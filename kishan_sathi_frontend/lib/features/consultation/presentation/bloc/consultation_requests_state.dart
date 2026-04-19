import 'package:equatable/equatable.dart';

import '../../domain/entities/consultation_request_entity.dart';

class ConsultationRequestsState extends Equatable {
  final bool isLoading;
  final bool isActionInProgress;
  final List<ConsultationRequestEntity> requests;
  final String? errorMessage;
  final String? successMessage;

  const ConsultationRequestsState({
    this.isLoading = false,
    this.isActionInProgress = false,
    this.requests = const [],
    this.errorMessage,
    this.successMessage,
  });

  ConsultationRequestsState copyWith({
    bool? isLoading,
    bool? isActionInProgress,
    List<ConsultationRequestEntity>? requests,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ConsultationRequestsState(
      isLoading: isLoading ?? this.isLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      requests: requests ?? this.requests,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccessMessage ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isActionInProgress,
        requests,
        errorMessage,
        successMessage,
      ];
}
