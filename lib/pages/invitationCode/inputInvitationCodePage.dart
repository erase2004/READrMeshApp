import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/pages/loginMember/loginPage.dart';
import 'package:readr/services/invitationCodeService.dart';
import 'package:url_launcher/url_launcher.dart';

class InputInvitationCodePage extends StatefulWidget {
  const InputInvitationCodePage({Key? key}) : super(key: key);

  @override
  State<InputInvitationCodePage> createState() =>
      _InputInvitationCodePageState();
}

class _InputInvitationCodePageState extends State<InputInvitationCodePage> {
  final _formKey = GlobalKey<FormState>();
  final InvitationCodeService _invitationCodeService = InvitationCodeService();
  final _pinController = TextEditingController();
  late InvitationCodeStatus _status;
  bool _isComplete = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'invitationCode'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 18,
            color: readrBlack,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0.5,
        actions: [
          if (_isComplete)
            TextButton(
              onPressed: () async {
                _loadingDialog(context);
                _status = await _invitationCodeService
                    .checkInvitationCode(_pinController.text);
                if (_status == InvitationCodeStatus.valid) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  Get.off(
                    () => const LoginPage(fromOnboard: true),
                    fullscreenDialog: true,
                  );
                } else {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _formKey.currentState!.validate();
                }
              },
              child: Text(
                'send'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            )
        ],
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    const defaultPinTheme = PinTheme(
      width: 40,
      height: 32,
      textStyle: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: readrBlack87,
      ),
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(0, 9, 40, 0.66),
          ),
        ),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: const Border(
        bottom: BorderSide(
          color: Color.fromRGBO(0, 9, 40, 0.1),
        ),
      ),
    );
    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: const Border(
        bottom: BorderSide(
          color: Colors.red,
        ),
      ),
    );
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(43, 40, 43, 0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Pinput(
              pinputAutovalidateMode: PinputAutovalidateMode.disabled,
              crossAxisAlignment: CrossAxisAlignment.center,
              controller: _pinController,
              onChanged: (value) {
                _status = InvitationCodeStatus.valid;
                _formKey.currentState!.validate();
              },
              validator: (code) {
                switch (_status) {
                  case InvitationCodeStatus.valid:
                    return null;
                  case InvitationCodeStatus.invalid:
                    return 'invitationCodeInputError'.tr;
                  case InvitationCodeStatus.activated:
                    return 'invitationCodeUsed'.tr;
                  case InvitationCodeStatus.error:
                    return 'invitationCodeError'.tr;
                }
              },
              onCompleted: (text) {
                setState(() {
                  _isComplete = true;
                });
              },
              errorTextStyle: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              autofocus: true,
              enableSuggestions: false,
              keyboardType: TextInputType.text,
              length: 6,
              showCursor: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))
              ],
              defaultPinTheme: defaultPinTheme,
              followingPinTheme: focusedPinTheme,
              errorPinTheme: errorPinTheme,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          alignment: Alignment.center,
          child: RichText(
            text: TextSpan(
              text: 'inputInvitationCodeDescriptionPrefix'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: readrBlack50,
              ),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () async {
                      final Uri params = Uri(
                        scheme: 'mailto',
                        path: 'readr@readr.tw',
                        queryParameters: {
                          'subject': '邀請碼問題',
                        },
                      );

                      if (await canLaunchUrl(params)) {
                        await launchUrl(params);
                      } else {
                        print('Could not launch ${params.toString()}');
                      }
                    },
                    child: const Text(
                      'readr@readr.tw',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: readrBlack50,
                        decoration: TextDecoration.underline,
                        decorationColor: readrBlack50,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: 'inputInvitationCodeDescriptionSuffix'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: readrBlack50,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _loadingDialog(BuildContext context) {
    AlertDialog alert = const AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
    showDialog(
      //prevent outside touch
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        //prevent Back button press
        return WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: alert);
      },
    );
  }
}
