part of 'cubit.dart';

abstract class MemberCenterState extends Equatable {
  const MemberCenterState();

  @override
  List<Object> get props => [];
}

class MemberCenterInitial extends MemberCenterState {}

class MemberCenterLoading extends MemberCenterState {}

class MemberCenterLoaded extends MemberCenterState {
  final String version;
  final String buildNumber;
  final Member? member;
  final bool isLogin;
  const MemberCenterLoaded({
    required this.version,
    required this.buildNumber,
    required this.isLogin,
    this.member,
  });
}

class MemberCenterError extends MemberCenterState {
  final dynamic error;
  const MemberCenterError({this.error});
}
