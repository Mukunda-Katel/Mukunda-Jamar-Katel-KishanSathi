import 'package:equatable/equatable.dart';

abstract class KhaltiAccountEvent extends Equatable {
  const KhaltiAccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadKhaltiAccount extends KhaltiAccountEvent {
  final String token;

  const LoadKhaltiAccount(this.token);

  @override
  List<Object?> get props => [token];
}

class LinkKhaltiAccount extends KhaltiAccountEvent {
  final String token;
  final String khaltiId;
  final String accountName;

  const LinkKhaltiAccount({
    required this.token,
    required this.khaltiId,
    required this.accountName,
  });

  @override
  List<Object?> get props => [token, khaltiId, accountName];
}

class UpdateKhaltiAccount extends KhaltiAccountEvent {
  final String token;
  final String? khaltiId;
  final String? accountName;

  const UpdateKhaltiAccount({
    required this.token,
    this.khaltiId,
    this.accountName,
  });

  @override
  List<Object?> get props => [token, khaltiId, accountName];
}

class UnlinkKhaltiAccount extends KhaltiAccountEvent {
  final String token;

  const UnlinkKhaltiAccount(this.token);

  @override
  List<Object?> get props => [token];
}
