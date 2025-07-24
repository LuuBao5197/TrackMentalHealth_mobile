import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/test/PersonalityTestPage.dart';

class TestDetailScreen extends StatelessWidget {
  final int testId;

  const TestDetailScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    return PersonalityTestPage(testId: testId);
  }
}
