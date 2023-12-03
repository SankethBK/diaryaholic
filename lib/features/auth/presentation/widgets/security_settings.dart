import 'package:dairy_app/app/themes/theme_extensions/note_create_page_theme_extensions.dart';
import 'package:dairy_app/app/themes/theme_extensions/settings_page_theme_extensions.dart';
import 'package:dairy_app/core/dependency_injection/injection_container.dart';
import 'package:dairy_app/core/utils/utils.dart';
import 'package:dairy_app/core/widgets/settings_tile.dart';
import 'package:dairy_app/features/auth/core/constants.dart';
import 'package:dairy_app/features/auth/domain/repositories/authentication_repository.dart';
import 'package:dairy_app/features/auth/presentation/bloc/auth_session/auth_session_bloc.dart';
import 'package:dairy_app/features/auth/presentation/bloc/user_config/user_config_cubit.dart';
import 'package:dairy_app/features/auth/presentation/widgets/email_change_popup.dart';
import 'package:dairy_app/features/auth/presentation/widgets/password_enter_popup.dart';
import 'package:dairy_app/features/auth/presentation/widgets/password_reset_popup.dart';
import 'package:dairy_app/features/auth/presentation/widgets/pin_reset_popup.dart';
import 'package:dairy_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_accordion/widgets/AccordionHeaderItem.dart';
import 'package:simple_accordion/widgets/AccordionItem.dart';
import 'package:simple_accordion/widgets/AccordionWidget.dart';

// ignore: must_be_immutable
class SecuritySettings extends StatelessWidget {
  late IAuthenticationRepository authenticationRepository;

  SecuritySettings({Key? key}) : super(key: key) {
    authenticationRepository = sl<IAuthenticationRepository>();
  }

  @override
  Widget build(BuildContext context) {
    final authSessionBloc = BlocProvider.of<AuthSessionBloc>(context);
    final userConfigCubit = BlocProvider.of<UserConfigCubit>(context);

    final mainTextColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .mainTextColor;

    final inactiveTrackColor = Theme.of(context)
        .extension<SettingsPageThemeExtensions>()!
        .inactiveTrackColor;

    final activeColor =
        Theme.of(context).extension<SettingsPageThemeExtensions>()!.activeColor;

    return BlocBuilder<UserConfigCubit, UserConfigState>(
      builder: (context, state) {
        var isFingerPrintLoginEnabledValue =
            state.userConfigModel!.isFingerPrintLoginEnabled;
        var isPINLoginEnabledValue = state.userConfigModel!.isPINLoginEnabled;

        final userId = state.userConfigModel?.userId;
        return SimpleAccordion(
          headerColor: mainTextColor,
          headerTextStyle: TextStyle(
            color: mainTextColor,
            fontSize: 16,
          ),
          children: [
            AccordionHeaderItem(
              title: S.current.securitySettings,
              children: [
                AccordionItem(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: SettingsTile(
                            child: Text(
                              S.current.changePassword,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: mainTextColor,
                              ),
                            ),
                            onTap: () async {
                              if (userId == null) {
                                showToast(S.current.unexpectedErrorOccured);
                                return;
                              }

                              if (userId == GuestUserDetails.guestUserId) {
                                showToast(S.current
                                    .pleaseSetupYourAccountToUseThisFeature);
                                return;
                              }
                              String? result = await passwordLoginPopup(
                                context: context,
                                submitPassword: (password) =>
                                    authenticationRepository.verifyPassword(
                                        userId, password),
                              );

                              // old password will be retrieved from previous dialog
                              if (result != null) {
                                passwordResetPopup(
                                  context: context,
                                  submitPassword: (newPassword) =>
                                      authenticationRepository.updatePassword(
                                    authSessionBloc.state.user!.email,
                                    result,
                                    newPassword,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Material(
                          color: Colors.transparent,
                          child: SettingsTile(
                            child: Text(
                              S.current.changeEmail,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: mainTextColor,
                              ),
                            ),
                            onTap: () async {
                              if (userId == null) {
                                showToast(S.current.unexpectedErrorOccured);
                              }

                              if (userId == GuestUserDetails.guestUserId) {
                                showToast(S.current
                                    .pleaseSetupYourAccountToUseThisFeature);
                              }

                              String? result = await passwordLoginPopup(
                                context: context,
                                submitPassword: (password) =>
                                    authenticationRepository.verifyPassword(
                                        authSessionBloc.state.user!.id,
                                        password),
                              );

                              // old password will be retrieved from previous dialog
                              dynamic emailChanged;
                              if (result != null) {
                                emailChanged = await emailChangePopup(
                                  context,
                                  (newEmail) =>
                                      authenticationRepository.updateEmail(
                                    oldEmail: authSessionBloc.state.user!.email,
                                    password: result,
                                    newEmail: newEmail,
                                  ),
                                );
                              }

                              if (emailChanged == true) {
                                authSessionBloc.add(UserLoggedOut());
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          inactiveTrackColor: inactiveTrackColor,
                          activeColor: activeColor,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: Text(
                            S.current.enableFingerPrintLogin,
                            style: TextStyle(color: mainTextColor),
                          ),
                          subtitle: Text(
                            S.current
                                .fingerPrintAthShouldBeEnabledInDeviceSettings,
                            style: TextStyle(color: mainTextColor),
                          ),
                          value: isFingerPrintLoginEnabledValue ?? false,
                          onChanged: (value) async {
                            if (userId == null) {
                              showToast(S.current.unexpectedErrorOccured);
                              return;
                            }

                            if (userId == GuestUserDetails.guestUserId) {
                              showToast(S.current
                                  .pleaseSetupYourAccountToUseThisFeature);
                              return;
                            }

                            try {
                              await authenticationRepository
                                  .isFingerprintAuthPossible();
                              userConfigCubit.setUserConfig(
                                UserConfigConstants.isFingerPrintLoginEnabled,
                                value,
                              );
                            } on Exception catch (e) {
                              showToast(
                                  e.toString().replaceAll("Exception: ", ""));
                            }
                          },
                        ),
                        SwitchListTile(
                          inactiveTrackColor: inactiveTrackColor,
                          activeColor: activeColor,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: Text(
                            S.current.enablePINLogin,
                            style: TextStyle(color: mainTextColor),
                          ),
                          subtitle: Text(
                            S.current.pinLoginSetupInstructions,
                            style: TextStyle(color: mainTextColor),
                          ),
                          value: isPINLoginEnabledValue ?? false,
                          onChanged: (value) async {
                            if (userId == null) {
                              showToast(S.current.unexpectedErrorOccured);
                              return;
                            }

                            if (userId == GuestUserDetails.guestUserId) {
                              showToast(S.current
                                  .pleaseSetupYourAccountToUseThisFeature);
                              return;
                            }
                            if (value) {
                              // Call the PIN reset popup
                              await pinResetPopup(
                                context: context,
                                userPinId: userId,
                              );
                            }

                            try {
                              userConfigCubit.setUserConfig(
                                UserConfigConstants.isPINLoginEnabled, //change
                                value,
                              );
                            } on Exception catch (e) {
                              showToast(
                                  e.toString().replaceAll("Exception: ", ""));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
