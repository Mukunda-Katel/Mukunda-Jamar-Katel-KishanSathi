import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/approve_consultation_request.dart';
import '../../domain/usecases/get_consultation_requests.dart';
import '../../domain/usecases/reject_consultation_request.dart';
import 'consultation_requests_event.dart';
import 'consultation_requests_state.dart';

class ConsultationRequestsBloc
    extends Bloc<ConsultationRequestsEvent, ConsultationRequestsState> {
  final GetConsultationRequests getConsultationRequests;
  final ApproveConsultationRequest approveConsultationRequest;
  final RejectConsultationRequest rejectConsultationRequest;

  ConsultationRequestsBloc({
    required this.getConsultationRequests,
    required this.approveConsultationRequest,
    required this.rejectConsultationRequest,
  }) : super(const ConsultationRequestsState()) {
    on<ConsultationRequestsFetchRequested>(_onFetchRequested);
    on<ConsultationRequestApproveRequested>(_onApproveRequested);
    on<ConsultationRequestRejectRequested>(_onRejectRequested);
    on<ConsultationRequestsFeedbackCleared>(_onFeedbackCleared);
  }

  Future<void> _onFetchRequested(
    ConsultationRequestsFetchRequested event,
    Emitter<ConsultationRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final requests = await getConsultationRequests(token: event.token);
      emit(
        state.copyWith(
          isLoading: false,
          requests: requests,
          clearErrorMessage: true,
          clearSuccessMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _cleanError(e),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  Future<void> _onApproveRequested(
    ConsultationRequestApproveRequested event,
    Emitter<ConsultationRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await approveConsultationRequest(
        token: event.token,
        requestId: event.requestId,
      );
      final refreshed = await getConsultationRequests(token: event.token);

      emit(
        state.copyWith(
          isActionInProgress: false,
          requests: refreshed,
          successMessage: 'Consultation request approved!',
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: _cleanError(e),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  Future<void> _onRejectRequested(
    ConsultationRequestRejectRequested event,
    Emitter<ConsultationRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await rejectConsultationRequest(
        token: event.token,
        requestId: event.requestId,
      );
      final refreshed = await getConsultationRequests(token: event.token);

      emit(
        state.copyWith(
          isActionInProgress: false,
          requests: refreshed,
          successMessage: 'Consultation request rejected',
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: _cleanError(e),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  void _onFeedbackCleared(
    ConsultationRequestsFeedbackCleared event,
    Emitter<ConsultationRequestsState> emit,
  ) {
    emit(
      state.copyWith(
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
