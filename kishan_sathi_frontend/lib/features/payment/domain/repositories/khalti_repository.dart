import '../entities/khalti_entities.dart';

abstract class KhaltiRepository {
  Future<BusinessKhaltiAccount?> getBusinessKhaltiAccount(String token);

  Future<BusinessKhaltiAccount> linkKhaltiAccount({
    required String token,
    required String khaltiId,
    required String accountName,
  });

  Future<BusinessKhaltiAccount> updateKhaltiAccount({
    required String token,
    String? khaltiId,
    String? accountName,
  });

  Future<void> unlinkKhaltiAccount(String token);

  Future<BusinessKhaltiStatus> checkBusinessKhaltiStatus({
    required String token,
    required int relationshipId,
  });

  Future<KhaltiPaymentInitiation> initiateKhaltiPayment({
    required String token,
    required int relationshipId,
    required double amount,
    String? description,
  });

  Future<bool> verifyKhaltiPayment({
    required String token,
    required int paymentRecordId,
    required String pidx,
    String? transactionId,
    String? totalAmount,
    String? status,
    Map<String, dynamic>? khaltiResponse,
  });
}
