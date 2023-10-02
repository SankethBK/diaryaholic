import 'package:dairy_app/app/themes/theme_extensions/note_create_page_theme_extensions.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SendFeedBack extends StatelessWidget {
  const SendFeedBack({Key? key}) : super(key: key);

  final emailAddress = 'diaryvault.app@gmail.com';
  final subject = 'Feedback for DiaryVault';

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _launchEmailApp,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            "Send feedback",
            style: TextStyle(
              fontSize: 16.0,
              color: Theme.of(context)
                  .extension<NoteCreatePageThemeExtensions>()!
                  .mainTextColor,
            ),
          ),
        ),
      );

  void _launchEmailApp() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {'subject': subject},
    );

    await launchUrl(emailLaunchUri);
  }
}
