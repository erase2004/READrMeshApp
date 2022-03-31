import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:readr/helpers/errorHelper.dart';
import 'package:readr/models/invitationCode.dart';
import 'package:readr/services/invitationCodeService.dart';

part 'invitationCode_state.dart';

class InvitationCodeCubit extends Cubit<InvitationCodeState> {
  InvitationCodeCubit() : super(InvitationCodeInitial());
  final InvitationCodeService _invitationCodeService = InvitationCodeService();

  fetchMyInvitationCode() async {
    List<InvitationCode> allMyInvitationCodes =
        await _invitationCodeService.fetchMyInvitationCode();
    List<InvitationCode> usableCodeList = [];
    List<InvitationCode> activatedCodeList = [];
    for (var code in allMyInvitationCodes) {
      if (code.activeMember == null) {
        usableCodeList.add(code);
      } else {
        activatedCodeList.add(code);
      }
    }
    emit(InvitationCodeLoaded(
      usableCodeList: usableCodeList,
      activatedCodeList: activatedCodeList,
    ));
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('$error, $stackTrace');
    super.onError(error, stackTrace);
    emit(InvitationCodeError(determineException(error)));
  }
}