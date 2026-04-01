import 'package:equatable/equatable.dart';

abstract class KhaltiPaymentEvent extends Equatable {
  const KhaltiPaymentEvent();

  @override
  List<Object?> get props => [];
}

class CheckKhaltiStatus extends KhaltiPaymentEvent {
  final String token;
  final int relationshipId;

  const CheckKhaltiStatus({
    required this.token,
    required this.relationshipId,
  });

  @override
  List<Object?> get props => [token, relationshipId];
}

class InitiateKhaltiPayment extends KhaltiPaymentEvent {
  final String token;
  final int relationshipId;
  final double amount;
  final String? description;

  const InitiateKhaltiPayment({
    required this.token,
    required this.relationshipId,
    required this.amount,
    this.description,
  });

  @override
  List<Object?> get props => [token, relationshipId, amount, description];
}

class VerifyKhaltiPayment extends KhaltiPaymentEvent {
  final String token;
  final int paymentRecordId;
  final String pidx;
  final String? transactionId;
  final String? totalAmount;
  final String? status;
  final Map<String, dynamic>? khaltiResponse;

  const VerifyKhaltiPayment({
    required this.token,
    required this.paymentRecordId,
    required this.pidx,
    this.transactionId,
    this.totalAmount,
    this.status,
    this.khaltiResponse,
  });

  @override
  List<Object?> get props => [
        token,
        paymentRecordId,
        pidx,
        transactionId,
        totalAmount,
        status,
        khaltiResponse,
      ];
}

class ResetKhaltiPayment extends KhaltiPaymentEvent {
  const ResetKhaltiPayment();
}
