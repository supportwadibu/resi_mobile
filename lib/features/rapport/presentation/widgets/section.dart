import 'package:flutter/material.dart';

import 'report_section_title.dart';

class Section extends StatelessWidget {
  final String title;
  final Widget child;

  const Section({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportSectionTitle(title: title),
        child,
      ],
    );
  }
}
