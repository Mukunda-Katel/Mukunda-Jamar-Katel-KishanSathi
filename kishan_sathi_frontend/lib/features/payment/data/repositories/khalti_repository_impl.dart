import '../../domain/entities/khalti_entities.dart';
import '../../domain/repositories/khalti_repository.dart';
import '../datasources/khalti_remote_data_source.dart';

class KhaltiRepositoryImpl implements KhaltiRepository {
  final KhaltiRemoteDataSource remoteDataSource;

  KhaltiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<BusinessKhaltiAccount?> getBusinessKhaltiAccount(String token) async {
    final data = await remoteDataSource.getBusinessKhaltiAccount(token);
    if (data == null) return null;
    return BusinessKhaltiAccount.fromJson(data);
  }

  @override
  Future<BusinessKhaltiAccount> linkKhaltiAccount({
    required String token,
    required String khaltiId,
    required String accountName,
  }) async {
    final data = await remoteDataSource.linkKhaltiAccount(
      token: token,
      khaltiId: khaltiId,
      accountName: accountName,
    );
    return BusinessKhaltiAccount.fromJson(data);
  }

  @override
  Future<BusinessKhaltiAccount> updateKhaltiAccount({
    required String token,
    String? khaltiId,
    String? accountName,
  }) async {
    final data = await remoteDataSource.updateKhaltiAccount(
      token: token,
      khaltiId: khaltiId,
      accountName: accountName,
    );
    return BusinessKhaltiAccount.fromJson(data);
  }

  @override
  Future<void> unlinkKhaltiAccount(String token) async {
    await remoteDataSource.unlinkKhaltiAccount(token);
  }

  @override
  Future<BusinessKhaltiStatus> checkBusinessKhaltiStatus({
    required String token,
    required int relationshipId,
  }) async {
    final data = await remoteDataSource.checkBusinessKhaltiStatus(
      token: token,
      relationshipId: relationshipId,
    );
    return BusinessKhaltiStatus.fromJson(data);
  }

  @override
  Future<KhaltiPaymentInitiation> initiateKhaltiPayment({
    required String token,
    required int relationshipId,
    required double amount,
    String? description,
  }) async {
    final data = await remoteDataSource.initiateKhaltiPayment(
      token: token,
      relationshipId: relationshipId,
      amount: amount,
      description: description,
    );
    return KhaltiPaymentInitiation.fromJson(data);
  }

  @override
  Future<bool> verifyKhaltiPayment({
    required String token,
    required int paymentRecordId,
    required String pidx,
    String? transactionId,
    String? totalAmount,
    String? status,
    Map<String, dynamic>? khaltiResponse,
  }) async {
    final response = await remoteDataSource.verifyKhaltiPayment(
      token: token,
      paymentRecordId: paymentRecordId,
      pidx: pidx,
      transactionId: transactionId,
      totalAmount: totalAmount,
      status: status,
      khaltiResponse: khaltiResponse,
    );

    return response['status'] == 200;
  }
}
